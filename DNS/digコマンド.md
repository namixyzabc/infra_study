# digコマンド完全ガイド

## 基本概要
`dig`（Domain Information Groper）は、DNSの情報を調査するためのコマンドラインツールです。nslookupよりも詳細で柔軟な情報取得が可能です。

## 基本構文
```bash
dig [@DNSサーバー] ドメイン名 [レコードタイプ] [オプション]
```

## 基本的な使い方

### 1. 最もシンプルな使用法
```bash
dig google.com
```
→ AレコードとDNSサーバーの情報を表示

### 2. 特定のレコードタイプを指定
```bash
dig google.com MX      # メールサーバー情報
dig google.com NS      # ネームサーバー情報
dig google.com AAAA    # IPv6アドレス
dig google.com TXT     # テキストレコード
dig google.com CNAME   # エイリアス情報
```

### 3. 特定のDNSサーバーに問い合わせ
```bash
dig @8.8.8.8 google.com        # GoogleのDNS
dig @1.1.1.1 google.com        # CloudflareのDNS
dig @208.67.222.222 google.com # OpenDNS
```

## 実務でよく使うコマンド集

### DNS設定の確認・トラブルシューティング

```bash
# ドメインのすべてのレコードタイプを確認
dig google.com ANY

# 権威DNSサーバーから直接問い合わせ
dig @ns1.google.com google.com

# 逆引き（IPアドレスからドメイン名）
dig -x 8.8.8.8

# DNSの伝播確認（複数のDNSサーバーで確認）
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com
dig @208.67.222.222 example.com
```

### 詳細情報の取得

```bash
# 簡潔な出力（IPアドレスのみ）
dig +short google.com

# トレース機能（ルートから順番に辿る）
dig +trace google.com

# キャッシュを使わず権威サーバーから取得
dig +norecurse google.com

# 詳細なデバッグ情報付き
dig +debug google.com
```

## 実務レベルの活用例

### 1. Webサイト移行時のDNS確認
```bash
#!/bin/bash
# 複数のDNSサーバーでレコードをチェック
DOMAIN="example.com"
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")

for dns in "${DNS_SERVERS[@]}"; do
    echo "=== DNS Server: $dns ==="
    dig @$dns +short $DOMAIN
    echo
done
```

### 2. メール設定の確認
```bash
# MXレコードの確認
dig example.com MX

# SPFレコードの確認
dig example.com TXT | grep -i spf

# DKIMレコードの確認
dig selector1._domainkey.example.com TXT
```

### 3. CDN・ロードバランサーの設定確認
```bash
# 地域別DNSの確認
dig +short example.com
dig +short @8.8.8.8 example.com
dig +short @208.67.220.220 example.com

# TTL値の確認
dig example.com | grep "IN.*A"
```

### 4. セキュリティ関連の確認
```bash
# DNSSEC確認
dig +dnssec example.com

# CAA（証明書発行許可）レコード確認
dig example.com CAA

# DMARCポリシー確認
dig _dmarc.example.com TXT
```

## 便利なオプション一覧

| オプション | 説明 |
|------------|------|
| `+short` | 簡潔な出力（結果のみ） |
| `+trace` | クエリの経路を表示 |
| `+norecurse` | 再帰問い合わせなし |
| `+tcp` | TCPで問い合わせ |
| `+time=5` | タイムアウト時間設定 |
| `+retry=3` | リトライ回数設定 |
| `+noall +answer` | 回答部分のみ表示 |

## よくあるトラブルシューティング

### 1. DNS伝播の確認
```bash
# 世界各地のDNSサーバーで確認
dig @8.8.8.8 +short example.com          # Google（米国）
dig @208.67.222.222 +short example.com   # OpenDNS（米国）
dig @1.1.1.1 +short example.com          # Cloudflare（グローバル）
```

### 2. 権威サーバーの確認
```bash
# ドメインの権威サーバーを確認してから直接問い合わせ
NS_SERVER=$(dig +short example.com NS | head -1)
dig @$NS_SERVER example.com
```

### 3. パフォーマンス測定
```bash
# 応答時間の測定
dig example.com | grep "Query time"

# 複数回実行して平均を取る
for i in {1..5}; do
    dig example.com | grep "Query time"
done
```

## 実際の運用シーン

### ドメイン移行チェックリスト
```bash
# 1. 現在の設定確認
dig old-domain.com ANY

# 2. 新しいDNS設定の確認
dig @new-dns-server.com new-domain.com

# 3. TTL確認（低い値に設定されているか）
dig old-domain.com | grep -E "^old-domain.com.*IN.*A"

# 4. 移行後の確認
dig +trace new-domain.com
```

これらのコマンドを使い分けることで、DNS関連の問題を効率的に診断・解決できます。特に`+short`と`+trace`は日常的によく使うオプションなので覚えておくと便利です。
