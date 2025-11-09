# NGINXの設定方法

## NGINXとは何か

NGINXは「エンジンエックス」と読みます。Webサーバーと呼ばれるソフトウェアの一種で、インターネット上でWebサイトを公開するために使用されます。ApacheやIISなどと同じカテゴリのソフトウェアですが、特に高速で軽量な点が特徴です。

### NGINXができること

NGINXは主に以下の用途で使用されます。

**Webサーバーとして**
HTMLファイルや画像などの静的なファイルをブラウザに配信します。例えば、あなたが作成したHTMLファイルをインターネット上で公開する際に使用します。

**リバースプロキシとして**
クライアント（ブラウザ）からのリクエストを受け取り、バックエンドのアプリケーションサーバーに転送する中継役を担います。例えば、Node.jsやPythonで作成したアプリケーションの前段に配置して使用します。

**ロードバランサーとして**
複数のサーバーにリクエストを分散させることで、負荷を分散し、システム全体の可用性を高めます。

## インストール方法

### Ubuntu/Debianの場合

Ubuntuなどのディストリビューションでは、以下のコマンドでインストールできます。

```bash
# パッケージリストを更新
sudo apt update

# NGINXをインストール
sudo apt install nginx
```

`apt update`は最新のパッケージ情報を取得するコマンドです。これを実行しないと古いバージョンがインストールされる可能性があります。

### CentOS/RHELの場合

CentOSやRed Hat Enterprise Linuxでは、以下のコマンドを使用します。

```bash
# EPELリポジトリを追加（NGINXが含まれています）
sudo yum install epel-release

# NGINXをインストール
sudo yum install nginx
```

EPELは「Extra Packages for Enterprise Linux」の略で、追加のソフトウェアパッケージを提供するリポジトリです。

### インストールの確認

インストールが成功したか確認するには、以下のコマンドを実行します。

```bash
nginx -v
```

正常にインストールされていれば、`nginx version: nginx/1.18.0`のようなバージョン情報が表示されます。

### NGINXの起動

インストール後、NGINXを起動します。

```bash
# NGINXを起動
sudo systemctl start nginx

# システム起動時に自動起動するよう設定
sudo systemctl enable nginx

# 起動状態を確認
sudo systemctl status nginx
```

`systemctl`はLinuxのサービス管理コマンドです。`start`で起動、`enable`で自動起動の有効化、`status`で状態確認ができます。

起動後、ブラウザで`http://サーバーのIPアドレス`にアクセスすると、NGINXのデフォルトページが表示されるはずです。

## ディレクトリ構成の理解

NGINXをインストールすると、いくつかの重要なディレクトリとファイルが作成されます。それぞれの役割を理解することが設定の第一歩です。

### 主要なファイルとディレクトリ

**`/etc/nginx/nginx.conf`**
これがNGINXのメイン設定ファイルです。NGINXの全体的な動作を制御する基本設定が記述されています。通常、このファイルは編集することが少なく、個別のサイト設定は別ファイルで行います。

**`/etc/nginx/conf.d/`**
追加の設定ファイルを配置するディレクトリです。ここに`.conf`という拡張子のファイルを作成すると、自動的に読み込まれます。

**`/etc/nginx/sites-available/`（Debian/Ubuntu系のみ）**
利用可能なサイトの設定ファイルを保存するディレクトリです。ここに設定ファイルを作成しただけでは有効になりません。

**`/etc/nginx/sites-enabled/`（Debian/Ubuntu系のみ）**
実際に有効化されているサイトの設定へのシンボリックリンクが配置されます。`sites-available`の設定ファイルへのリンクを作成することで、その設定を有効化します。

**`/var/log/nginx/`**
NGINXのログファイルが保存されるディレクトリです。`access.log`にはアクセスログ、`error.log`にはエラーログが記録されます。

**`/usr/share/nginx/html/`または`/var/www/html/`**
デフォルトのWebコンテンツが配置されるディレクトリです。HTMLファイルや画像などをここに配置すると、ブラウザから見ることができます。

## 設定ファイルの基本構造

NGINXの設定ファイルは独特の構造を持っています。基本的な要素を理解しましょう。

### ディレクティブとは

ディレクティブは設定の指示を表す命令文です。2種類あります。

**シンプルディレクティブ**
1行で完結する設定で、セミコロン`;`で終わります。

```nginx
worker_processes 2;
```

この例では「ワーカープロセスを2つ起動する」という指示を出しています。

**ブロックディレクティブ**
中括弧`{}`で囲まれた複数の設定をまとめたものです。

```nginx
events {
    worker_connections 1024;
}
```

この例では`events`というブロックの中に、接続数の設定を記述しています。

### コンテキストの理解

NGINXの設定は階層構造になっており、この階層を「コンテキスト」と呼びます。

```nginx
# メインコンテキスト（最上位）
user nginx;
worker_processes auto;

events {
    # eventsコンテキスト
    worker_connections 1024;
}

http {
    # httpコンテキスト
    server {
        # serverコンテキスト
        listen 80;
        
        location / {
            # locationコンテキスト
            root /var/www/html;
        }
    }
}
```

各コンテキストには記述できるディレクティブが決まっています。例えば、`listen`ディレクティブは`server`コンテキスト内でのみ使用できます。

### コメントの書き方

`#`で始まる行はコメントとして扱われます。設定の説明を書くのに使用します。

```nginx
# これはコメントです
server_name example.com;  # 行末にもコメントを書けます
```

## メイン設定ファイル（nginx.conf）の詳細解説

`/etc/nginx/nginx.conf`ファイルを開くと、以下のような内容が記述されています。各部分を詳しく見ていきましょう。

```nginx
# NGINXを実行するユーザーを指定
user nginx;

# ワーカープロセスの数（autoでCPUコア数に自動設定）
worker_processes auto;

# エラーログの出力先とレベル
error_log /var/log/nginx/error.log;

# プロセスIDを記録するファイル
pid /run/nginx.pid;

# イベント処理の設定
events {
    # 1つのワーカープロセスが同時に処理できる接続数
    worker_connections 1024;
}

# HTTP関連の設定
http {
    # ログの形式を定義
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    # アクセスログの出力先と使用するフォーマット
    access_log /var/log/nginx/access.log main;

    # ファイル送信の効率化（通常はonのまま）
    sendfile on;
    
    # sendfileと組み合わせて使用（パケット最適化）
    tcp_nopush on;
    
    # 小さなパケットをすぐに送信（レスポンス速度向上）
    tcp_nodelay on;
    
    # クライアント接続を維持する時間（秒）
    keepalive_timeout 65;
    
    # MIMEタイプのハッシュテーブルサイズ
    types_hash_max_size 2048;

    # MIMEタイプの定義ファイルを読み込む
    include /etc/nginx/mime.types;
    
    # デフォルトのMIMEタイプ
    default_type application/octet-stream;

    # 追加の設定ファイルを読み込む
    include /etc/nginx/conf.d/*.conf;
}
```

### 各ディレクティブの詳しい説明

**`user nginx;`**
NGINXのワーカープロセスを実行するユーザーを指定します。セキュリティ上、root以外の専用ユーザーで実行することが推奨されます。

**`worker_processes auto;`**
NGINXが起動するワーカープロセスの数を指定します。`auto`を指定すると、CPUのコア数に合わせて自動的に設定されます。例えば、4コアのCPUなら4つのワーカープロセスが起動します。

**`worker_connections 1024;`**
1つのワーカープロセスが同時に処理できる接続数です。この設定では1024個の同時接続が可能です。ワーカープロセスが4つあれば、理論上は4096個の同時接続を処理できます。

**`sendfile on;`**
ファイルをブラウザに送信する際の効率化機能です。通常はオンのままで問題ありません。

**`keepalive_timeout 65;`**
クライアントとの接続を何秒間維持するかを指定します。接続を維持することで、複数のリクエストを効率的に処理できます。

**`include`**
他のファイルの内容を読み込みます。`/etc/nginx/conf.d/*.conf`と記述すると、そのディレクトリ内のすべての`.conf`ファイルが読み込まれます。

## 最初の簡単なWebサーバー設定

実際に静的なWebサイトを公開する設定を作成してみましょう。

### ステップ1: Webコンテンツの準備

まず、公開するHTMLファイルを作成します。

```bash
# ディレクトリを作成
sudo mkdir -p /var/www/mysite

# HTMLファイルを作成
sudo nano /var/www/mysite/index.html
```

`index.html`の内容：

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>私の最初のサイト</title>
</head>
<body>
    <h1>NGINXで公開しました！</h1>
    <p>これは私の最初のWebサイトです。</p>
</body>
</html>
```

### ステップ2: NGINX設定ファイルの作成

次に、このWebサイトを公開するための設定ファイルを作成します。

```bash
sudo nano /etc/nginx/conf.d/mysite.conf
```

設定ファイルの内容：

```nginx
# serverブロック：1つのWebサイトの設定を定義
server {
    # ポート80（HTTP）で待ち受ける
    listen 80;
    
    # このサーバーのドメイン名（localhostまたはIPアドレスでテスト可能）
    server_name localhost;
    
    # Webコンテンツが配置されているディレクトリ
    root /var/www/mysite;
    
    # デフォルトで表示するファイル名
    index index.html index.htm;
    
    # URLパス"/"（ルート）へのアクセス時の動作
    location / {
        # リクエストされたファイルを探して返す
        # 見つからない場合は404エラー
        try_files $uri $uri/ =404;
    }
}
```

### 各設定項目の詳細説明

**`listen 80;`**
NGINXが待ち受けるポート番号を指定します。80番ポートはHTTPの標準ポートです。ブラウザで`http://example.com`とアクセスした時、実際には`http://example.com:80`に接続しています（80番ポートは省略可能）。

**`server_name localhost;`**
このサーバーブロックが応答するドメイン名を指定します。`localhost`と設定した場合、ローカルマシンからのアクセスに応答します。実際のドメインを使う場合は、`server_name example.com www.example.com;`のように記述します。

**`root /var/www/mysite;`**
Webコンテンツが配置されているディレクトリのパスを指定します。ブラウザで`http://localhost/image.jpg`にアクセスすると、実際には`/var/www/mysite/image.jpg`が返されます。

**`index index.html index.htm;`**
ディレクトリにアクセスした時に自動的に表示するファイル名を指定します。左から順に探され、最初に見つかったファイルが表示されます。

**`try_files $uri $uri/ =404;`**
リクエストされたファイルの処理方法を指定します。
- `$uri`: まずリクエストされたファイルそのものを探します
- `$uri/`: ファイルが見つからなければ、ディレクトリとして探します
- `=404`: それでも見つからなければ404エラーを返します

### ステップ3: 設定のテストと適用

設定ファイルを作成したら、必ずテストしてからリロードします。

```bash
# 設定ファイルの文法チェック
sudo nginx -t
```

このコマンドで設定ファイルに間違いがないか確認します。正常であれば以下のように表示されます：

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

エラーが表示された場合は、メッセージをよく読んで設定を修正します。よくあるエラーは、セミコロン`;`の付け忘れや、中括弧`{}`の閉じ忘れです。

問題がなければ、設定を適用します：

```bash
# NGINXをリロード（再起動せずに設定を反映）
sudo systemctl reload nginx
```

`reload`は実行中の接続を維持したまま設定を反映します。`restart`は一度NGINXを停止してから起動するため、瞬間的にサービスが停止します。

### ステップ4: 動作確認

ブラウザで`http://localhost`または`http://サーバーのIPアドレス`にアクセスして、作成したHTMLファイルが表示されることを確認します。

## locationブロックの詳細解説

`location`ブロックは、URLのパスに応じて異なる処理を定義する重要な機能です。

### locationの基本的な使い方

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    # ルートパス（http://example.com/）へのアクセス
    location / {
        try_files $uri $uri/ =404;
    }
}
```

この設定では、すべてのリクエストが`location /`ブロックで処理されます。

### locationのマッチングパターン

locationには複数のマッチング方法があり、それぞれ優先順位が異なります。

#### 1. 完全一致（最優先）

```nginx
# http://example.com/about と完全に一致する場合のみマッチ
location = /about {
    return 200 "About page";
    add_header Content-Type text/plain;
}
```

`=`を使うと、指定したパスと完全に一致する場合のみマッチします。`/about/`や`/about.html`にはマッチしません。

#### 2. 優先的な前方一致

```nginx
# /images/で始まるすべてのリクエストにマッチ
# 正規表現よりも優先される
location ^~ /images/ {
    root /var/www;
    expires 30d;
}
```

`^~`を使うと、指定したパスで始まるすべてのリクエストにマッチし、正規表現のチェックをスキップします。パフォーマンス向上に有効です。

#### 3. 正規表現マッチ（大文字小文字を区別）

```nginx
# .phpで終わるすべてのリクエストにマッチ
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm.sock;
    include fastcgi_params;
}
```

`~`を使うと、正規表現でマッチングを行います。`\.php$`は「.phpで終わる」という意味です。

#### 4. 正規表現マッチ（大文字小文字を区別しない）

```nginx
# .jpg、.JPG、.Jpg などすべてにマッチ
location ~* \.(jpg|jpeg|png|gif)$ {
    expires 30d;
    add_header Cache-Control "public";
}
```

`~*`を使うと、大文字小文字を区別せずに正規表現マッチングを行います。

#### 5. 前方一致（最も優先順位が低い）

```nginx
# /downloadsで始まるすべてのリクエストにマッチ
location /downloads {
    root /var/www;
}
```

何もつけない場合、指定したパスで始まるリクエストにマッチします。

### マッチングの優先順位

NGINXは以下の順序でlocationを評価します：

1. 完全一致 `= /path`
2. 優先的な前方一致 `^~ /path`
3. 正規表現マッチ `~` または `~*`（記述順に評価）
4. 前方一致 `/path`（最長一致を使用）

### 実践的なlocation設定例

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    # ルートページ
    location = / {
        index index.html;
    }
    
    # 静的ファイル（画像）の配信
    location ^~ /images/ {
        # /var/www/html/images/にアクセス
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # PHPファイルの処理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # 画像ファイルのキャッシュ設定（拡張子不問）
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 30d;
        log_not_found off;
    }
    
    # 隠しファイル（.htaccessなど）へのアクセスを拒否
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # その他すべてのリクエスト
    location / {
        try_files $uri $uri/ =404;
    }
}
```

## リバースプロキシの設定（初心者向け詳細解説）

リバースプロキシは、NGINXの非常に重要な機能の一つです。これにより、バックエンドで動作しているアプリケーション（Node.js、Python、Javaなど）をNGINX経由で公開できます。

### リバースプロキシとは

通常、ブラウザは直接アプリケーションサーバーに接続します：

```
ブラウザ → アプリケーションサーバー（例：Node.js）
```

しかし、リバースプロキシを使うと：

```
ブラウザ → NGINX → アプリケーションサーバー
```

という構成になります。NGINXが中継役となり、以下のメリットがあります：

- SSL/TLS（HTTPS）の処理をNGINXに任せられる
- 静的ファイルはNGINXが直接配信し、動的な処理のみアプリケーションに転送できる
- 複数のバックエンドサーバーに負荷を分散できる
- セキュリティの強化（アプリケーションサーバーを直接インターネットに公開しない）

### 基本的なリバースプロキシ設定

例えば、ポート3000で動作しているNode.jsアプリケーションを公開する場合：

```nginx
server {
    listen 80;
    server_name app.example.com;
    
    location / {
        # バックエンドサーバーのアドレスを指定
        proxy_pass http://localhost:3000;
        
        # HTTPバージョンを1.1に設定（WebSocket対応に必要）
        proxy_http_version 1.1;
        
        # WebSocketのためのアップグレードヘッダー
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        
        # オリジナルのHostヘッダーを保持
        proxy_set_header Host $host;
        
        # クライアントの実際のIPアドレスを渡す
        proxy_set_header X-Real-IP $remote_addr;
        
        # プロキシチェーン全体のIPアドレスを渡す
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # オリジナルのプロトコル（httpまたはhttps）を渡す
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # キャッシュをバイパス
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 各ディレクティブの詳細説明

**`proxy_pass http://localhost:3000;`**
リクエストを転送する先のアドレスとポートを指定します。`localhost:3000`は同じサーバーのポート3000で動作しているアプリケーションを意味します。別のサーバーの場合は`http://192.168.1.100:3000`のようにIPアドレスを指定します。

**`proxy_http_version 1.1;`**
HTTP/1.1プロトコルを使用するよう指定します。WebSocketを使用する場合に必要です。

**`proxy_set_header Host $host;`**
バックエンドに送信する`Host`ヘッダーを設定します。`$host`は元のリクエストのホスト名です。これにより、バックエンドアプリケーションは元のドメイン名を知ることができます。

**`proxy_set_header X-Real-IP $remote_addr;`**
クライアントの実際のIPアドレスをバックエンドに伝えます。NGINXを経由すると、バックエンドからは「NGINXのIPアドレス」が見えてしまうため、この設定で元のクライアントIPを伝達します。

**`proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`**
プロキシを経由した全てのIPアドレスのリストを保持します。複数のプロキシを経由する場合に、元のクライアントを追跡できます。

**`proxy_set_header X-Forwarded-Proto $scheme;`**
元のリクエストがHTTPだったかHTTPSだったかをバックエンドに伝えます。これにより、バックエンドアプリケーションは正しいリダイレクトURLを生成できます。

### 静的ファイルと動的処理の分離

リバースプロキシの大きな利点は、静的ファイルはNGINXが直接配信し、動的な処理のみバックエンドに転送できることです。

```nginx
server {
    listen 80;
    server_name app.example.com;
    
    # 静的ファイル（CSS、JavaScript、画像）はNGINXが直接配信
    location /static/ {
        # 実際のファイルの場所
        alias /var/www/app/static/;
        
        # キャッシュの有効期限を設定（1年）
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 画像ファイルもNGINXが直接配信
    location ~* \.(jpg|jpeg|png|gif|svg|ico)$ {
        root /var/www/app/public;
        expires 30d;
    }
    
    # その他のリクエストはバックエンドに転送
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

この設定により、画像やCSSファイルはNGINXが高速に配信し、API呼び出しなどの動的な処理のみNode.jsアプリケーションが処理します。

### タイムアウト設定

バックエンドアプリケーションの処理に時間がかかる場合、タイムアウトを調整する必要があります。

```nginx
location /api/ {
    proxy_pass http://localhost:3000;
    
    # バックエンドへの接続タイムアウト（デフォルト60秒）
    proxy_connect_timeout 90s;
    
    # バックエンドからの応答待ちタイムアウト（デフォルト60秒）
    proxy_read_timeout 90s;
    
    # バックエンドへのデータ送信タイムアウト（デフォルト60秒）
    proxy_send_timeout 90s;
}
```

例えば、データ処理に時間がかかるAPIエンドポイントがある場合、`proxy_read_timeout`を長めに設定します。

## 複数サイトの管理

1台のサーバーで複数のWebサイトを運用する方法を解説します。

### sites-availableとsites-enabledの仕組み（Debian/Ubuntu）

Debian系のLinuxでは、サイト管理を効率的に行うための仕組みがあります。

```
/etc/nginx/sites-available/  ← 設定ファイルを保管
/etc/nginx/sites-enabled/    ← 有効な設定へのリンク
```

- `sites-available`：すべてのサイト設定ファイルを保管します（有効・無効問わず）
- `sites-enabled`：実際に有効化したいサイトの設定ファイルへのシンボリックリンクを配置します

この仕組みにより、設定ファイルを削除せずに一時的に無効化したり、簡単に有効化したりできます。

### サイト1の設定

`/etc/nginx/sites-available/site1.conf`を作成します：

```nginx
server {
    listen 80;
    # このサイトのドメイン名
    server_name site1.example.com;
    
    # このサイトのコンテンツが配置されているディレクトリ
    root /var/www/site1;
    index index.html;
    
    # アクセスログとエラーログをサイト専用に分ける
    access_log /var/log/nginx/site1-access.log;
    error_log /var/log/nginx/site1-error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### サイト2の設定

`/etc/nginx/sites-available/site2.conf`を作成します：

```nginx
server {
    listen 80;
    # 別のドメイン名
    server_name site2.example.com;
    
    # 別のコンテンツディレクトリ
    root /var/www/site2;
    index index.html;
    
    # サイト2専用のログファイル
    access_log /var/log/nginx/site2-access.log;
    error_log /var/log/nginx/site2-error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### サイト設定の有効化

設定ファイルを作成しただけでは有効になりません。シンボリックリンクを作成して有効化します。

```bash
# site1を有効化
sudo ln -s /etc/nginx/sites-available/site1.conf /etc/nginx/sites-enabled/

# site2を有効化
sudo ln -s /etc/nginx/sites-available/site2.conf /etc/nginx/sites-enabled/

# 設定ファイルをテスト
sudo nginx -t

# 設定を適用
sudo systemctl reload nginx
```

`ln -s`コマンドは「リンク元」「リンク先」の順で指定します。

### サイトの無効化

サイトを一時的に無効にしたい場合は、シンボリックリンクを削除します。

```bash
# site2を無効化
sudo rm /etc/nginx/sites-enabled/site2.conf

# 設定を再読み込み
sudo systemctl reload nginx
```

元の設定ファイル（`sites-available`内）は残っているので、再度有効化することも簡単です。

### CentOS/RHEL系での複数サイト管理

CentOS系では`sites-available`と`sites-enabled`の仕組みがデフォルトでは用意されていません。代わりに`/etc/nginx/conf.d/`ディレクトリに直接設定ファイルを配置します。

```bash
# サイト設定を作成
sudo nano /etc/nginx/conf.d/site1.conf
sudo nano /etc/nginx/conf.d/site2.conf

# 設定を適用
sudo nginx -t
sudo systemctl reload nginx
```

一時的に無効化したい場合は、拡張子を`.conf`以外に変更します。

```bash
# 無効化（.confでなくなるため読み込まれない）
sudo mv /etc/nginx/conf.d/site2.conf /etc/nginx/conf.d/site2.conf.disabled

# 有効化
sudo mv /etc/nginx/conf.d/site2.conf.disabled /etc/nginx/conf.d/site2.conf
```

### 同じポートで複数サイトを運用する仕組み

なぜ同じポート80で複数のサイトを運用できるのでしょうか？これはNGINXが`server_name`ディレクティブを使ってリクエストを振り分けるからです。

ブラウザがリクエストを送信する際、`Host`ヘッダーにドメイン名が含まれています：

```
GET / HTTP/1.1
Host: site1.example.com
```

NGINXはこの`Host`ヘッダーを見て、どの`server`ブロックで処理するか判断します。

```nginx
# site1.example.comへのリクエストはこちら
server {
    server_name site1.example.com;
    root /var/www/site1;
}

# site2.example.comへのリクエストはこちら
server {
    server_name site2.example.com;
    root /var/www/site2;
}
```

### デフォルトサーバーの設定

どの`server_name`にもマッチしないリクエスト（IPアドレス直接アクセスなど）を処理するデフォルトサーバーを設定できます。

```nginx
server {
    listen 80 default_server;
    server_name _;
    
    # 404ページを返す
    return 404;
}
```

`default_server`パラメータをつけた`server`ブロックが、マッチしないリクエストを処理します。`server_name _;`はワイルドカードで、任意のホスト名にマッチします。

## SSL/TLS（HTTPS）の設定

HTTPSは暗号化通信を提供し、セキュリティを大幅に向上させます。現代のWebサイトでは必須の設定です。

### SSL/TLSとは

HTTPは通信内容が暗号化されていないため、第三者に傍受される可能性があります。HTTPS（HTTPSのSはSecureの意味）は、SSL/TLSという暗号化技術を使って通信を保護します。

HTTPSを使用するには、SSL証明書が必要です。証明書は以下の役割を果たします：

1. サイトの身元を証明する
2. 通信を暗号化するための鍵を提供する

### SSL証明書の入手方法

**Let's Encryptを使用する（推奨・無料）**

Let's Encryptは無料でSSL証明書を発行してくれるサービスです。Certbotというツールを使うと簡単に設定できます。

```bash
# Certbotのインストール（Ubuntu/Debian）
sudo apt install certbot python3-certbot-nginx

# Certbotのインストール（CentOS/RHEL）
sudo yum install certbot python3-certbot-nginx
```

証明書の取得と自動設定：

```bash
# ドメインを指定して証明書を取得し、NGINXを自動設定
sudo certbot --nginx -d example.com -d www.example.com
```

このコマンドを実行すると、対話形式で以下の操作が自動的に行われます：

1. ドメインの所有権確認
2. SSL証明書の取得
3. NGINX設定ファイルの自動更新
4. HTTPからHTTPSへのリダイレクト設定

証明書は90日間有効で、Certbotが自動更新のタイマーも設定してくれます。

### 手動でのHTTPS設定

証明書を手動で取得した場合や、より細かい制御が必要な場合は、以下のように設定します。

```nginx
# HTTPSサーバー（ポート443）
server {
    # ポート443（HTTPS）で待ち受け、HTTP/2を有効化
    listen 443 ssl http2;
    listen [::]:443 ssl http2;  # IPv6対応
    
    server_name example.com www.example.com;
    
    # SSL証明書のパス
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # 使用するSSL/TLSプロトコルバージョン
    # TLS 1.2以上を使用（古いバージョンは脆弱性があるため無効化）
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 使用する暗号化方式
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    
    # サーバー側の暗号化方式を優先
    ssl_prefer_server_ciphers on;
    
    # SSL接続の再利用を有効化（パフォーマンス向上）
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

# HTTPサーバー（ポート80）- HTTPSへリダイレクト
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # すべてのHTTPリクエストをHTTPSにリダイレクト
    return 301 https://$server_name$request_uri;
}
```

### SSL設定の詳細説明

**`listen 443 ssl http2;`**
- `443`：HTTPSの標準ポート
- `ssl`：このポートでSSL/TLSを有効化
- `http2`：HTTP/2プロトコルを有効化（高速化）

**`ssl_certificate`と`ssl_certificate_key`**
証明書ファイルと秘密鍵ファイルのパスを指定します。これらのファイルは外部から読み取れないよう、適切なパーミッションを設定する必要があります：

```bash
sudo chmod 600 /etc/nginx/ssl/example.com.key
sudo chmod 644 /etc/nginx/ssl/example.com.crt
```

**`ssl_protocols TLSv1.2 TLSv1.3;`**
使用を許可するTLSバージョンを指定します。TLS 1.0とTLS 1.1は脆弱性が発見されているため使用しません。

**`ssl_session_cache`**
SSL接続の情報をキャッシュして、再接続時の処理を高速化します。`shared:SSL:10m`は「10MBの共有キャッシュ」を意味します。

**`return 301 https://$server_name$request_uri;`**
HTTPでアクセスされた場合、HTTPSにリダイレクトします。
- `301`：恒久的なリダイレクト（検索エンジンにもHTTPS版が正しいURLと伝わる）
- `$server_name`：現在のサーバー名
- `$request_uri`：リクエストされたパス（`/page.html?param=value`など）

### SSL証明書の自動更新

Let's Encryptの証明書は90日で期限切れになりますが、Certbotが自動更新してくれます。

```bash
# 自動更新のテスト
sudo certbot renew --dry-run

# 自動更新タイマーの確認（Systemdを使用している場合）
sudo systemctl status certbot.timer
```

自動更新が正しく動作しているか、定期的に確認することをお勧めします。

### HSTSの設定（上級者向け）

HSTS（HTTP Strict Transport Security）は、ブラウザに「このサイトは常にHTTPSでアクセスすること」を伝えるセキュリティ機能です。

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # HSTSヘッダーを追加（1年間有効）
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # その他の設定...
}
```

注意：HSTSを有効にすると、指定した期間中はHTTPでアクセスできなくなります。証明書が期限切れになった場合などにサイトにアクセスできなくなる可能性があるため、慎重に設定してください。

## アクセス制御

特定のユーザーやIPアドレスからのアクセスのみを許可する方法を解説します。

### IPアドレスによるアクセス制限

特定のIPアドレスまたはIPアドレス範囲からのアクセスのみを許可できます。

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 管理画面へのアクセスを制限
    location /admin {
        # 192.168.1.0/24のネットワークからのアクセスを許可
        allow 192.168.1.0/24;
        
        # 特定のIPアドレスを許可
        allow 10.0.0.1;
        
        # それ以外はすべて拒否
        deny all;
        
        root /var/www/html;
        index index.html;
    }
}
```

**設定の説明**

- `allow 192.168.1.0/24`：192.168.1.0から192.168.1.255までのIPアドレスを許可
- `allow 10.0.0.1`：特定の1つのIPアドレスを許可
- `deny all`：それ以外のすべてを拒否

NGINXは上から順番に評価し、最初にマッチしたルールを適用します。そのため、`deny all`は必ず最後に記述します。

### CIDR表記の理解

`192.168.1.0/24`のような表記をCIDR表記と呼びます。

- `/24`：最初の24ビット（3オクテット）が固定、最後の8ビット（1オクテット）が可変
  - 範囲：192.168.1.0 ～ 192.168.1.255（256個のアドレス）
- `/32`：すべてのビットが固定
  - 範囲：指定した1つのIPアドレスのみ
- `/16`：最初の16ビット（2オクテット）が固定
  - 範囲：192.168.0.0 ～ 192.168.255.255（65,536個のアドレス）

### Basic認証（ベーシック認証）

ユーザー名とパスワードでアクセスを制限する方法です。

**ステップ1: パスワードファイルの作成**

まず、`htpasswd`コマンドをインストールします。

```bash
# Ubuntu/Debian
sudo apt install apache2-utils

# CentOS/RHEL
sudo yum install httpd-tools
```

パスワードファイルを作成します：

```bash
# 新規作成（-cオプション）
sudo htpasswd -c /etc/nginx/.htpasswd admin

# 2人目以降のユーザー追加（-cオプションなし）
sudo htpasswd /etc/nginx/.htpasswd user2
```

パスワードの入力を求められるので、入力します。

**ステップ2: NGINX設定**

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 特定のディレクトリに認証を設定
    location /private {
        # 認証が必要であることを示すメッセージ
        auth_basic "Restricted Area";
        
        # パスワードファイルのパス
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        root /var/www/html;
        index index.html;
    }
    
    # その他の場所は認証不要
    location / {
        root /var/www/html;
        index index.html;
    }
}
```

これで`http://example.com/private/`にアクセスすると、ユーザー名とパスワードの入力を求められます。

### IPアドレス制限とBasic認証の組み合わせ

より強固なセキュリティのため、両方を組み合わせることもできます。

```nginx
location /admin {
    # IPアドレス制限
    allow 192.168.1.0/24;
    deny all;
    
    # Basic認証
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    root /var/www/html;
}
```

この設定では、許可されたIPアドレスからのアクセスであり、かつ正しいユーザー名とパスワードを入力した場合のみアクセスが許可されます。

### satisfy ディレクティブ

`satisfy`ディレクティブを使うと、「IPアドレス制限またはBasic認証のいずれか」を満たせばアクセスを許可する設定ができます。

```nginx
location /admin {
    satisfy any;  # anyまたはallを指定
    
    allow 192.168.1.0/24;
    deny all;
    
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

- `satisfy any`：IPアドレス制限またはBasic認証のいずれかを満たせばOK
- `satisfy all`：両方を満たす必要がある（デフォルト）

## ログの設定と活用

ログはトラブルシューティングやアクセス解析に不可欠です。

### ログの種類

NGINXには2種類のログがあります。

**アクセスログ（access.log）**
すべてのリクエストが記録されます。どのファイルにアクセスされたか、どのIPアドレスからアクセスされたかなどが記録されます。

デフォルトの場所：`/var/log/nginx/access.log`

**エラーログ（error.log）**
エラーや警告が記録されます。設定ミス、ファイルが見つからない、アップストリームサーバーへの接続失敗などが記録されます。

デフォルトの場所：`/var/log/nginx/error.log`

### ログの閲覧方法

```bash
# アクセスログの最新10行を表示
sudo tail /var/log/nginx/access.log

# エラーログをリアルタイムで監視
sudo tail -f /var/log/nginx/error.log

# アクセスログから特定のIPアドレスを検索
sudo grep "192.168.1.100" /var/log/nginx/access.log

# エラーログから404エラーを検索
sudo grep "404" /var/log/nginx/error.log
```

### アクセスログのフォーマットカスタマイズ

デフォルトのログフォーマットに加えて、独自のフォーマットを定義できます。

```nginx
http {
    # カスタムログフォーマットを定義
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    # このフォーマットを使用してログを記録
    access_log /var/log/nginx/access.log detailed;
}
```

**変数の説明**

- `$remote_addr`：クライアントのIPアドレス
- `$remote_user`：Basic認証のユーザー名
- `$time_local`：アクセス日時
- `$request`：リクエスト内容（`GET /index.html HTTP/1.1`など）
- `$status`：HTTPステータスコード（200、404など）
- `$body_bytes_sent`：送信したバイト数
- `$http_referer`：参照元URL
- `$http_user_agent`：ブラウザやクライアントの情報
- `$request_time`：リクエスト処理にかかった時間（秒）
- `$upstream_response_time`：バックエンドからのレスポンス時間

### サイトごとに異なるログファイルを使用

複数のサイトを運用している場合、サイトごとにログを分けると管理が楽になります。

```nginx
server {
    listen 80;
    server_name site1.example.com;
    
    # site1専用のログ
    access_log /var/log/nginx/site1-access.log;
    error_log /var/log/nginx/site1-error.log;
    
    location / {
        root /var/www/site1;
    }
}

server {
    listen 80;
    server_name site2.example.com;
    
    # site2専用のログ
    access_log /var/log/nginx/site2-access.log;
    error_log /var/log/nginx/site2-error.log;
    
    location / {
        root /var/www/site2;
    }
}
```

### 特定のlocationでログを無効化

ヘルスチェックや静的ファイルなど、ログに記録する必要がないリクエストのログを無効化できます。

```nginx
server {
    listen 80;
    server_name example.com;
    
    # ヘルスチェックのログは不要
    location /health-check {
        access_log off;
        return 200 "OK";
    }
    
    # faviconのアクセスログも不要
    location = /favicon.ico {
        access_log off;
        log_not_found off;  # 見つからない場合もエラーログに記録しない
    }
    
    # その他は通常通りログを記録
    location / {
        root /var/www/html;
    }
}
```

### エラーログのレベル設定

エラーログには詳細度のレベルがあります。

```nginx
# グローバル設定
error_log /var/log/nginx/error.log warn;

server {
    listen 80;
    server_name example.com;
    
    # このサーバーブロックだけデバッグレベルで記録
    error_log /var/log/nginx/example-debug.log debug;
}
```

**ログレベル（詳細度の低い順）**

1. `emerg`：緊急事態（システムが使用不能）
2. `alert`：早急な対応が必要
3. `crit`：重大な状況
4. `error`：エラー（デフォルト）
5. `warn`：警告
6. `notice`：通知（正常だが重要な情報）
7. `info`：情報
8. `debug`：デバッグ情報（非常に詳細）

通常は`error`または`warn`レベルで十分です。`debug`レベルはトラブルシューティング時のみ使用し、大量のログが生成されるため常用は避けましょう。

### ログのローテーション

ログファイルは放置すると肥大化してディスク容量を圧迫します。多くのLinuxシステムでは`logrotate`が自動的にログをローテーション（古いログをアーカイブ）してくれます。

設定ファイル：`/etc/logrotate.d/nginx`

```
/var/log/nginx/*.log {
    daily          # 毎日ローテーション
    missingok      # ログファイルがなくてもエラーにしない
    rotate 14      # 14日分保持
    compress       # 古いログを圧縮
    delaycompress  # 最新のローテーション分は圧縮しない
    notifempty     # ログが空なら何もしない
    create 0640 nginx adm  # 新しいログファイルの権限
    sharedscripts  # すべてのログで1回だけスクリプト実行
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

手動でローテーションをテストする場合：

```bash
sudo logrotate -f /etc/logrotate.d/nginx
```

## リダイレクト設定

URLの変更やサイトの移転時にリダイレクトを設定します。

### 基本的なリダイレクト

**returnディレクティブを使用**

```nginx
server {
    listen 80;
    server_name old-domain.com;
    
    # すべてのリクエストを新ドメインにリダイレクト
    return 301 https://new-domain.com$request_uri;
}
```

`$request_uri`は元のパスとクエリパラメータを保持します。例えば、`http://old-domain.com/page?id=1`は`https://new-domain.com/page?id=1`にリダイレクトされます。

### HTTPからHTTPSへのリダイレクト

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    # HTTPSにリダイレクト
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    root /var/www/html;
}
```

`$host`は`Host`ヘッダーの値（`example.com`または`www.example.com`）を保持します。

### wwwあり・なしの統一

```nginx
# wwwなしに統一する場合
server {
    listen 80;
    listen 443 ssl http2;
    server_name www.example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # wwwなしにリダイレクト
    return 301 $scheme://example.com$request_uri;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # 実際のコンテンツ
    root /var/www/html;
}
```

`$scheme`は`http`または`https`に自動的に置き換わります。

### 特定のページのリダイレクト

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 特定のページをリダイレクト
    location = /old-page.html {
        return 301 /new-page.html;
    }
    
    # ディレクトリ全体をリダイレクト
    location /old-section/ {
        return 301 /new-section/;
    }
    
    location / {
        root /var/www/html;
    }
}
```

### rewriteディレクティブを使用

より複雑なパターンマッチングが必要な場合は`rewrite`を使用します。

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /products/123 を /items/123 にリダイレクト
    rewrite ^/products/(.*)$ /items/$1 permanent;
    
    # /blog/2024/01/article を /blog/article にリダイレクト（日付を削除）
    rewrite ^/blog/[0-9]{4}/[0-9]{2}/(.*)$ /blog/$1 permanent;
    
    location / {
        root /var/www/html;
    }
}
```

**rewriteの構文**

```nginx
rewrite 正規表現パターン 置換後のURL [フラグ];
```

**主なフラグ**

- `permanent`：301リダイレクト（恒久的）
- `redirect`：302リダイレクト（一時的）
- `break`：リダイレクトせずにURLを内部的に書き換え
- `last`：他のrewriteルールも評価

### リダイレクトループの回避

設定ミスでリダイレクトループが発生することがあります。

```nginx
# 悪い例：無限ループになる
server {
    listen 80;
    server_name example.com;
    
    location / {
        return 301 http://example.com/;  # 同じURLにリダイレクト！
    }
}

# 良い例：条件を正しく設定
server {
    listen 80;
    server_name www.example.com;
    return 301 $scheme://example.com$request_uri;
}

server {
    listen 80;
    server_name example.com;  # 別のserver_name
    root /var/www/html;
}
```

## 静的ファイルの最適化

Webサイトの読み込み速度を向上させるための設定です。

### ブラウザキャッシュの設定

ブラウザに「このファイルは○○日間キャッシュしていい」と伝えることで、2回目以降のアクセスが高速になります。

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    # 画像ファイル：1年間キャッシュ
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # CSS・JavaScriptファイル：1ヶ月間キャッシュ
    location ~* \.(css|js)$ {
        expires 1M;
        add_header Cache-Control "public";
    }
    
    # フォントファイル：1年間キャッシュ
    location ~* \.(woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public";
        
        # CORSヘッダー（他のドメインからの読み込みを許可）
        add_header Access-Control-Allow-Origin *;
    }
    
    # HTMLファイル：キャッシュしない（常に最新版を取得）
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate";
    }
}
```

**expiresディレクティブの説明**

- `1y`：1年間
- `1M`：1ヶ月間
- `30d`：30日間
- `24h`：24時間
- `-1`：キャッシュしない

**Cache-Controlヘッダーの説明**

- `public`：プロキシサーバーなどもキャッシュ可能
- `private`：ブラウザのみキャッシュ可能
- `immutable`：ファイルが変更されないことを示す（更なる最適化）
- `no-store`：キャッシュしない
- `must-revalidate`：期限切れ時に必ずサーバーに確認

### Gzip圧縮の設定

テキストファイル（HTML、CSS、JavaScriptなど）を圧縮して転送することで、データ量を大幅に削減できます。

```nginx
http {
    # Gzip圧縮を有効化
    gzip on;
    
    # プロキシ経由のリクエストでも圧縮
    gzip_proxied any;
    
    # 圧縮するファイルの最小サイズ（バイト）
    # 小さすぎるファイルは圧縮しない方が効率的
    gzip_min_length 1000;
    
    # 圧縮レベル（1-9、数字が大きいほど圧縮率が高いがCPU負荷も高い）
    gzip_comp_level 6;
    
    # 圧縮の効果を示すヘッダーを追加
    gzip_vary on;
    
    # 圧縮するファイルタイプ
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/x-javascript
        image/svg+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject;
    
    # 古いIE6では圧縮を無効化（互換性のため）
    gzip_disable "msie6";
}
```

**圧縮レベルの選び方**

- レベル1-3：低圧縮率だが高速（CPU負荷が低い）
- レベル4-6：バランスが良い（推奨）
- レベル7-9：高圧縮率だが遅い（CPU負荷が高い）

通常はレベル6で十分です。レベル9にしても圧縮率はそれほど向上せず、CPU負荷だけが増加します。

### 静的ファイルの配信最適化

```nginx
http {
    # sendfileを有効化（カーネルレベルでの効率的なファイル転送）
    sendfile on;
    
    # tcp_nopushを有効化（パケットをまとめて送信）
    tcp_nopush on;
    
    # tcp_nodelayを有効化（小さなパケットをすぐに送信）
    tcp_nodelay on;
}

server {
    listen 80;
    server_name example.com;
    
    # 静的ファイル用のディレクトリ
    location /static/ {
        root /var/www;
        
        # ファイルが見つからない場合のログを無効化
        log_not_found off;
        
        # アクセスログも無効化（静的ファイルは記録不要なら）
        access_log off;
        
        # キャッシュ設定
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### ETagの設定

ETagはファイルのバージョンを識別するための値です。ファイルが変更されていない場合、サーバーは304（Not Modified）を返し、データ転送をスキップできます。

```nginx
server {
    listen 80;
    server_name example.com;
    
    # ETagを有効化（デフォルトでオン）
    etag on;
    
    # If-Modified-Sinceヘッダーの処理を有効化
    if_modified_since before;
    
    location / {
        root /var/www/html;
    }
}
```

### Open File Cacheの設定

頻繁にアクセスされるファイルのメタデータをキャッシュして、ディスクアクセスを減らします。

```nginx
http {
    # ファイル情報のキャッシュ設定
    open_file_cache max=10000 inactive=30s;
    
    # キャッシュの有効性を確認する間隔
    open_file_cache_valid 60s;
    
    # 最低このアクセス数がある場合のみキャッシュ
    open_file_cache_min_uses 2;
    
    # ファイルが見つからない場合もキャッシュ
    open_file_cache_errors on;
}
```

**パラメータの説明**

- `max=10000`：最大10,000個のファイル情報をキャッシュ
- `inactive=30s`：30秒間アクセスされないキャッシュは削除
- `open_file_cache_valid 60s`：60秒ごとにキャッシュの有効性を再チェック
- `open_file_cache_min_uses 2`：2回以上アクセスされたファイルのみキャッシュ

## エラーハンドリング

エラーが発生した時の動作をカスタマイズします。

### カスタムエラーページの設定

デフォルトのエラーページではなく、独自のデザインのエラーページを表示できます。

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    # 404エラー時の処理
    error_page 404 /404.html;
    location = /404.html {
        # エラーページ専用のディレクトリ
        root /var/www/errors;
        
        # internalディレクティブ：直接アクセスを禁止
        # /404.htmlには内部リダイレクト経由でのみアクセス可能
        internal;
    }
    
    # 50xエラー時の処理（サーバーエラー）
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
    
    # 403エラー時の処理（アクセス拒否）
    error_page 403 /403.html;
    location = /403.html {
        root /var/www/errors;
        internal;
    }
}
```

**エラーページの作成例**

`/var/www/errors/404.html`を作成：

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>ページが見つかりません</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
        }
        h1 { color: #e74c3c; }
    </style>
</head>
<body>
    <h1>404 - ページが見つかりません</h1>
    <p>お探しのページは存在しないか、移動した可能性があります。</p>
    <a href="/">トップページに戻る</a>
</body>
</html>
```

ディレクトリの作成と権限設定：

```bash
# エラーページ用ディレクトリの作成
sudo mkdir -p /var/www/errors

# HTMLファイルを作成
sudo nano /var/www/errors/404.html
sudo nano /var/www/errors/50x.html
sudo nano /var/www/errors/403.html

# 権限設定
sudo chown -R www-data:www-data /var/www/errors
sudo chmod 755 /var/www/errors
sudo chmod 644 /var/www/errors/*.html
```

### 主なHTTPステータスコード

- **2xx（成功）**
  - `200 OK`：正常に処理された
  
- **3xx（リダイレクト）**
  - `301 Moved Permanently`：恒久的な移転
  - `302 Found`：一時的な移転
  - `304 Not Modified`：キャッシュが有効
  
- **4xx（クライアントエラー）**
  - `400 Bad Request`：不正なリクエスト
  - `401 Unauthorized`：認証が必要
  - `403 Forbidden`：アクセス拒否
  - `404 Not Found`：ページが見つからない
  - `429 Too Many Requests`：リクエスト数超過
  
- **5xx（サーバーエラー）**
  - `500 Internal Server Error`：サーバー内部エラー
  - `502 Bad Gateway`：ゲートウェイエラー（バックエンドからの応答が不正）
  - `503 Service Unavailable`：サービス利用不可（メンテナンス中など）
  - `504 Gateway Timeout`：ゲートウェイタイムアウト

### エラー時のステータスコードを変更

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 404エラーを200として返す（SEO対策で使われることも）
    error_page 404 =200 /404.html;
    location = /404.html {
        root /var/www/errors;
        internal;
    }
}
```

ただし、通常は元のステータスコードを保持することが推奨されます。検索エンジンが正しくエラーを認識できなくなるためです。

### バックエンドエラーの処理

リバースプロキシとして使用している場合、バックエンドサーバーのエラーをカスタマイズできます。

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        
        # バックエンドがエラーを返した場合、NGINXのエラーページを表示
        proxy_intercept_errors on;
    }
    
    # バックエンドが502エラーを返した場合
    error_page 502 /502.html;
    location = /502.html {
        root /var/www/errors;
        internal;
    }
}
```

`proxy_intercept_errors on`により、バックエンドから返されたエラーページではなく、NGINXで定義したエラーページが表示されます。

## ロードバランシング（負荷分散）

複数のバックエンドサーバーにリクエストを分散させる設定です。

### ロードバランシングとは

1台のサーバーでは処理しきれないほどのアクセスがある場合、複数のサーバーでリクエストを分散処理します。

```
           NGINX（ロードバランサー）
              /      |      \
             /       |       \
       サーバー1  サーバー2  サーバー3
```

NGINXが自動的にリクエストを振り分けます。

### 基本的なロードバランシング設定

```nginx
# アップストリーム（バックエンドサーバー群）の定義
upstream backend {
    # バックエンドサーバーのリスト
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

server {
    listen 80;
    server_name example.com;
    
    location / {
        # 定義したアップストリームに転送
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

この設定により、リクエストは3台のサーバーに順番に振り分けられます（ラウンドロビン方式）。

### 負荷分散方式

#### 1. ラウンドロビン（デフォルト）

リクエストを順番に割り振ります。

```nginx
upstream backend {
    server server1.example.com;
    server server2.example.com;
    server server3.example.com;
}
```

リクエストの流れ：
- 1番目のリクエスト → server1
- 2番目のリクエスト → server2
- 3番目のリクエスト → server3
- 4番目のリクエスト → server1（最初に戻る）

#### 2. 重み付けラウンドロビン

サーバーのスペックに応じて割り振る比率を変更できます。

```nginx
upstream backend {
    # server1は3回、server2は2回、server3は1回の割合で振り分け
    server server1.example.com weight=3;
    server server2.example.com weight=2;
    server server3.example.com weight=1;
}
```

server1が最も性能が高い場合に、より多くのリクエストを処理させることができます。

#### 3. 最小接続数（least_conn）

現在の接続数が最も少ないサーバーに振り分けます。

```nginx
upstream backend {
    least_conn;
    server server1.example.com;
    server server2.example.com;
    server server3.example.com;
}
```

処理時間がバラバラなリクエストが混在する場合に効果的です。

#### 4. IPハッシュ（ip_hash）

クライアントのIPアドレスに基づいて、同じクライアントは常に同じサーバーに接続します。

```nginx
upstream backend {
    ip_hash;
    server server1.example.com;
    server server2.example.com;
    server server3.example.com;
}
```

セッション情報をサーバー側で保持しているアプリケーションで有効です。ただし、セッション情報はRedisなどの共有ストレージで管理する方が推奨されます。

### サーバーの状態管理

```nginx
upstream backend {
    # 通常のサーバー
    server server1.example.com;
    
    # 重み付け
    server server2.example.com weight=2;
    
    # バックアップサーバー（他が全てダウンした時のみ使用）
    server server3.example.com backup;
    
    # 一時的にダウンしているサーバー
    server server4.example.com down;
    
    # 最大失敗回数とタイムアウト
    server server5.example.com max_fails=3 fail_timeout=30s;
}
```

**パラメータの説明**

- `weight=2`：このサーバーは他の2倍の頻度でリクエストを受け取る
- `backup`：バックアップサーバー（通常は使用されない）
- `down`：メンテナンス中などで使用しない
- `max_fails=3`：3回連続で失敗したらダウンとみなす
- `fail_timeout=30s`：30秒間リクエストを送らない（その後再試行）

### ヘルスチェック

バックエンドサーバーの健全性を自動的にチェックできます（商用版のNGINX Plusで利用可能。オープンソース版では制限あり）。

オープンソース版では、`max_fails`と`fail_timeout`で簡易的なヘルスチェックを実現します。

```nginx
upstream backend {
    server server1.example.com max_fails=3 fail_timeout=30s;
    server server2.example.com max_fails=3 fail_timeout=30s;
    
    # キープアライブ接続を維持（パフォーマンス向上）
    keepalive 32;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### セッション維持

ユーザーのセッションを同じサーバーに維持する必要がある場合の設定です。

```nginx
upstream backend {
    # クッキーベースのセッション維持
    # "route"というクッキーでサーバーを識別
    hash $cookie_route consistent;
    
    server server1.example.com route=a;
    server server2.example.com route=b;
    server server3.example.com route=c;
}
```

または、IPハッシュを使用：

```nginx
upstream backend {
    ip_hash;
    server server1.example.com;
    server server2.example.com;
    server server3.example.com;
}
```

## パフォーマンスチューニング

NGINXのパフォーマンスを最大限に引き出すための設定です。

### ワーカープロセスの最適化

```nginx
# CPUコア数に応じて自動設定（推奨）
worker_processes auto;

# または手動で指定（4コアCPUの場合）
# worker_processes 4;

# 各ワーカープロセスが開けるファイル数の上限
worker_rlimit_nofile 65535;

events {
    # 1ワーカーあたりの同時接続数
    worker_connections 4096;
    
    # epollを使用（Linux環境で推奨）
    use epoll;
    
    # 複数の接続を同時に受け入れる
    multi_accept on;
}
```

**計算方法**

最大同時接続数 = `worker_processes` × `worker_connections`

例：4コアCPU、worker_connections 4096の場合
→ 最大16,384接続を処理可能

### バッファサイズの調整

```nginx
http {
    # クライアントリクエストボディのバッファサイズ
    client_body_buffer_size 16K;
    
    # リクエストヘッダーのバッファサイズ
    client_header_buffer_size 1k;
    
    # 大きなリクエストヘッダー用のバッファ
    large_client_header_buffers 4 8k;
    
    # アップロード可能な最大ファイルサイズ
    client_max_body_size 20M;
}
```

**サイズの目安**

- 小規模サイト：上記のデフォルト値で十分
- 大規模サイト：より大きな値に調整
- ファイルアップロード機能がある場合：`client_max_body_size`を大きくする

### タイムアウト設定

```nginx
http {
    # クライアントのリクエストボディ受信タイムアウト
    client_body_timeout 12s;
    
    # クライアントのリクエストヘッダー受信タイムアウト
    client_header_timeout 12s;
    
    # キープアライブ接続のタイムアウト
    keepalive_timeout 15s;
    
    # レスポンス送信のタイムアウト
    send_timeout 10s;
    
    # リクエストボディの読み取りを遅延させる時間
    # スロークライアント対策
    reset_timedout_connection on;
}
```

タイムアウトを短くしすぎると、遅い回線のユーザーが正常にアクセスできなくなるので注意が必要です。

### キープアライブ接続の最適化

```nginx
http {
    # 1つのキープアライブ接続で処理できるリクエスト数
    keepalive_requests 100;
    
    # キープアライブタイムアウト
    keepalive_timeout 65s;
}

upstream backend {
    server localhost:3000;
    
    # バックエンドへのキープアライブ接続を維持
    keepalive 32;
    keepalive_timeout 60s;
    keepalive_requests 100;
}
```

キープアライブを使用することで、TCP接続の確立・切断のオーバーヘッドを削減できます。

### ファイルディスクリプタの上限引き上げ

大量の接続を処理する場合、システムの制限を引き上げる必要があります。

```bash
# 現在の制限を確認
ulimit -n

# 一時的に引き上げ
ulimit -n 65535
```

恒久的に変更する場合、`/etc/security/limits.conf`に追加：

```
nginx soft nofile 65535
nginx hard nofile 65535
```

NGINX設定にも反映：

```nginx
worker_rlimit_nofile 65535;
```

### レート制限（DoS攻撃対策）

特定のIPアドレスからの過剰なリクエストを制限します。

```nginx
http {
    # ゾーンの定義：10MBのメモリ使用、1秒間に10リクエストまで
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            # レート制限を適用
            # burst=20: 瞬間的に20リクエストまでキューイング
            # nodelay: キューイングせず即座に処理
            limit_req zone=mylimit burst=20 nodelay;
            
            root /var/www/html;
        }
        
        # APIエンドポイントはより厳しく制限
        location /api/ {
            limit_req zone=mylimit burst=5 nodelay;
            proxy_pass http://localhost:3000;
        }
    }
}
```

**パラメータの説明**

- `rate=10r/s`：1秒間に10リクエストまで
- `burst=20`：一時的に20リクエストまで受け付ける（超過分はキュー）
- `nodelay`：キューイングせずすぐに処理（または拒否）

### 接続数の制限

同時接続数を制限します。

```nginx
http {
    # 同時接続数の制限ゾーン
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    server {
        listen 80;
        server_name example.com;
        
        # 1つのIPアドレスから同時に10接続まで
        limit_conn addr 10;
        
        location /download {
            # ダウンロードは1接続まで
            limit_conn addr 1;
            
            # 帯域制限（500KB/秒）
            limit_rate 500k;
            
            root /var/www;
        }
    }
}
```

## 設定ファイルのテストとリロード

設定変更後の手順を確認します。

### 設定ファイルの文法チェック

設定を変更したら、必ず文法チェックを行います。

```bash
# 設定ファイルのテスト
sudo nginx -t
```

**成功時の出力**

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**エラー時の出力例**

```
nginx: [emerg] unexpected "}" in /etc/nginx/nginx.conf:25
nginx: configuration file /etc/nginx/nginx.conf test failed
```

エラーメッセージには、問題のあるファイル名と行番号が表示されます。

### よくある設定エラー

#### 1. セミコロンの付け忘れ

```nginx
# 誤り
server {
    listen 80
    server_name example.com;
}

# 正しい
server {
    listen 80;
    server_name example.com;
}
```

#### 2. 中括弧の閉じ忘れ

```nginx
# 誤り
server {
    listen 80;
    location / {
        root /var/www/html;
    # locationの閉じ忘れ
}

# 正しい
server {
    listen 80;
    location / {
        root /var/www/html;
    }
}
```

#### 3. ディレクティブのタイプミス

```nginx
# 誤り
server {
    liste 80;  # "listen"のタイプミス
}

# 正しい
server {
    listen 80;
}
```

#### 4. 不正なコンテキスト

```nginx
# 誤り（listenはserverコンテキスト内でのみ使用可能）
http {
    listen 80;
}

# 正しい
http {
    server {
        listen 80;
    }
}
```

### 設定の再読み込み

文法チェックが成功したら、設定を適用します。

```bash
# 方法1: systemctlを使用（推奨）
sudo systemctl reload nginx

# 方法2: NGINXコマンドを使用
sudo nginx -s reload

# 方法3: 再起動（接続が一時的に切断される）
sudo systemctl restart nginx
```

**reloadとrestartの違い**

- `reload`：実行中の接続を維持したまま設定を反映（ダウンタイムなし）
- `restart`：NGINXを一度停止してから起動（瞬間的にサービスが停止）

通常は`reload`を使用します。

### 設定変更のベストプラクティス

```bash
# 1. 設定ファイルのバックアップ
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# 2. 設定を編集
sudo nano /etc/nginx/nginx.conf

# 3. 文法チェック
sudo nginx -t

# 4. 問題なければリロード
sudo systemctl reload nginx

# 5. ログを確認
sudo tail -f /var/log/nginx/error.log
```

エラーが発生した場合は、バックアップから復元します：

```bash
sudo cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
sudo systemctl reload nginx
```

## トラブルシューティング

よくある問題と解決方法を解説します。

### NGINXが起動しない

#### 症状

```bash
sudo systemctl start nginx
# エラーが発生
```

#### 原因と解決方法

**1. ポートが既に使用されている**

```bash
# ポート80を使用しているプロセスを確認
sudo lsof -i :80
# または
sudo netstat -tulpn | grep :80
```

Apache httpd などが既に起動している場合は停止します：

```bash
sudo systemctl stop apache2  # Ubuntu/Debian
sudo systemctl stop httpd    # CentOS/RHEL
```

**2. 設定ファイルにエラーがある**

```bash
sudo nginx -t
```

エラーメッセージを読んで修正します。

**3. 権限の問題**

```bash
# エラーログを確認
sudo tail -20 /var/log/nginx/error.log
```

パーミッションエラーが表示されている場合：

```bash
# ドキュメントルートの権限を確認・修正
sudo chown -R nginx:nginx /var/www/html
sudo chmod 755 /var/www/html
```

### 403 Forbiddenエラー

#### 症状

ブラウザで「403 Forbidden」と表示される。

#### 原因と解決方法

**1. ディレクトリのパーミッション**

NGINXユーザーがファイルを読み取れない可能性があります。

```bash
# パーミッションを確認
ls -la /var/www/html

# 修正
sudo chmod 755 /var/www/html
sudo chmod 644 /var/www/html/index.html
```

**2. インデックスファイルが存在しない**

```bash
# index.htmlが存在するか確認
ls /var/www/html/index.html
```

存在しない場合は作成します：

```bash
echo "<h1>Test Page</h1>" | sudo tee /var/www/html/index.html
```

**
3. SELinuxによる制限（CentOS/RHELの場合）**

SELinuxが有効な場合、ファイルへのアクセスがブロックされることがあります。

```bash
# SELinuxの状態を確認
getenforce

# 一時的に無効化（テスト用）
sudo setenforce 0
```

これで問題が解決する場合、SELinuxのコンテキストを設定します：

```bash
# 正しいコンテキストを設定
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
sudo restorecon -Rv /var/www/html

# SELinuxを再度有効化
sudo setenforce 1
```

**4. ディレクトリリスティングの問題**

`index`ファイルが見つからず、ディレクトリリスティングも無効になっている場合：

```nginx
location / {
    root /var/www/html;
    index index.html index.htm;
    # autoindexを有効にする（開発環境のみ推奨）
    autoindex on;
}
```

### 502 Bad Gatewayエラー

#### 症状

リバースプロキシ経由でバックエンドにアクセスすると「502 Bad Gateway」と表示される。

#### 原因と解決方法

**1. バックエンドサーバーが起動していない**

```bash
# バックエンドサーバーの状態を確認
# 例：Node.jsアプリケーションの場合
ps aux | grep node

# 起動していない場合は起動
node app.js
# または
pm2 start app.js
```

**2. バックエンドのポート番号が間違っている**

NGINX設定を確認：

```nginx
location / {
    # ポート番号が正しいか確認
    proxy_pass http://localhost:3000;
}
```

バックエンドが実際に動作しているポートを確認：

```bash
sudo netstat -tulpn | grep 3000
```

**3. ファイアウォールによるブロック**

```bash
# ファイアウォールの状態を確認（Ubuntu/Debian）
sudo ufw status

# ポート3000を許可
sudo ufw allow 3000

# ファイアウォールの状態を確認（CentOS/RHEL）
sudo firewall-cmd --list-all

# ポート3000を許可
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

**4. SELinuxによるブロック（CentOS/RHEL）**

NGINXがネットワーク接続を行えない設定になっている可能性があります：

```bash
# SELinuxのブール値を確認
getsebool httpd_can_network_connect

# 許可する
sudo setsebool -P httpd_can_network_connect 1
```

**5. タイムアウト**

バックエンドの処理に時間がかかりすぎている場合：

```nginx
location / {
    proxy_pass http://localhost:3000;
    proxy_connect_timeout 90s;
    proxy_send_timeout 90s;
    proxy_read_timeout 90s;
}
```

### 504 Gateway Timeoutエラー

#### 症状

バックエンドからの応答が遅く、タイムアウトが発生する。

#### 解決方法

タイムアウト時間を延長します：

```nginx
http {
    # グローバルなタイムアウト設定
    proxy_connect_timeout 120s;
    proxy_send_timeout 120s;
    proxy_read_timeout 120s;
}

server {
    listen 80;
    
    location /slow-api {
        proxy_pass http://localhost:3000;
        # このlocationだけ長めに設定
        proxy_read_timeout 300s;
    }
}
```

バックエンドのパフォーマンスも改善を検討してください。

### ログファイルが肥大化

#### 症状

ログファイルが大きくなりすぎて、ディスク容量を圧迫している。

#### 解決方法

**1. ログローテーションの確認**

```bash
# ログローテーション設定を確認
cat /etc/logrotate.d/nginx

# 手動でローテーションを実行
sudo logrotate -f /etc/logrotate.d/nginx
```

**2. 不要なログを無効化**

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 静的ファイルのアクセスログを無効化
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        access_log off;
        root /var/www/html;
    }
    
    # ヘルスチェックのログを無効化
    location /health {
        access_log off;
        return 200 "OK";
    }
}
```

**3. 古いログファイルの削除**

```bash
# 30日以前のログを削除
sudo find /var/log/nginx -name "*.log.*" -mtime +30 -delete

# 圧縮されたログを削除
sudo find /var/log/nginx -name "*.gz" -mtime +30 -delete
```

### SSL証明書のエラー

#### 症状

ブラウザで「この接続ではプライバシーが保護されません」と表示される。

#### 原因と解決方法

**1. 証明書のパスが間違っている**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    # パスを確認
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
}
```

ファイルの存在確認：

```bash
ls -l /etc/nginx/ssl/example.com.crt
ls -l /etc/nginx/ssl/example.com.key
```

**2. 証明書の有効期限切れ**

```bash
# 証明書の有効期限を確認
sudo openssl x509 -in /etc/nginx/ssl/example.com.crt -noout -dates

# Let's Encryptの証明書を更新
sudo certbot renew
```

**3. 証明書チェーンが不完全**

Let's Encryptの場合、`fullchain.pem`を使用していることを確認：

```nginx
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

**4. ドメイン名の不一致**

証明書のドメイン名と実際のドメイン名が一致しているか確認：

```bash
# 証明書に含まれるドメイン名を確認
sudo openssl x509 -in /etc/nginx/ssl/example.com.crt -noout -text | grep DNS
```

### パフォーマンスが遅い

#### 診断方法

**1. アクセスログで応答時間を確認**

まず、ログフォーマットに応答時間を含めます：

```nginx
http {
    log_format timed '$remote_addr - $remote_user [$time_local] '
                     '"$request" $status $body_bytes_sent '
                     '"$http_referer" "$http_user_agent" '
                     'request_time=$request_time '
                     'upstream_response_time=$upstream_response_time';
    
    access_log /var/log/nginx/access.log timed;
}
```

ログを分析：

```bash
# 応答時間が1秒以上のリクエストを表示
sudo grep "request_time=[1-9]" /var/log/nginx/access.log

# 応答時間の平均を計算（awkを使用）
sudo awk '{print $NF}' /var/log/nginx/access.log | awk -F= '{sum+=$2; count++} END {print sum/count}'
```

**2. NGINXのステータス情報を確認**

NGINXのステータスページを有効化：

```nginx
server {
    listen 80;
    server_name localhost;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;  # ローカルからのみアクセス可能
        deny all;
    }
}
```

ステータスの確認：

```bash
curl http://localhost/nginx_status
```

出力例：

```
Active connections: 291
server accepts handled requests
 16630948 16630948 31070465
Reading: 6 Writing: 179 Waiting: 106
```

- `Active connections`：現在の接続数
- `Reading`：リクエストヘッダーを読み取り中
- `Writing`：レスポンスを送信中
- `Waiting`：キープアライブ接続で待機中

#### 改善方法

**1. キャッシュの有効化**

静的ファイルのキャッシュ：

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**2. Gzip圧縮の有効化**

```nginx
http {
    gzip on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript;
}
```

**3. ワーカープロセスの調整**

```nginx
worker_processes auto;
worker_connections 4096;
```

**4. バックエンド接続のキープアライブ**

```nginx
upstream backend {
    server localhost:3000;
    keepalive 32;
}

server {
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### デバッグログの有効化

問題の原因が特定できない場合、デバッグログを有効にします。

```nginx
error_log /var/log/nginx/error.log debug;
```

注意：デバッグログは非常に詳細で大量のログが生成されるため、問題解決後は必ず元に戻してください：

```nginx
error_log /var/log/nginx/error.log error;
```

デバッグログの確認：

```bash
sudo tail -f /var/log/nginx/error.log
```

## 実践的な設定例

よくある用途別の完全な設定例を紹介します。

### 例1: シンプルな静的サイト

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # HTTPSにリダイレクト
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL証明書
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # セキュリティ設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # セキュリティヘッダー
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # ドキュメントルート
    root /var/www/example.com;
    index index.html index.htm;
    
    # アクセスログとエラーログ
    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;
    
    # メインコンテンツ
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 静的ファイルのキャッシュ
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # 隠しファイルへのアクセス拒否
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # robots.txtとfavicon
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    # カスタムエラーページ
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
    
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        internal;
    }
}
```

### 例2: WordPressサイト

```nginx
server {
    listen 80;
    server_name wordpress.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name wordpress.example.com;
    
    # SSL設定
    ssl_certificate /etc/letsencrypt/live/wordpress.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wordpress.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # WordPressのディレクトリ
    root /var/www/wordpress;
    index index.php index.html;
    
    # ログ
    access_log /var/log/nginx/wordpress-access.log;
    error_log /var/log/nginx/wordpress-error.log;
    
    # アップロードサイズの制限
    client_max_body_size 50M;
    
    # パーマリンク対応
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP処理
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # タイムアウト設定
        fastcgi_read_timeout 300;
    }
    
    # 静的ファイルのキャッシュ
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        log_not_found off;
    }
    
    # wp-config.phpへの直接アクセスを拒否
    location = /wp-config.php {
        deny all;
    }
    
    # xmlrpc.phpへのアクセスを制限（スパム対策）
    location = /xmlrpc.php {
        deny all;
    }
    
    # wp-adminへのアクセス制限（オプション）
    location /wp-admin/ {
        # 特定のIPからのみアクセス可能
        # allow 192.168.1.0/24;
        # deny all;
        
        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
    
    # 隠しファイルの保護
    location ~ /\. {
        deny all;
    }
}
```

### 例3: Node.jsアプリケーション（リバースプロキシ）

```nginx
# アップストリームの定義
upstream nodejs_app {
    server localhost:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name app.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name app.example.com;
    
    # SSL設定
    ssl_certificate /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # ログ
    access_log /var/log/nginx/app-access.log;
    error_log /var/log/nginx/app-error.log;
    
    # セキュリティヘッダー
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 静的ファイルはNGINXが直接配信
    location /static/ {
        alias /var/www/app/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /public/ {
        alias /var/www/app/public/;
        expires 30d;
    }
    
    # APIエンドポイント
    location /api/ {
        # レート制限
        limit_req zone=api_limit burst=10 nodelay;
        
        proxy_pass http://nodejs_app;
        proxy_http_version 1.1;
        
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_cache_bypass $http_upgrade;
        
        # タイムアウト
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # WebSocket対応
    location /socket.io/ {
        proxy_pass http://nodejs_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        
        # WebSocketのタイムアウト
        proxy_read_timeout 86400;
    }
    
    # その他のリクエストをNode.jsに転送
    location / {
        proxy_pass http://nodejs_app;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# レート制限ゾーンの定義（httpコンテキストで）
# limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
```

### 例4: 複数のバックエンドサーバーでロードバランシング

```nginx
# バックエンドサーバー群の定義
upstream backend_cluster {
    least_conn;  # 最小接続数方式
    
    server 192.168.1.101:8080 weight=3 max_fails=3 fail_timeout=30s;
    server 192.168.1.102:8080 weight=2 max_fails=3 fail_timeout=30s;
    server 192.168.1.103:8080 weight=1 max_fails=3 fail_timeout=30s;
    server 192.168.1.104:8080 backup;  # バックアップサーバー
    
    keepalive 32;
}

server {
    listen 80;
    server_name lb.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name lb.example.com;
    
    ssl_certificate /etc/letsencrypt/live/lb.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lb.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    access_log /var/log/nginx/lb-access.log;
    error_log /var/log/nginx/lb-error.log;
    
    location / {
        proxy_pass http://backend_cluster;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # ヘッダー設定
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # タイムアウト設定
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 次のサーバーへのフェイルオーバー
        proxy_next_upstream error timeout http_500 http_502 http_503;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # エラー時のNGINXエラーページを表示
        proxy_intercept_errors on;
    }
    
    # ヘルスチェック用エンドポイント
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # カスタムエラーページ
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
}
```

## まとめ：設定の基本フロー

NGINXの設定を行う際は、以下の流れで進めてください。

### 1. 目的を明確にする

- 静的サイトを公開したいのか？
- リバースプロキシとして使いたいのか？
- ロードバランシングが必要か？
- HTTPSは必要か？

### 2. 基本設定から始める

最初はシンプルな設定から始め、動作確認してから機能を追加していきます。

```nginx
# 最小限の設定
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 3. 段階的に機能を追加

動作確認ができたら、必要な機能を1つずつ追加します。

1. ログの設定
2. エラーページのカスタマイズ
3. SSL/TLSの設定
4. キャッシュの設定
5. セキュリティヘッダーの追加
6. パフォーマンスチューニング

### 4. テストを繰り返す

機能を追加するたびに、必ずテストします。

```bash
# 文法チェック
sudo nginx -t

# リロード
sudo systemctl reload nginx

# ログ確認
sudo tail -f /var/log/nginx/error.log

# ブラウザで動作確認
curl -I https://example.com
```

### 5. ドキュメント化

設定の意図をコメントとして残しておくと、後で見返す時に便利です。

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # 2024-11-10: SSL証明書をLet's Encryptに変更
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # 2024-11-10: 管理画面へのアクセスを社内IPに制限
    location /admin {
        allow 192.168.1.0/24;
        deny all;
    }
}
```

### 6. バックアップを取る

重要な変更を行う前は、必ずバックアップを取ります。

```bash
# 設定ファイルのバックアップ
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.$(date +%Y%m%d)
sudo cp /etc/nginx/sites-available/example.conf /etc/nginx/sites-available/example.conf.backup
```

### 7. 定期的なメンテナンス

- ログファイルの確認と整理
- SSL証明書の有効期限確認
- NGINXのバージョンアップ
- セキュリティアップデートの適用

```bash
# NGINXのバージョン確認
nginx -v

# アップデート（Ubuntu/Debian）
sudo apt update
sudo apt upgrade nginx

# アップデート（CentOS/RHEL）
sudo yum update nginx
```

これらの基本を理解し、段階的に設定を進めていくことで、NGINXを効果的に活用できるようになります。問題が発生した場合は、ログを確認し、設定を1つずつ見直していくことが重要です。



    
