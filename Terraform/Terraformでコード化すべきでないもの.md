***

## Azure上の業務基幹システムでTerraformでコード化すべきでないもの

Azureで業務基幹システムを構築する際、Terraformはインフラをコードで管理するための強力なツールです。しかし、その特性上、すべての要素をTerraformで管理することが最適とは限りません。

結論として、Terraformは**「Azureのコントロールプレーン（リソースのあるべき状態）」**の定義に集中させ、VM内部の設定、アプリケーション、データ、頻繁に変わる運用項目、機密情報の「値」などは、それぞれ専門のツールや仕組みに分離するのがベストプラクティスです。

以下に、Terraformでコード化すべきでないものとその理由、そして代替となる推奨アプローチを網羅的に解説します。

### 1. VM内部のOS・ミドルウェア設定

-   **具体例**:
    -   Windowsのロール/機能、レジストリ、IIS設定
    -   Linuxのパッケージインストール、`sshd`などの設定ファイル変更
    -   ウイルス対策ソフトの設定、ミドルウェアのインストールと構成
-   **Terraformに不向きな理由**:
    -   Terraformはインフラの状態を管理するツールであり、ゲストOS内部の状態管理には向いていません。
    -   `remote-exec`などのプロビジョナは冪等性（何度実行しても同じ結果になること）の保証が難しく、スクリプトの管理が複雑化します。
    -   構成の変更やドリフト（コードと実際の状態の乖離）の検知・収束が苦手で、実行エラー時のデバッグも困難です。
-   **推奨される代替手段**:
    -   **構成管理ツール**: **Ansible**, **Chef**, **Puppet**, **PowerShell DSC** を利用します。TerraformでVMを作成後、これらのツールを呼び出して内部構成を自動化します。
    -   **ゴールデンイメージ (Immutable Infrastructure)**: **Packer** や **Azure Image Builder** を使用し、OS設定やミドルウェアをインストール済みのカスタムイメージを事前に作成します。Terraformは、そのイメージからVMをデプロイするだけに専念させます。これにより、デプロイが高速化し、環境の一貫性が保たれます。
    -   **起動スクリプトの限定利用**: **cloud-init (Linux)** や **Custom Script Extension (Windows/Linux)** を、構成管理エージェントの導入など、初回起動時の最小限のブートストラップ処理にのみ利用します。

### 2. データベースのスキーマ・内部設定

-   **具体例**:
    -   テーブル、ビュー、インデックス、ストアドプロシージャの定義
    -   データベースユーザーや権限の詳細設定
    -   初期データやマスタデータの投入
-   **Terraformに不向きな理由**:
    -   データベーススキーマの変更は、マイグレーションの順序性やロールバックが重要であり、Terraformの宣言的な実行モデルとは相性が悪いです。
    -   Terraformの管理下で誤ってデータベースリソースを再作成してしまうと、中のデータがすべて失われる重大なリスクがあります。
-   **推奨される代替手段**:
    -   **データベースマイグレーションツール**: **Flyway**, **Liquibase**, **DACPAC (SQL Server)**, **Entity Framework Migrations** などをCI/CDパイプラインに組み込み、スキーマのバージョン管理を行います。
    -   **Terraformの役割**: データベースサーバー（Azure SQL Databaseなど）や空のデータベースといった「器」の作成、ネットワーク設定（Private Endpointなど）、バックアップポリシー、監視設定までに留めます。

```hcl
# terraform/database.tf - インフラ（器）のみを管理
resource "azurerm_mssql_server" "main" {
  name                         = "sql-server-prod"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value
}

resource "azurerm_mssql_database" "app_db" {
  name      = "app_database"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S2"
}

# DBスキーマのマイグレーションはCI/CDパイプラインでFlywayなどを実行する
```

### 3. 機密情報（シークレット）の値

-   **具体例**:
    -   データベースのパスワード、APIキー、接続文字列、証明書の秘密鍵
-   **Terraformに不向きな理由**:
    -   Terraformはリソースの状態を`tfstate`ファイルに保存します。ここに**機密情報が平文で保存される**ため、ファイルが漏洩すると深刻なセキュリティインシデントに繋がります。
    -   コード内に直接記述するのは論外です。
-   **推奨される代替手段**:
    -   **Azure Key Vault + Managed Identity**: 機密情報はAzure Key Vaultに安全に格納します。アプリケーションやVMは、パスワードが不要な**Managed Identity**を使ってKey Vaultから実行時に直接シークレットを取得します。
    -   **Terraformの役割**: Key Vaultリソース自体の作成と、どのリソースがKey Vaultにアクセスできるかのアクセスポリシー（権限）設定に限定します。シークレットの「値」の書き込みは、CI/CDパイプラインや手動で行い、Terraformの管理外とします。

```hcl
# ❌ 非推奨: 変数やtfstateにパスワードが残る
resource "azurerm_key_vault_secret" "db_pwd" {
  name         = "db-admin-password"
  value        = "MySuperSecretPassword123!" # 絶対にやってはいけない
  key_vault_id = azurerm_key_vault.main.id
}

# ✅ 推奨: Key Vaultから値を読み取り、リソースに設定する
# 注: この方法でもtfstateには値が記録されるため、最も安全なのはアプリケーションが直接Key Vaultから取得する方式です。
data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_mssql_server" "example" {
  # ...
  administrator_login_password = data.azurerm_key_vault_secret.sql_password.value
}
```

### 4. アプリケーションの配布と頻繁に変更される設定

-   **具体例**:
    -   アプリケーションのコードやバイナリファイル
    -   機能の有効/無効を切り替えるフィーチャーフラグ、ログレベルなど
-   **Terraformに不向きな理由**:
    -   アプリケーションのデプロイはインフラの変更よりもはるかに頻度が高く、ライフサイクルが異なります。変更の都度`terraform apply`を実行するのは非効率です。
    -   デプロイの失敗時のロールバックなど、アプリケーションリリースに特有の要件をTerraformで満たすのは困難です。
-   **推奨される代替手段**:
    -   **CI/CDパイプライン**: **Azure DevOps** や **GitHub Actions** を利用して、アプリケーションのビルド、テスト、デプロイを自動化します。
    -   **Azure App Configuration**: フィーチャーフラグや外部サービスのURLなど、動的に変更したいアプリケーション設定を一元管理します。アプリケーションは起動時や実行時にここから設定を読み込みます。

### 5. 永続的なデータとデータプレーンの大量オブジェクト

-   **具体例**:
    -   Azure Blob Storageに保存された業務データやファイル
    -   Azure Filesの中身
    -   データベース内の業務トランザクションデータ
-   **Terraformに不向きな理由**:
    -   Terraformはインフラの「定義」を管理するものであり、その中で動的に生成・変更される「データ」を管理対象外とします。
    -   誤った操作でストレージアカウントなどが再作成されると、データがすべて消失するリスクがあります。
-   **推奨される代替手段**:
    -   **アプリケーション/SDK**: データはアプリケーションによって書き込まれるべきものです。
    -   **Terraformの役割**: ストレージアカウントやファイル共有、Blobコンテナといったデータの「器」や、バックアップポリシーの作成に留めます。
    -   **バックアップ**: **Azure Backup** などの専用サービスでデータを保護します。

### 6. 動的なルールや一時的な運用操作

-   **具体例**:
    -   障害調査のための一時的なNSG（ネットワークセキュリティグループ）の許可ルール
    -   特定のクライアントIPアドレスに対するAzure SQL Databaseファイアウォールの一時的な許可
    -   VMの日常的な起動・停止、手動スナップショット作成
-   **Terraformに不向きな理由**:
    -   Terraformはコードで定義された状態を「正」とします。そのため、手動で行った一時的な変更は次回の`terraform plan/apply`で削除対象となり、意図しない操作を引き起こす原因となります。
    -   変更頻度が高い値をTerraformで管理すると、運用負荷が増大します。
-   **推奨される代替手段**:
    -   **恒久的なアクセスの確保**: Private Endpoint, VPN, Azure Bastion, JIT (Just-In-Time) VM Accessなどを利用し、一時的なルールが不要な設計を目指します。
    -   **運用自動化ツール**: どうしても必要な場合は、**Azure CLI**, **Azure Automation**, **Logic Apps** などでスクリプト化します。

### その他、Terraformでの管理を避けるべきもの

| 項目 | 理由 | 推奨手段 |
| :--- | :--- | :--- |
| **人ユーザー単位のRBAC** | 個人の入社・退社・異動で頻繁に変更され、コードと実態が乖離しやすいため。 | AADグループを作成し、そのグループに対してTerraformでロールを割り当てます。人の管理はEntra ID（AAD）側で行います。 |
| **VMSSのインスタンス数** | `capacity`を手動で変更すると、Autoscale設定と競合し、意図しないスケールイン/アウトが発生する可能性があるため。 | Azure Monitor Autoscaleでルールベースの自動スケーリングを設定します。（Autoscale設定自体はTerraformで管理します） |
| **イメージビルド処理** | Terraformはイメージを生成するパイプラインの実行には不向きなため。 | **Packer**や**Azure Image Builder**でイメージ作成プロセスをコード化し、Terraformはその成果物（イメージID）を参照するだけとします。 |
| **DR切替などの手順型作業** | フェイルオーバーなどは、複数の手順と確認を伴う「プロセス」であり、状態を宣言するTerraformには不向きなため。 | **Azure Site Recovery**のRecovery Planや、**Azure Automation Runbook**で手順をコード化します。 |

### まとめ：責任分担のベストプラクティス

| 要素 | 理由 | 推奨ツール・アプローチ |
| :--- | :--- | :--- |
| **VM内のOS/ミドルウェア設定** | 冪等性の確保が難しく、状態管理に不向き。 | **Ansible, Chef, Puppet, Packer (ゴールデンイメージ)** |
| **DBスキーマ・データ** | マイグレーションやデータ保護の観点から不向き。 | **Flyway, Liquibase** などのDBマイグレーションツール |
| **機密情報（シークレット）の値** | `tfstate`ファイルへの平文保存による情報漏洩リスク。 | **Azure Key Vault + Managed Identity** |
| **アプリケーションコード・設定** | インフラとデプロイのライフサイクルが異なるため。 | **Azure DevOps, GitHub Actions (CI/CD), Azure App Configuration** |
| **永続データ** | Terraformは「器」を管理するもので、「中身」は管理対象外。 | アプリケーション、**Azure Backup** |
| **一時的な運用操作・動的ルール** | 宣言的管理と相性が悪く、手動操作と競合するため。 | **Azure CLI, Azure Automation, JIT/Bastion** |
| **人ユーザーの権限** | 変更頻度が高く、人事異動に追従できないため。 | **Azure AD (Entra ID) グループ**による権限管理 |

この役割分担を遵守することで、Terraformをインフラの「設計図」として最大限に活用し、安全で、効率的かつ保守性の高いシステム運用を実現できます。

***

### 統合時に見られた記載の矛盾点について

今回統合した3つの回答には、主旨が大きく矛盾する箇所は見られませんでした。すべての回答が「Terraformはインフラのコントロールプレーンに集中させ、VM内部の構成やデータ、シークレットの値などは別のツールで管理すべき」という点で一貫していました。

ただし、一点だけ表現のニュアンスに違いが見られました。

*   **Azure Key Vaultのシークレット参照 (`data`ソース) の扱いについて**:
    *   ある回答では、`data "azurerm_key_vault_secret"` を使ってKey Vaultから値を読み取り、リソース（例: `azurerm_sql_server`のパスワード）に設定する方法を「良い例」として紹介していました。
    *   一方、別の回答では、同じ方法を紹介しつつも「※この場合でもtfstateには値が記録されるため、最終的にはVM起動スクリプト内でKey Vaultから取得する方式が最も安全です」という重要な注釈を加えていました。

これは厳密な矛盾ではありませんが、セキュリティレベルの考え方に差があると言えます。統合した本文では、より安全性を重視する後者の考え方を採用し、**「`data`ブロックで参照する方法も可能だが、tfstateに値が残るため、最も推奨されるのはアプリケーションがManaged Identityを使って実行時に直接Key Vaultから値を取得する方式である」** という形で、両方の情報を補足的に記載しました。
