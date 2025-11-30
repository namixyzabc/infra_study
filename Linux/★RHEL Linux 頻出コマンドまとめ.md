
---

# RHEL Linux 頻出コマンドまとめ

## 1. 基本情報・ハードウェア・システムステータス
サーバにログインした直後や、環境把握のために使用するコマンド群です。

```bash
# OSバージョン確認
cat /etc/redhat-release

# カーネルバージョン確認
uname -r

# ホスト名・仮想化基盤等の確認
hostnamectl

# システム稼働時間・ロードアベレージ・ログインユーザ数
uptime

# 現在時刻・タイムゾーン・NTP同期状態
timedatectl status

# CPU情報の詳細（コア数、アーキテクチャ等）
lscpu

# メモリ搭載量・使用量の確認（-h でGB/MB表示）
free -h

# ハードウェア詳細情報（BIOS、シリアルNo等）
dmidecode -t system

# PCIデバイス一覧
lspci
```

## 2. サービス・プロセス管理
`systemd` によるサービス制御と、個別のプロセス監視・操作です。

### サービス管理 (`systemctl`)
```bash
# サービスの状態確認（Active/Inactive, ログ抜粋）
systemctl status httpd

# サービスの起動・停止・再起動
systemctl start httpd
systemctl stop httpd
systemctl restart httpd

# 設定ファイルの再読み込み（プロセスを落とさずに反映）
systemctl reload httpd

# 自動起動の有効化・無効化
systemctl enable httpd
systemctl disable httpd

# 自動起動設定と起動を同時に行う（RHEL推奨）
systemctl enable --now httpd

# 自動起動が有効になっているサービス一覧
systemctl list-unit-files --type=service | grep enabled

# 起動に失敗しているユニットの確認
systemctl --failed
```

### プロセス管理 (`ps`, `top` 等)
```bash
# プロセス一覧の詳細表示（よく使う形式）
ps aux
ps -ef

# 特定のプロセスを検索
ps aux | grep httpd
pgrep -a httpd

# プロセスツリー表示（親子関係の確認）
ps fax
pstree -p

# リアルタイムリソース監視（CPU/メモリ順）
top -c       # -c でコマンドのフルパスを表示

# プロセスの終了
kill <PID>       # SIGTERM（通常終了）
kill -9 <PID>    # SIGKILL（強制終了）
pkill <名>       # 名前でkill

# 開いているファイルからプロセスを特定
lsof /var/log/httpd/access_log
lsof -i :80      # 80番ポートを使っているプロセス
```

## 3. パッケージ管理 (`dnf` / `rpm`)
RHEL8以降は `dnf` が標準ですが、`yum` コマンドも互換性のため使用可能です。

### `dnf` (yum)
```bash
# パッケージの検索
dnf search <キーワード>

# パッケージの詳細情報
dnf info httpd

# インストール・削除
dnf install -y httpd
dnf remove -y httpd

# システム全体のアップデート
dnf update -y
dnf check-update

# インストール済みパッケージ一覧
dnf list installed

# 特定のファイルがどのパッケージに含まれるか検索
dnf whatprovides /usr/bin/curl

# 操作履歴の確認・取り消し
dnf history
dnf history undo <ID>

# キャッシュクリア
dnf clean all
```

### `rpm` (ローカルファイル・詳細調査)
```bash
# インストール済み全パッケージ表示
rpm -qa

# パッケージに含まれるファイル一覧
rpm -ql httpd

# 特定のファイルがどのパッケージに属するか（インストール済み）
rpm -qf /etc/httpd/conf/httpd.conf

# 設定ファイルが変更されているか検証
rpm -Va
```

## 4. リソース・性能調査（障害対応・チューニング）
システムが重い、応答しない場合の切り分けに使用します。

### CPU・メモリ・全体
```bash
# 全体のリソース使用状況を1秒間隔で表示（r列:待ち行列, si/so:スワップ）
vmstat 1 5

# CPU使用率の内訳（user, system, iowait等）
sar -u 1 5

# メモリ使用状況の履歴
sar -r 1 5

# 過去（当日）の全リソース履歴を表示
sar -A
```

### ディスクI/O
```bash
# ディスク負荷の詳細（%utilが100%に近いとボトルネック）
iostat -xz 1 5

# プロセスごとのディスク書き込み量確認（要インストール）
iotop
```

### 負荷対策・プロファイル
```bash
# パフォーマンスプロファイルの確認と変更（省電力 or 高パフォーマンス）
tuned-adm list
tuned-adm active
tuned-adm profile throughput-performance
```

## 5. ネットワーク・ファイアウォール
`ip`, `ss` コマンドが現代の標準です（`ifconfig`, `netstat` は非推奨）。

### ネットワーク設定・確認
```bash
# IPアドレス・リンク状態確認
ip a

# ルーティングテーブル確認
ip r

# ネットワークインターフェースの統計（エラーパケット等）
ip -s link show eth0

# NetworkManagerによる管理状態
nmcli device status
nmcli connection show
```

### ポート・疎通確認
```bash
# リッスンしているポートとプロセスの確認（TCP/UDP）
ss -tulpn

# 確立済みのTCP接続一覧
ss -antp

# 疎通確認（ICMP）
ping -c 4 8.8.8.8

# 名前解決（DNS）確認
dig example.com
nslookup example.com

# 経路確認（どこで途切れるか）
traceroute -n 8.8.8.8

# TCPポート指定での疎通確認（Telnet代替）
curl -v telnet://192.168.1.10:22
nc -zv 192.168.1.10 22
```

### パケットキャプチャ (`tcpdump`)
```bash
# 特定インターフェース・ポートのパケットを表示
tcpdump -i eth0 port 80 -nn

# ファイルに保存してWireshark等で解析
tcpdump -i any -w /tmp/capture.pcap
```

### ファイアウォール (`firewalld`)
```bash
# 現在の設定一覧（ゾーン、許可サービス、ポート）
firewall-cmd --list-all

# サービスの許可（恒久設定）
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# ポートの許可（恒久設定）
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
```

## 6. ストレージ・ファイルシステム・LVM
ディスク容量管理やパーティション操作です。

```bash
# ディスク使用量とファイルシステムタイプ確認
df -hT

# ディレクトリごとの容量調査（容量圧迫箇所の特定）
du -sh /var/*

# ブロックデバイスの階層構造・UUID確認
lsblk -f

# マウント状況の確認
findmnt
mount

# LVM: 物理ボリューム・ボリュームグループ・論理ボリューム確認
pvs; vgs; lvs

# LVM: 論理ボリュームとファイルシステムの同時拡張（+10GB）
lvextend -r -L +10G /dev/mapper/rl-root
```

## 7. ログ調査・ジャーナル
従来の `/var/log` と `systemd-journald` の両方を確認します。

```bash
# systemd管理のログ（最新のエラーなどを詳細表示）
journalctl -xe

# 特定サービスのログを追跡（tail -f 相当）
journalctl -u httpd -f

# カーネルメッセージ（起動時エラーやOOM Killer等）
dmesg -T
journalctl -k

# システムログ（全体）
tail -f /var/log/messages

# セキュリティログ（ログイン、sudo履歴）
tail -f /var/log/secure

# エラーの検索（再帰的）
grep -r "error" /var/log/
```

## 8. ファイル操作・検索・テキスト処理
実務で役立つ応用コマンドを含みます。

### 検索 (`find`, `grep`)
```bash
# 名前で検索（エラー出力を捨てる）
find / -name "httpd.conf" 2>/dev/null

# 更新が1日以内のファイルを検索
find /var/log -type f -mtime -1

# サイズが100MB以上のファイルを検索
find / -size +100M

# 設定ファイルからコメント行と空行を除外して表示（設定値のみ確認）
grep -Ev "^$|^#" /etc/httpd/conf/httpd.conf
```

### 編集・アーカイブ
```bash
# ファイル内の文字列を一括置換（バックアップ作成含む）
sed -i.bak 's/old-text/new-text/g' file.txt

# 差分確認
diff -u file1.conf file2.conf

# 圧縮・解凍
tar -czvf archive.tar.gz /path/to/dir
tar -xzvf archive.tar.gz

# 同期・バックアップ（権限維持・削除反映）
rsync -avz --delete /src/ /dst/
```

### 便利な表示
```bash
# 更新時刻順に並べて表示（最新ファイルを末尾に）
ls -lart

# ログ集計（例：アクセス数が多いIPトップ10）
awk '{print $1}' access_log | sort | uniq -c | sort -nr | head
```

## 9. ユーザ・権限・SELinux
セキュリティに関わる重要な設定です。

### ユーザ・権限
```bash
# ユーザ情報確認（ID, 所属グループ）
id user1

# ユーザ追加とパスワード設定
useradd -m user1
passwd user1

# 現在のログインユーザ確認
w
last

# 所有者変更（再帰的）
chown -R apache:apache /var/www/html

# パーミッション変更
chmod 755 script.sh
```

### SELinux（トラブルシューティング）
```bash
# 状態確認（Enforcing / Permissive）
getenforce
sestatus

# 一時的に無効化（ログ出力のみにする・切り分け用）
setenforce 0

# SELinuxコンテキストの確認
ls -Z /var/www/html

# コンテキストの修復（ポリシー通りに戻す）
restorecon -Rv /var/www/html

# 拒否ログの検索
ausearch -m avc -ts recent
```

## 10. その他管理（時刻、Cron、証明書など）

```bash
# NTP同期状態（chrony）
chronyc tracking
chronyc sources -v

# Cron設定（ユーザ・システム）
crontab -e
cat /etc/crontab
ls /etc/cron.d/

# SSL証明書の期限確認
openssl x509 -in server.crt -noout -dates

# リソース制限（ファイルディスクリプタ等）
ulimit -a
```

## 11. コンテナ・DB・Webサーバ（ミドルウェア）

```bash
# Podman (Docker互換)
podman ps
podman images
podman run -d -p 8080:80 nginx

# Apache / Nginx 設定テスト
httpd -t
nginx -t

# DB接続
mysql -u root -p
sudo -u postgres psql
```

