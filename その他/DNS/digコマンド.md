# digコマンドの実務的な使い方

## 基本構文
```bash
dig [@サーバー] [ドメイン] [レコード種類] [オプション]
```

## 1. 基本的な使い方

### 最もシンプルな使用
```bash
dig google.com
```

**出力結果の見方:**
```
; <<>> DiG 9.18.12 <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; QUESTION SECTION:
;google.com.			IN	A

;; ANSWER SECTION:
google.com.		300	IN	A	142.250.196.142

;; Query time: 15 msec
;; SERVER: 192.168.1.1#53(192.168.1.1)
;; WHEN: Wed Jan 10 10:30:45 JST 2024
;; MSG SIZE  rcvd: 55
```

**重要な部分:**
- `ANSWER SECTION`: 実際の回答（IPアドレス）
- `300`: TTL（秒）
- `Query time`: 応答時間

## 2. 実務でよく使うパターン

### A) シンプルな結果のみ表示（+short）
```bash
dig google.com +short
142.250.196.142
```
→ **一番よく使う！** 余計な情報なしでIPアドレスだけ

### B) 特定のレコード種類を調べる
```bash
# MXレコード（メールサーバー）
dig google.com MX +short
10 smtp.google.com.

# CNAMEレコード
dig www.github.com CNAME +short
github.com.

# NSレコード（ネームサーバー）
dig google.com NS +short
```

### C) 特定のDNSサーバーに問い合わせ
```bash
# Googleの公開DNSに問い合わせ
dig @8.8.8.8 google.com +short

# Cloudflareの公開DNSに問い合わせ
dig @1.1.1.1 google.com +short
```

## 3. トラブルシューティングでよく使う

### 逆引き（IPからドメイン名を調べる）
```bash
dig -x 8.8.8.8 +short
dns.google.
```

### TTL値を確認（キャッシュ問題の調査）
```bash
dig google.com | grep "IN A"
google.com.		300	IN	A	142.250.196.142
```
→ 300秒でキャッシュが更新される

### トレース（DNS解決の経路を確認）
```bash
dig google.com +trace
```
→ ルートサーバーから順番に解決過程を表示

## 4. 実務的な活用例

### サーバー移行時の確認
```bash
# 移行前後でIPが変わったか確認
dig example.com +short
```

### ロードバランサーの確認
```bash
# 複数のIPが返ってくるか確認
dig cdn.example.com +short
203.0.113.1
203.0.113.2
203.0.113.3
```

### メールサーバーの設定確認
```bash
dig example.com MX +short
10 mail1.example.com.
20 mail2.example.com.
```

## 5. 便利なエイリアス設定

`.bashrc`に追加すると便利：
```bash
alias digs='dig +short'
alias digmx='dig MX +short'
alias digns='dig NS +short'
```

使用例：
```bash
digs google.com          # dig google.com +short と同じ
digmx google.com         # dig google.com MX +short と同じ
```

## まとめ：最低限覚えるべき3つ

1. `dig ドメイン名 +short` - IPアドレスを素早く確認
2. `dig @8.8.8.8 ドメイン名 +short` - 特定DNSサーバーで確認  
3. `dig ドメイン名 MX +short` - メールサーバー確認

