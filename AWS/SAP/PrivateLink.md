# AWS PrivateLinkをわかりやすく

## 一言でいうと
AWS PrivateLinkは、別のVPCやSaaS事業者が提供するサービスに、インターネットを経由せず“プライベートIP”だけで安全に接続するための仕組みです。  
“VPC間のネットワーク接続”ではなく、“特定サービスへの入口（エンドポイント）”をVPC内に作るイメージです。

---

## 何がうれしいのか（解決する課題）
- インターネット非経由で安全に通信（IP公開・NAT不要、DDoS表面積縮小）
- ネットワークを広げずに“サービス単位”で接続（最小権限・簡素化）
- CIDR重複や複雑なルーティングの問題を回避（VPC Peeringや`Transit Gateway`より運用楽）
- SaaSや別アカウントのサービスを社内リソースのように使える

---

## どう動くか（仕組み）
- サービス提供側（provider）は、`NLB (Network Load Balancer)`の背後にサービスを配置し、`VPC endpoint service`として公開します（許可制）。
- 利用側（consumer）は、自分のVPC内のサブネットに`Interface VPC endpoint`（ENI）を作成します。
- アプリは、そのVPC内のプライベートIP（エンドポイントのENI）に向けて通信するだけで、裏でPrivateLinkがprovider側の`NLB`へ安全に中継します。
- `Private DNS`を有効化すると、通常のサービス名（例: `com.amazonaws.ap-northeast-1.ssm`）を引くと自分の`Interface endpoint`のIPに解決され、透過的に使えます。

ポイント
- ルートテーブルへの経路追加は不要（ENI直結のため）
- 通信の開始はconsumer側からのみ（非対称／一方向）
- 通常は同一リージョンで利用（設計時はリージョン要件を確認）

---

## 用語
- `Interface VPC endpoint`（利用側が作る入口）: サブネットに作られる`ENI`。セキュリティグループを設定可能。
- `VPC endpoint service`（提供側の公開口）: `NLB`の背後のサービスを、アカウントや組織単位で許可して公開。
- `Private DNS`: 既存のサービス名を、エンドポイントのプライベートIPに解決させる仕組み。

---

## 代表ユースケース
- 別アカウント/別VPCの社内APIや内部管理ツールへプライベート接続
- サードパーティSaaS（PrivateLink対応）のAPI/DB/ログ収納先へのプライベート接続
- オンプレ（`Direct Connect`/`Site-to-Site VPN`）からAWS内のサービスへ、インターネット非経由で接続
- AWSマネージドサービス（例: `SSM`, `EC2 API`, `ECR`, `KMS` など）へのプライベートアクセス  
  - 参考: `S3`/`DynamoDB`は`Gateway VPC endpoint`が長らく一般的（費用安・スケール容易）。用途に応じて`Interface endpoint`版も選択可。

---

## 似た仕組みとの違い（ざっくり）
- `VPC Peering`: VPC間をL3で直結。サブネット全体が見える。CIDR重複不可。トランジティブ不可。サービス単位の分離が難しい。
- `Transit Gateway`: 多数のVPC/オンプレをハブ&スポークで接続。広域L3接続。ルーティング設計・コストは大きめ。
- `NAT Gateway`: プライベートサブネットからインターネット/パブリックへ出るため。PrivateLinkはインターネット非経由で特定サービスへ。
- `Gateway VPC endpoint`（`S3`/`DynamoDB`向け）: ルートテーブルで経路を張る方式。安価・高スケール。細かなSG制御は不可。  
- PrivateLink（`Interface endpoint`）: ENIベースでSG制御ができ、SaaS/自前サービスにも使える。細粒度で“サービスだけ”つなぐ。

---

## 設計のポイント・制限
- AZごとに`Interface endpoint`を配置（クライアントが動くAZに合わせる）
  - 単一AZだとクロスAZ経由になりレイテンシ/費用/可用性に影響
- `Private DNS`は便利だが、オンプレからの名前解決では`Route 53 Resolver`の連携を検討
- セキュリティ
  - consumer側: `Interface endpoint`にセキュリティグループを適用し、許可する宛先ポートを最小化
  - provider側: `VPC endpoint service`は“許可されたプリンシパルのみ”接続可。アプリは認証/認可を別途実装。
  - ソースIPはproviderのターゲット側で“クライアントの生IPが見えない”点に注意（NLB/PrivateLinkの都合）。クライアント識別はTLS相互認証、アプリレベル認証、接続承認（アカウント単位）で対応
- プロトコルはL4ベース（一般的にはTCP/TLS想定）。HTTPヘッダ書き換え等は不可（`ALB`ではなく`NLB`利用）
- オンプレ到達: 可能（DX/VPN経由でエンドポイントのプライベートIPへ）。DNSとルーティングの整備が必要
- クォータ（上限）あり（エンドポイント数、接続数など）。必要に応じて引き上げ申請
- 料金は`Interface endpoint`の時間課金＋データ処理料＋（provider側の`NLB`等の通常料金）。リージョン/サービスで異なる

---

## 導入フロー（概要）

提供側（provider）
1. `NLB`を作成（ターゲット登録、ヘルスチェック設定）
2. `VPC endpoint service`を作成し、`NLB`を関連付け
3. 接続を許可するプリンシパル（AWSアカウント、`IAM`ユーザー/ロール、`Organizations` OU 等）を設定
4. 必要なら`Private DNS`名を設定し、ドメイン所有確認（ACM検証）

利用側（consumer）
1. `Interface VPC endpoint`を作成（対象サブネット、`security group`、`Private DNS`有無を設定）
2. providerの承認が必要な場合は待機（あるいは自動承認）
3. 名前解決（`Private DNS`/自前のDNS）や到達性（SG/ネットワーク）を確認して接続

最小のCLI例（AWSサービス向け）
```bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-1234567890abcdef0 \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.ap-northeast-1.ssm \
  --subnet-ids subnet-aaa subnet-bbb \
  --security-group-ids sg-0123456789abcdef0 \
  --private-dns-enabled
```

---

## よくあるハマりどころ
- `Private DNS`が有効でも、オンプレや別VPCのリゾルバでは正しく解決されないことがある
  - 対策: `Route 53 Resolver`のインバウンド/アウトバウンドエンドポイント、フォワーダ設定
- クライアントの生IPがprovider側に届かない
  - 対策: mTLS、アプリ認証、アカウント承認、接続ログの相関
- エンドポイントを1AZにしか置いていない
  - 症状: クロスAZトラフィックでコスト増/可用性低下
- セキュリティグループの方向を誤る
  - consumer側`Interface endpoint`のSGで“送信”方向、provider側ターゲットSGで“受信”方向を適切に許可
- DNSキャッシュ/名前解決の不整合（`Private DNS`切替時など）

---

## 料金の考え方（ざっくり）
- consumer: `Interface endpoint`の時間課金（AZ単位）＋データ処理量課金
- provider: `NLB`やバックエンドの通常料金（LCU/時間、データ処理、クロスAZ転送など）
- どの方式（`Gateway endpoint`/`Interface endpoint`/`TGW`/インターネット経由）より安いかは、トラフィック量・AZ配置・SLA要件で変わるため試算推奨

---

## ベストプラクティス（要点）
- クライアントが存在する各AZに`Interface endpoint`を配置
- `Private DNS`＋`Route 53 Resolver`で名前解決を一元化
- 最小権限（接続承認、SG最小化、ポート限定）
- 観測性: NLB/ターゲットのメトリクス、VPCフローログ、アプリログで可視化
- 障害時切替の運用（複数エンドポイント、DNSヘルスチェック、バージョン併走）

---

## まとめ
- PrivateLinkは“サービス単位でプライベートに接続”するための仕組み
- インターネット非経由・CIDR非依存・一方向接続で安全かつシンプル
- `Interface endpoint`（consumer）＋`VPC endpoint service`/`NLB`（provider）という構成理解が鍵
- DNS・AZ配置・セキュリティグループ・認証方式をしっかり設計すると、拡張性と安全性を両立できます

