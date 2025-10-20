# AWS Transit Gateway（TGW）概要

`Transit Gateway` は、複数の `VPC` やオンプレミス（`VPN`/`Direct Connect`）をリージョン内で集約・相互接続するマネージドなハブサービスです。ハブ＆スポーク型のトポロジで、非推移（トランジティブでない）な `VPC Peering` の複雑さを解消し、大規模ネットワークを一元管理できます。`Transit Gateway Route Table` により、環境別（例：Prod/Dev）などのセグメント分離や、経路制御（どこに行けるか／行けないか）を細かく設計できます。

---

## 覚えるべき要点（用語補足つき）

### 基本コンセプト
- `Transit Gateway (TGW)` はリージョン単位のハブで、複数の接続元（`attachment`）を束ねるルータの役割を果たします（L3ルーティングのみ、NATはしない）。
- `attachment`（アタッチメント）とは、`VPC`、`Site-to-Site VPN`、`Direct Connect Gateway`、`TGW Peering` など TGW への接続単位のこと。
- 変換（NAT）なしのIPルーティングのため、基本は重複しないアドレス設計（非重複CIDR）が必要（オーバーラップは不可。必要ならNAT/ファイアウォール等で解決）。
- マルチアカウント環境では `AWS Resource Access Manager (RAM)` を使って TGW を共有可能。

### 主なアタッチメント種別
- `VPC attachment`
  - TGW が各 `AZ` のサブネットに `ENI` を配置して接続（AZ単位で冗長化するにはAZごとにサブネットを指定）。
  - `appliance mode` を有効化すると、ステートフルな中間装置（例：FW）を通す際の経路対称性（往復が同じ経路）を担保できる。
- `Site-to-Site VPN attachment`
  - IPsecトンネル。`BGP` による動的ルーティングに対応。複数トンネルでの `ECMP`（等コスト経路分散）により冗長化・スループット向上が可能。
- `Direct Connect Gateway (DXGW) attachment`
  - `Transit VIF` 経由で TGW に接続。`BGP` による動的ルーティング。オンプレから複数VPCへのハブ接続に適する。
- `Transit Gateway Peering attachment`
  - TGW 間のリージョンを跨いだ接続。AWSバックボーン上で暗号化される。非推移（中継不可）に注意。
  - 制限：`VPN`/`DX` 由来の経路はピアリング越しに伝播しない（オンプレ経路を他リージョンTGWへ“中継”できない）。
- `Transit Gateway Connect`
  - GRE+BGP による SD-WAN 統合向け機能（仮想/物理アプライアンスと連携しやすい）。
- `Multicast`
  - TGWマルチキャスト（`IGMP` ベース）。特定ユースケース向けで試験では優先度低め。

### Transit Gateway Route Table（経路制御の要）
- TGW は複数の `Transit Gateway Route Table` を持てる。VPCごとや環境ごとに分離可能（例：`prod-rt`、`dev-rt`）。
- `association（関連付け）` と `propagation（伝播）` の違いが最重要。
  - `association`：ある `attachment` から出るトラフィックが「どのルートテーブルを参照するか」を決める。
  - `propagation`：ある `attachment` のプレフィックス（CIDR）を「どのルートテーブルへ学習させるか」を決める。
- `default route table` の挙動
  - 既定で新規 `attachment` はデフォルトRTに関連付け/伝播される設定になりがち。意図しない横断通信が起きるため、明示的に無効化/分離するのがベストプラクティス。
- ルートは静的追加も可能。`VPN`/`DX` は `BGP` により動的に経路伝播できる。
- `Prefix List` を参照したルーティング指定に対応し、運用性を向上できる。

### 代表的な設計パターン
- 共有サービスVPC（Shared Services）
  - AD、DNS、監視、CI/CDなど共通基盤を1つのVPCに集約し、他VPCからTGW経由で到達。
  - ルートテーブルを分けることで不要な横断通信を遮断。
- 集中Egress/NAT（Centralized Egress）
  - 各スポークVPCのデフォルトルート（`0.0.0.0/0`）をTGWへ向け、中央のEgress VPCで `NAT Gateway` や `Internet Gateway` から外部通信。
  - ステートフル検査（FW）を挟むなら `appliance mode`＋対称ルーティング設計が必須。
- 中央インスペクション（Firewall/GWLB統合）
  - サービス間通信・外向き通信を中央のセキュリティVPC経由で検査。`Gateway Load Balancer (GWLB)` 連携でスケール。
- ハイブリッド接続の集約
  - `DXGW`/`VPN` を TGW に集約し、複数VPCへ配布。バックアップとして `VPN` を併設（DX障害時にフェイルオーバー）。

### 注意点・制限（試験で問われやすい）
- アドレス重複
  - TGW単体では重複CIDRは扱えない。NAT/ファイアウォールで変換・分離するか、設計で回避。
- 非推移の原則
  - `TGW Peering` は中継不可（他TGWを経由した三角接続はできない）。`VPN`/`DX` の経路はピア越しに広まらない。
- セキュリティグループ参照
  - `VPC Peering` のような他VPCセキュリティグループID参照は `TGW` 経由では不可。到達制御はルーティングとFWで行う。
- DNS
  - TGWはDNSを転送しない。クロスVPC解決は `Route 53 Resolver` の `Inbound/Outbound Endpoint` と `Resolver ルール共有（RAM）` を使う。
- VPCエンドポイントの特性
  - `Gateway Endpoint`（S3/DynamoDB）は“非トランジティブ”。中央化しても他VPCからTGW経由では使えない。必要VPCごとに配置するか、`Interface Endpoint`/`PrivateLink` を検討。
- アプライアンス経由の非対称問題
  - ステートフルFWは送受信が同経路でないとセッション破棄の原因。`appliance mode` とRT設計で対称性を担保。

### 可用性・性能
- AZ冗長
  - `VPC attachment` はアタッチ時に各AZのサブネットを指定。複数AZで冗長化。
- スループットとECMP
  - `VPN` は複数トンネルで `ECMP` を使いスループット/可用性を向上。DXは回線側冗長設計が基本。
- MTU
  - VPC間は大きめMTUが使えるが、`VPN`（IPsec）はMTUが小さくなる。アプリ要件に注意。
- クォータ
  - アタッチメント数、ルート数、ルートテーブル数に上限あり（リージョン/アカウントの最新クォータを確認）。必要に応じて引き上げ申請。

### コストの考え方
- 課金は主に以下：
  - `attachment` の時間課金（接続数に比例）。
  - `data processing` の転送量課金（TGWを経由するトラフィック量に比例）。
  - リージョン間は `TGW peering` のデータ処理＋リージョン間データ転送料金。
  - クロスAZ通信は追加コストがかかり得るため、AZローカル最適化を検討。
- `VPC Peering` より運用は楽だが、データ処理課金が発生。トラフィックパターンを踏まえ費用対効果を評価。

### 運用・監視
- 可視化・運用
  - `Transit Gateway Flow Logs` でフローを `CloudWatch Logs`/`S3` に出力し、到達性やトラブルシュートに活用。
  - `CloudWatch` メトリクスでアタッチメント別の統計を監視。
  - `Transit Gateway Network Manager` でSD-WAN連携、トポロジ/経路可視化、イベント管理。
- IaC
  - `CloudFormation`/`Terraform` で `attachment`、`route table`、`association`/`propagation` をコード化しドリフトを防止。

### 試験対策の着眼点（シナリオで狙われやすいところ）
- 「多VPC・多アカウント・オンプレ統合を簡素化したい」→ `Transit Gateway`。`VPC Peering` は非推移でスケールしない。
- 「環境分離（Prod/Dev）＋共有サービスにだけ到達」→ 複数 `Transit Gateway Route Table` と `association/propagation` 制御。
- 「DX本番＋VPNバックアップ」→ `BGP` とルート優先度（AS-Path/メトリクス）でフェイルオーバー設計。
- 「中央FWで検査」→ セキュリティVPC＋`appliance mode`＋対称ルーティング。`GWLB` 連携でスケールアウト。
- 「リージョン間VPC接続」→ `TGW Peering`（ただしオンプレ経路は広がらない点に注意）。
- 「DNSが通らない」→ TGWはDNS中継しない。`Route 53 Resolver` のエンドポイントとルール共有が必要。
- 「S3/DynamoDBを中央VPC経由で使いたい」→ `Gateway Endpoint` は非トランジティブ。各VPCに配置するか、別方式を検討。
- 「CIDR重複」→ TGWでは解決不可。NAT/ファイアウォール（SNAT/DNAT）で回避、またはアドレス再設計。
- 「意図せぬ横断通信が発生」→ デフォルトの `association/propagation` を無効化し、RTを明示的に分離。

---

必要なキーワードと因果（なぜそう設計するか）をセットで覚え、`association（出るとき参照）` と `propagation（経路を載せる）` を即答できるようにしておくと、試験問題の大半は見切れます。
