
---

# RHEL Linux 使用頻度の高いディレクトリ・パス

## 1. システム基本情報・リリース管理
OSのバージョンや個体識別に関する情報です。

- **/etc/redhat-release**：RHELのリリースバージョン情報（例: `Red Hat Enterprise Linux release 8.8`）。
- **/etc/os-release**：OS詳細情報の定義ファイル（スクリプト処理での参照推奨）。
- **/etc/hostname**：ホスト名設定。
- **/etc/machine-id**：システム固有ID（DBUS等で使用）。
- **/proc/version**：カーネルバージョンやビルド情報。
- **/sys/class/dmi/id/**：ハードウェアのシリアル番号やUUID（`product_uuid`, `product_serial`など）。

## 2. ログ・監査・障害調査（最重要）
障害発生時の初動調査で必ず確認するファイル群です。

### システムログ
- **/var/log/messages**：システム全体の汎用ログ。
- **/var/log/secure**：認証、sudo、SSHなどのセキュリティ関連ログ。
- **/var/log/boot.log**：ブート時のサービス起動ログ。
- **/var/log/cron**：cron定期実行ジョブの履歴。
- **/var/log/dmesg**：カーネルバッファ（ハードウェア認識・ドライバ）のログ。
- **/var/log/maillog**：メール配送ログ（Postfix等）。

### Systemd / Audit / その他
- **/var/log/journal/**：systemd-journaldのログ永続化保存先。
- **/run/log/journal/**：systemdログの一時保存先（揮発性）。
- **/var/log/audit/audit.log**：Auditd監査ログ（SELinux拒否ログや詳細な操作履歴）。
- **/var/crash/**：kdumpによるカーネルクラッシュダンプ（vmcore）保存先。
- **/var/log/sa/**：sar（sysstat）の統計データファイル。

## 3. ネットワーク設定
- **/etc/hosts**：静的なホスト名解決（DNS参照前）。
- **/etc/resolv.conf**：DNSサーバー（リゾルバ）設定。
- **/etc/nsswitch.conf**：名前解決の優先順位設定。
- **/etc/services**：ポート番号とサービス名の定義。
- **/etc/sysconfig/network-scripts/**：【RHEL7/8まで主流】`ifcfg-*` 形式のインターフェース設定。
- **/etc/NetworkManager/**：NetworkManagerの全般設定。
- **/etc/NetworkManager/system-connections/**：【RHEL8/9推奨】NetworkManagerの接続プロファイル（keyfile形式）。
- **/etc/firewalld/**：firewalldの設定（`zones/`, `services/`など）。
- **/etc/ssh/**：SSH設定（`sshd_config`：サーバー設定、`ssh_config`：クライアント設定）。

## 4. ユーザー・認証・セキュリティ
- **/etc/passwd**：ユーザーアカウント情報。
- **/etc/shadow**：暗号化されたパスワード情報（rootのみ閲覧可）。
- **/etc/group**：グループ定義。
- **/etc/sudoers** および **/etc/sudoers.d/**：sudo実行権限の設定。
- **/etc/pam.d/**：PAM（Pluggable Authentication Modules）認証設定。
- **/etc/security/limits.conf**：ユーザーごとのリソース制限（ulimit）。
- **/root/.ssh/**：rootユーザーのSSH鍵（`authorized_keys`等）。
- **/home/*/.ssh/**：一般ユーザーのSSH鍵。
- **/etc/pki/tls/certs/**：SSL/TLS証明書（`ca-bundle.crt`等）。
- **/etc/pki/tls/private/**：SSL/TLS秘密鍵。

### SELinux
- **/etc/selinux/config**：SELinuxのモード（Enforcing/Permissive/Disabled）設定。
- **/var/log/audit/audit.log**：SELinuxの拒否ログ（AVC denial）確認先。

## 5. ストレージ・ファイルシステム
- **/etc/fstab**：起動時のファイルシステムマウント設定（記述ミスは起動不能の原因）。
- **/proc/mounts**：現在のマウント状況（カーネル情報）。
- **/dev/**：デバイスファイル格納先（`/dev/sda`, `/dev/mapper/*`など）。
- **/dev/disk/**：ディスクの永続名（UUIDやIDでの指定用）。
- **/etc/lvm/**：LVM（論理ボリューム）設定（`lvm.conf`など）。
- **/etc/multipath.conf**：マルチパス（DM-Multipath）設定。
- **/etc/mdadm.conf**：ソフトウェアRAID設定。

## 6. カーネル・ブート・パフォーマンス
- **/boot/**：カーネルイメージ（vmlinuz）、initramfs格納先。
- **/boot/grub2/grub.cfg**：GRUB2設定（BIOSブート用）。
- **/boot/efi/EFI/redhat/grub.cfg**：GRUB2設定（UEFIブート用）。
- **/etc/default/grub**：GRUB設定の生成元ファイル（カーネルパラメータ変更時はここを編集）。
- **/proc/cmdline**：現在起動しているカーネルの起動パラメータ。
- **/etc/sysctl.conf** および **/etc/sysctl.d/**：カーネルパラメータ（sysctl）の永続設定。
- **/lib/modules/**：カーネルモジュール格納先。
- **/etc/kdump.conf**：kdump（クラッシュダンプ）の設定。
- **/etc/tuned/**：パフォーマンスチューニングツール（Tuned）の設定。

### Procfs / Sysfs（動的情報）
- **/proc/cpuinfo**：CPU情報。
- **/proc/meminfo**：メモリ詳細情報。
- **/proc/loadavg**：ロードアベレージ。
- **/proc/[pid]/**：プロセスごとの詳細情報（起動コマンド、FD、環境変数など）。
- **/sys/class/net/**：ネットワークインターフェース情報。
- **/sys/block/**：ブロックデバイス情報。

## 7. サービス管理・スケジュール・自動化
- **/usr/lib/systemd/system/**：パッケージ標準のUnitファイル（デフォルト）。
- **/etc/systemd/system/**：管理者が作成・変更するUnitファイル（優先される）。
- **/etc/crontab**：システム全体のcron設定。
- **/etc/cron.d/**：アプリケーション等のcron設定ドロップインディレクトリ。
- **/var/spool/cron/**：各ユーザーのcrontab設定実体。
- **/etc/rc.local**：起動時実行スクリプト（互換用）。

## 8. パッケージ管理（DNF/YUM・RPM）
- **/etc/dnf/dnf.conf**（または `/etc/yum.conf`）：パッケージ管理ツールの全体設定。
- **/etc/yum.repos.d/**：リポジトリ定義ファイル（`.repo`）。
- **/var/lib/rpm/**：RPMデータベース（パッケージ情報の管理簿）。
- **/var/log/dnf.log**：パッケージ操作履歴。
- **/etc/rhsm/**：Red Hat Subscription Manager設定。

## 9. アプリケーション・ミドルウェア設定（代表例）
- **/etc/httpd/**：Apache HTTP Server設定。
- **/etc/nginx/**：Nginx設定。
- **/etc/my.cnf**：MySQL/MariaDB設定。
- **/var/lib/mysql/** (または `pgsql`): データベースのデータディレクトリ。
- **/etc/postfix/**：Postfix（メール）設定。
- **/etc/aliases**：メール転送設定。
- **/etc/chrony.conf**：時刻同期（Chrony）設定。
- **/etc/localtime**：タイムゾーン設定（`/usr/share/zoneinfo/`へのリンク）。
- **/etc/exports**：NFS共有設定。

## 10. 環境変数・ライブラリ・パス
- **/etc/profile**：システム全体のログインプロファイル。
- **/etc/profile.d/**：環境変数設定スクリプトの追加用ディレクトリ。
- **/etc/bashrc**：bash利用者全体の共通設定。
- **/etc/ld.so.conf** および **/etc/ld.so.conf.d/**：共有ライブラリの検索パス設定。
- **/usr/bin/**：一般ユーザー用コマンド。
- **/usr/sbin/**：システム管理用コマンド。
- **/usr/lib/**, **/usr/lib64/**：ライブラリファイル。

## 11. 一時ファイル・ランタイム
- **/tmp/**：一時ファイル（多くは再起動不要、定期的削除）。
- **/var/tmp/**：再起動後も保持される一時ファイル。
- **/run/**：システム実行中のランタイムデータ（PIDファイル、ソケット等。再起動で消える）。
- **/dev/shm/**：共有メモリ。

---
