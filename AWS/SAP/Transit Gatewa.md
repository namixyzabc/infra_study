# 概要

`Transit Gateway (TGW)` は、複数の `VPC`、オンプレミス（`VPN`/`Direct Connect`）、および別リージョン間（`TGW Peering`）をハブ&スポーク型で一元接続するAWSのリージョナルなネットワーク集約サービスです。従来の `VPC Peering` のような「メッシュ接続の管理負荷」や「トランジティブルーティング不可」といった制約を解消し、大規模・多アカウント・ハイブリッド構成での接続・分離・経路制御をシンプルにします。  
ルーティングは「インバウンド側アタッチメントに結び付けた `TGW ルートテーブル`」で決定され、`アタッチメント`（接続点）の種類に応じて経路の伝播（`Propagation`）や関連付け（`Association`）を柔軟に制御でき、セグメンテーション（業務/環境ごとの分離）や中央集約型のセキュリティ検査にも対応します。

---

# 覚えるべき要点

## 基本概念（用語は平易に補足）
- `Transit Gateway (TGW)`: リージョン内のハブ。複数の接続（アタッチメント）を束ね、転送の要になります。
- `Attachment（アタッチメント）`: TGWと何かを接続する“差し込み口”。例: `VPC Attachment`, `VPN Attachment`, `Direct Connect Gateway (DXGW) Attachment`, `Peering Attachment`, `Connect Attachment`, `Multicast Attachment`。
- `TGW Route Table`: 経路の集合。どのアタッチメントから入ってきたトラフィックを、どこ（どのアタッチメント）へ送るかを決めます。
- `Association（関連付け）`: あるアタッチメントの“入ってくるトラフィック”が、どの `TGW Route Table` を参照するかの設定。
- `Propagation（伝播）`: アタッチメントが持つプレフィックス（到達可能なネットワーク）を、指定の `TGW Route Table` に自動登録する仕組み。
- `Longest Prefix Match（最長一致）`: 経路選択の基本ルール。より具体的なプレフィックスが優先。
- `ECMP（Equal-Cost Multi-Path）`: 同コスト経路が複数あれば負荷分散する仕組み。BGP学習経路に対して有効。
- `Blackhole Route`: マッチしたトラフィックを破棄する経路。誤経路や検疫的制御に使用。
- `Appliance mode support（アプライアンスモード）`: 仮想FWなどステートフル機器のために経路非対称を防ぐためのモード。AZローカル経路の保持を強化します。

## アタッチメントの種類と使いどころ
- `VPC Attachment`
  - VPCの各AZから1つずつ“TGW専用ENIを置くサブネット（アタッチメントサブネット）”を指定します。冗長化のため各AZに作成。
  - 帯域はAZ単位でスケール（一般に「1アタッチメントあたりAZごとに高スループット」）。クロスAZ転送は課金・遅延増のため、同一AZ内経路を取れるよう設計。
- `Site-to-Site VPN Attachment`
  - `IPsec` トンネル（最大2トンネル/接続）でオンプレに接続。`BGP` 使用時は経路自動学習・`ECMP` 分散が可能。静的ルートも可。
  - 帯域はトンネルあたり中程度。多数並行でスケール可能（ECMP）。
- `Direct Connect Gateway (DXGW) Attachment`
  - `Direct Connect (専用線)` をTGWに結びます（`transit VIF` 経由）。大容量・低遅延・安定性が利点。BGPで経路学習。
  - オンプレ側の経路広告制限（許可プレフィックス）や経路数上限に留意。
- `TGW Peering Attachment`（リージョン間）
  - リージョン間をTGW同士で接続。暗号化はAWS管理。マルチリージョンのハブ&スポークに。
  - トランジティブではない（後述）。`VPN/DX` の“エッジ”経路をPeering越しに転送することは不可（試験の落とし穴）。
- `Connect Attachment`
  - `SD-WAN` ベンダー等向け。`GRE` トンネルと`BGP` を用いた接続方式（既存のVPC/VPNを“Transport”にして、その上にConnectを載せるイメージ）。
  - 高スケール・動的経路制御に向き、支社拠点の大量収容に適する。
- `Multicast Attachment`
  - マルチキャスト（`IGMP v2/v3`）をTGW上で提供。VPC内ENIが送受信者。`VPN/Peering` 越えやインターネット越えは不可。
  - `Multicast domain` と送受信サブネットの登録が必要。

## ルーティングの要点（“入口のテーブルを見る”が原則）
- 経路判定は「パケットが入ってきたアタッチメントに関連付けられた `TGW Route Table`」で行う（出口側ではない点が重要）。
- `Propagation` により、VPC CIDRやBGP学習ルートなどを自動でテーブルへ注入可能。手動の静的ルートと併用できる。
- `ECMP` は同一プレフィックス宛ての複数経路に対して負荷分散（主にVPN/BGPで活用）。
- `Blackhole Route` は明示的なドロップに使用。誤経路や隔離に有効。
- `Appliance mode support` を有効にすると、同一AZ内での送受信が維持され、ステートフルFW/IPS等で“非対称経路”が起きにくくなる。検査VPC挿入時に有効。
- `AZローカルルーティング` と `クロスAZ転送`:
  - TGWは可能な限り同一AZにあるアタッチメントENIへ転送。指定したAZにアタッチメントサブネットを用意していないと、他AZに転送され、コスト/遅延の増加につながる。
  - 各VPCアタッチメントで“必要なAZすべて”に専用サブネットを作るのが定石。

## セグメンテーション（論理的な分離）
- 複数の `TGW Route Table` を作成し、環境/業務/機密度ごとに分離。
  - 例: `prod-rt`, `stg-rt`, `shared-rt` を分け、`prod` からは `stg` へ行けないようにする。
- `Association` と `Propagation` の組み合わせで、「誰から何が見えるか」を制御。
- `Transit Gateway Route Table Policies`（ポリシーベース制御）を使うと、タグやBGP属性に基づく柔軟な経路流通制御が可能（大規模環境で有効）。

## 代表的デザインパターン
- ハブ&スポーク型中央集約
  - `TGW` をハブ、各業務VPCをスポーク。`shared-services VPC`（AD/DNS/監査/CI/CD）へは必要な経路のみ許可。
- 集中検査（Inspection VPC）
  - `GWLB（Gateway Load Balancer）` と仮想FWをVPC内に配置し、`appliance mode` とルートテーブルの経路誘導で全トラフィックをFW経由に。
- 中央インターネット出口
  - 各スポークVPCのデフォルトルートをTGWへ集約し、NAT/Firewallを持つ`egress VPC`から外部へ。戻り経路の対称性確保が鍵。
- ハイブリッド接続のハブ
  - オンプレは `DXGW` または `VPN` でTGWに収容。BGP/ECMPで冗長化・スケール。クラウド側の経路伝播を自動化。
- マルチリージョン拡張
  - 各リージョンにTGWを置き、`Peering Attachment` で接続。グローバルネットワークの骨格に。

## できない/注意すべきこと（試験で狙われやすい）
- `Peering Attachment` は「非トランジティブ」:
  - TGW A —(Peering)— TGW B — VPC への経路はOKだが、
  - TGW A — DX/VPN —(Peering)— TGW B — VPC のような “エッジ（DX/VPN）→Peering→他TGW” は不可（エッジtoエッジやエッジ越しのトランジティブは禁止）。
- `VPC Peering` と違い、TGWは「トランジティブなハブ」だが、“非VPC系（VPN/DX/Peering）間”の相互中継は制限あり。
- オーバーラップCIDR（重複アドレス空間）はルーティング衝突の原因。TGW経由の統合前にアドレス計画を整理。
- 対称ルーティングが必要な仮想アプライアンスは `appliance mode support` とAZ設計、戻り経路の最長一致で崩れやすい点に注意。
- ルーティングは“入口のルートテーブル”を見る。出口側の設定だけでは流れない。

## ルーティング設計の実践Tips
- ルート作法
  - 入口テーブル単位で「どの宛先はどのアタッチメントへ」を明示。`0.0.0.0/0`（既定経路）で中央出口や検査VPCを指すのが一般的。
  - `Propagation` は便利だが“見せたくない”経路も混入する。不要経路はポリシー/手動ルート/ブラックホールで制限。
- BGP/ECMP
  - オンプレ冗長はBGP推奨。複数VPN/DX経路でECMP活用。最長一致とAS Path等のチューニングで意図した経路選好を設計。
- スポーク間通信
  - スポーク同士を直接許すか、検査経由にするかをテーブル分割とデフォルトルートで制御。
- `TGW` にセキュリティグループはない
  - フィルタリングはVPC内の `Security Group` / `NACL`、または `AWS Network Firewall` + ルーティングで実現。

## DNS/サービス発見のポイント
- `TGW` 自体はDNSを転送しません。`Route 53 Private Hosted Zone` を複数VPCで共有するには `Private Hosted Zoneの関連付け` または `Route 53 Resolver`（インバウンド/アウトバウンドエンドポイント＋転送ルール）を併用。
- DNSはユニキャスト通信。マルチキャストDNSはTGWのマルチキャスト機能の対象外。

## 共有/マルチアカウント
- `AWS Resource Access Manager (RAM)` で `TGW` と `TGW Route Table` を組織内の他アカウントへ共有可能。
- 中央ネットワークアカウントがTGWを保有し、各ワークロードアカウントのVPCをアタッチするのがベストプラクティス。

## 運用・監視・トラブルシュート
- ログ/メトリクス
  - `Transit Gateway Flow Logs`: アタッチメント間のフローを `CloudWatch Logs`/`S3`/`Kinesis` に出力。到達性やセキュリティ調査に有用。
  - `CloudWatch Metrics`: バイト/パケット数、ドロップなど。スパイク検知やキャパシティ判断に。
- 経路可視化
  - `VPC Reachability Analyzer` はTGW経由のパス解析をサポート。意図せぬ欠落経路やNACL/SG起因の到達不可を診断。
- IaC/変更管理
  - `CloudFormation`/`Terraform` で `attachments`、`route tables`、`associations`、`propagations` をコード化。環境間差異やドリフトを削減。

## スループット・スケール・クォータ（代表的な考え方）
- VPCアタッチメントはAZ単位でスケール（高スループット）。必要AZにアタッチメントサブネットを配置。
- VPNはトンネル数でスケールし、BGP/ECMPで帯域を足し算可能。
- DXは回線帯域（1/2/5/10/100Gbps等）と `transit VIF` 数・冗長構成でスケール。
- 具体的な数値上限（アタッチメント数、ルート数等）はリージョンや時期で更新されるため、試験対策は「設計原則」と「制約の種類」を優先して覚え、最新クォータはドキュメントで確認。

## コストモデルの勘所
- 主な課金要素
  - `アタッチメント時間単価`（接続しているだけで従量）
  - `データ処理量（GB）`（TGWを通過するトラフィック）
  - `Peering` 間のデータ転送
- 最適化のコツ
  - 同一AZ内での転送を維持（クロスAZ転送は追加コスト）
  - 不要な東西トラフィックを抑止（セグメント分割、最長一致の活用）
  - 検査VPC挿入時も、AZ対称設計で迂回・クロスAZを削減

## マルチキャスト
- `Multicast domain` を作り、送信/受信サブネットを登録。`IGMP` によりグループ管理。
- 制約: `Peering`/`VPN`/`DX` 越し不可、同リージョン内のVPC ENI間のみ。ユースケースは市場データ配信など。

## 試験対策 重要ポイント（覚えやすく）
- 入口側の `TGW Route Table` がルックアップされる。戻り経路の最長一致も常に意識。
- `Peering Attachment` は非トランジティブ。`DX/VPN` を跨いだ中継は不可（“edge-to-edge”禁止）。
- セグメンテーションは `Association` と `Propagation` の組み合わせ＋必要なら `Route Table Policies`。
- 仮想FW/検査の経路対称性は `appliance mode support` とAZ配置で担保。
- ハイブリッドはBGP+ECMPでスケール。静的ルートは小規模/一時利用向け。
- `TGW` 自体にファイアウォール機能はない。`SG/NACL/Network Firewall/GWLB` とルーティングで構成。
- RAM共有で組織横断のネットワーク基盤を中央運用。

## 例: 典型的な中央インターネット出口構成（まとめ）
- 各アプリVPCは `0.0.0.0/0` を `TGW` へ。`TGW Route Table` で `egress VPC` のアタッチメントへ誘導。
- `egress VPC` 内で `GWLB+仮想FW` と `NAT Gateway` を配置。`appliance mode` で対称性を確保。
- オンプレは `DX` を優先、`VPN` をバックアップに。BGPでフェイルオーバー/ECMP。

---

- AWS Network Manager/Global Network（可視化・運用）: https://docs.aws.amazon.com/vpn/latest/networkmanager/what-is-network-manager.html

この要点を押さえれば、設計問題（セグメンテーション、中央検査、マルチリージョン、ハイブリッド冗長）に対して、制約とベストプラクティスを根拠に選択肢を絞り込めるようになります。
