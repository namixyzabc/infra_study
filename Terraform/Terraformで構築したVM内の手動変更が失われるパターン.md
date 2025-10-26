

***

## Terraformで構築したVM内の手動変更は失われるか？ケース別の解説とベストプラクティス

Terraformを使用してAzureなどで仮想マシン（VM）を構築した後、VM内部のOS設定（レジストリ、IIS設定、サービスなど）を手動で変更した場合、その設定が次回の `terraform apply` で失われてしまうのではないか、という懸念は非常に重要です。

### 1. 結論：原則として失われないが、特定の条件下で失われる（または上書きされる）

結論から言うと、**原則として、TerraformはVM内部のOS設定を直接関知しないため、手動で行った変更が`terraform apply`によって失われることはありません。**

TerraformはVMのサイズ、ディスク、ネットワークインターフェースといった「インフラストラクチャレベル（器）」の状態を管理するツールです。OS内部のファイル作成、レジストリ変更、ソフトウェアのインストールといった「ゲストOSレベル」の構成は、Terraformの直接の管理範囲外です。

しかし、以下の**例外的なケース**においては、Terraformの操作が「結果的に」OS内部の変更を失わせたり、上書きしたりする可能性があります。

---

### 2. 手動設定が失われる・上書きされる主なケース

#### ケース1: VMが「再作成」される変更 (Force New Resource)

TerraformのコードでVMの**再作成（破棄して作り直すこと）**を引き起こす変更を行うと、既存のVMは完全に削除され、OSディスクもろとも新しいVMがまっさらに作成されます。この場合、古いVMに手動で行った設定は**すべて失われます。**

**VMの再作成を引き起こす変更の例：**

*   `name`（VM名）
*   `location`（リージョン）
*   `zone`（可用性ゾーン）
*   OSディスクの種類やキャッシング設定
*   `source_image_id`（VMのベースとなるイメージ）

**【確認方法】**
`terraform plan` を実行した際に、リソース名の横に `(forces new resource)` または `(forces replacement)` と表示された場合、そのリソースは再作成されます。この表示がないか必ず確認する習慣が重要です。

```sh
# terraform plan の出力例
-/+ azurerm_windows_virtual_machine.main (forces new resource)
  # ...
```

#### ケース2: VM拡張機能 (VM Extension) が再実行される

`azurerm_virtual_machine_extension`（Custom Script ExtensionやPowerShell DSCなど）を使用してVMの初期設定を行っている場合、この拡張機能が再実行されると、スクリプトの内容がOS設定を上書きする可能性があります。

**拡張機能が再実行される主なトリガー：**

*   拡張機能リソースの `settings` や `protected_settings` に変更があった場合。
*   拡張機能リソースの `name` など、再作成をトリガーするプロパティが変更された場合。
*   `lifecycle`ブロックなどで制御されていない場合。

例えば、「毎回タイムゾーンをJSTに設定する」というスクリプトが拡張機能に仕込まれている場合、手動でタイムゾーンをPSTに変更しても、何らかのトリガーで拡張機能が再実行されると、タイムゾーンはJSTに上書きされてしまいます。

#### ケース3: Terraform管理外の仕組みによる構成の収束

Terraformとは独立して、OSの設定をあるべき状態に維持・強制する仕組みが働いている場合、手動変更はそれらによって元に戻されます。

*   **Active Directoryのグループポリシー (GPO)**
*   **Desired State Configuration (DSC)**
*   **Azure Policy Guest Configuration (Assign/Enforceモード)**
*   **Azure Automanage**

これらのツールは、設定のドリフト（あるべき姿からの乖離）を自動的に修正するため、手動変更は一時的なものとなり、やがて元に戻ったように見えます。

---

### 3. 対策とベストプラクティス：すべてをコードで管理する

これらの問題を根本的に解決し、堅牢なインフラを維持するためのベストプラクティスは、「手動変更を原則として行わず、OS内部の設定も含めてすべてコードで管理する」ことです。

#### アプローチ1: 構成管理のコード化 (推奨)

Terraformは「器」の管理に徹させ、OS内部の設定はAnsible、DSC、GPOといった専用の構成管理ツールでコード化して管理します。

*   **役割分担:**
    *   **Terraform:** VM、NIC、ディスク、LBなどインフラのプロビジョニング。
    *   **Ansible/DSC:** IISのインストール、ファイアウォールルールの設定、レジストリ変更などOS内部の構成。
*   **連携方法:**
    Terraformの`null_resource`と`local-exec`プロビジョナーを使い、VM作成後にAnsible Playbookを自動実行させることができます。

```hcl
# main.tf: TerraformはVMを作成するだけ
resource "azurerm_windows_virtual_machine" "app" {
  # ... VMの定義 ...
}

# 初回プロビジョニング時にAnsibleを実行
resource "null_resource" "ansible_provisioning" {
  # VMが作成された後にトリガーされる
  triggers = {
    vm_id = azurerm_windows_virtual_machine.app.id
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${azurerm_windows_virtual_machine.app.private_ip_address}, playbooks/windows-setup.yml"
  }
}
```

#### アプローチ2: イミュータブル・インフラストラクチャ (最も堅牢)

OS設定やアプリケーションのインストールをすべて済ませた「ゴールデンイメージ」をPackerなどのツールで事前に作成し、TerraformはそのイメージからVMを起動するだけ、というアプローチです。

*   **Packer:** OSの初期設定、パッチ適用、ミドルウェアのインストールなどを行い、カスタムイメージを作成。
*   **Terraform:** Packerが作成したイメージID (`source_image_id`) を指定してVMをデプロイ。

変更が必要になった場合は、VMにログインして手動変更するのではなく、**新しいバージョンのイメージを作成し、そのイメージでVMを再デプロイ**します。これにより、構成ドリフトが原理的に発生しなくなります。

```hcl
# Packerで作成した最新イメージの情報をdataソースで取得
data "azurerm_image" "app_base" {
  name                = "app-base-image-v2.1.0"
  resource_group_name = "image-gallery-rg"
}

# そのイメージからVMを作成
resource "azurerm_windows_virtual_machine" "app_v2" {
  name            = "app-vm-v2-001"
  source_image_id = data.azurerm_image.app_base.id
  # ...
  tags = {
    ImageVersion = "2.1.0"
  }
}
```

#### アプローチ3: VM拡張機能の安全な利用法

VM拡張機能をどうしても利用する場合は、意図しない再実行による設定の上書きを防ぐ工夫が必要です。

*   **冪等性（Idempotence）の担保:** スクリプトを「何度実行しても同じ結果になる」ように記述します。例えば、「特定のディレクトリがなければ作成する」といった条件分岐を入れます。
*   **`lifecycle`ブロックの活用:** `ignore_changes` を設定することで、Terraformが特定の属性（`settings`など）の差分を検知しても、リソースの更新を無視させることができます。これは意図しない再実行を防ぐのに有効です。

```hcl
resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                 = "bootstrap-once"
  virtual_machine_id   = azurerm_windows_virtual_machine.app.id
  # ...
  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -File C:\\bootstrap\\init.ps1"
  })

  # settings/protected_settingsの差分による不要な再適用を防ぐ
  lifecycle {
    ignore_changes = [
      settings,
      protected_settings,
    ]
  }
}
```

#### アプローチ4: 構成ドリフトの検知

手動変更が避けられない場合の次善策として、あるべき状態と実際の状態の差分を定期的に検知する仕組みを導入します。

*   **Azure Policy Guest Configuration (Auditモード):** VM内の設定が定義したルールに準拠しているかを監査します。
*   **カスタムスクリプト:** PowerShellなどで期待する設定値と実際の値を比較するスクリプトを作成し、定期的に実行します。

---

### 4. まとめ：ケース別早見表

| 状況 | 手動設定は失われるか？ | 対策・推奨アプローチ |
| :--- | :--- | :--- |
| **通常の `terraform apply`** (VMの再作成や拡張機能の再実行を伴わない) | ✅ **失われない** | そのまま利用可能。ただし手動変更は非推奨。 |
| **`terraform apply` でVMが再作成される** (`forces new resource`) | ❌ **すべて失われる** | `terraform plan`を必ず確認する。 |
| **`terraform apply` でVM拡張機能が再実行される** | ⚠️ **上書きされる可能性あり** | スクリプトの冪等性を担保するか、`lifecycle { ignore_changes }` を使用する。 |
| **`terraform destroy` の実行** | ❌ **VMごと失われる** | VMが削除されるため設定も消える。OSディスクの保護設定は可能。 |
| **カスタムイメージからVMをリストア** | ❌ **失われる** | イメージに含まれていない手動設定は反映されない。設定はイメージに含めるべき。 |
| **GPO/DSC/Azure Policyなどが有効** | ⚠️ **上書きされる可能性あり** | OS内部の設定はTerraformではなく、これらの構成管理ツールでコード化して管理する。 |

**最も安全な運用は、以下の階層的なアプローチを取ることです。**

1.  **インフラ層 (Terraform):** VM、ネットワーク、ストレージなどの「器」を管理。
2.  **構成管理層 (Ansible/DSC/Packer):** OS内部の設定やアプリケーションのデプロイをコードで管理。
3.  **運用プロセス:** 原則としてVMへの手動変更は行わず、すべての変更をコードに反映させてから適用する。

***

### 元の回答にあった矛盾点について

元の3つの回答には、表現の強弱によるニュアンスの違いはありましたが、内容に大きな矛盾はありませんでした。

*   ある回答では「**基本的には、手動で変更した設定が元に戻ることはありません**」と断定的に記述していました。
*   他の回答では「**通常、TerraformはOS設定を直接書き戻すことはありません。ただし、次のケースでは...**」と、例外があることを前提に記述していました。

これらの表現を統合し、本回答では「**原則として失われないが、特定の条件下では結果的に失われる（または上書きされる）**」という、より正確で誤解の少ない表現に統一しました。これにより、Terraformの基本的な動作と、注意すべき例外ケースの両方を明確に理解できるように構成しました。
