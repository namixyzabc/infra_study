# NGINX基本的な設定方法

## NGINXとは

NGINXは高速で軽量なWebサーバーソフトウェアです。静的ファイルの配信、リバースプロキシ、ロードバランサーなど、さまざまな用途で使用されます。

## 基本的な設定ファイルの構造

NGINXの設定ファイルは通常 `/etc/nginx/nginx.conf` に配置されています。設定は階層構造になっており、ディレクティブと呼ばれる命令で構成されます。

```nginx
# メインコンテキスト
user nginx;
worker_processes auto;

events {
    # eventsコンテキスト
    worker_connections 1024;
}

http {
    # httpコンテキスト
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        # serverコンテキスト
        listen 80;
        server_name example.com;
        
        location / {
            # locationコンテキスト
            root /var/www/html;
            index index.html;
        }
    }
}
```

## 主要な設定項目

### 1. worker_processes

NGINXが使用するワーカープロセスの数を指定します。`auto` に設定すると、CPUコア数に応じて自動的に決定されます。

```nginx
worker_processes auto;
```

### 2. events ブロック

接続処理に関する設定を記述します。

```nginx
events {
    worker_connections 1024;  # 1つのワーカーが処理できる同時接続数
}
```

### 3. http ブロック

Webサーバーとしての設定全体を記述します。

```nginx
http {
    # MIMEタイプの設定ファイルを読み込む
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # ログの設定
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # パフォーマンス向上のための設定
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
}
```

## 基本的なWebサイトの設定例

### シンプルな静的サイト

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    root /var/www/example.com;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

この設定の説明:
- `listen 80`: ポート80で待ち受けます
- `server_name`: このサーバーブロックが処理するドメイン名
- `root`: ファイルを配信するディレクトリ
- `index`: デフォルトで表示するファイル
- `try_files`: リクエストされたファイルを順番に探し、見つからなければ404エラーを返します

### 複数のロケーションを持つ設定

```nginx
server {
    listen 80;
    server_name example.com;
    
    root /var/www/example.com;
    
    # トップページ
    location / {
        index index.html;
    }
    
    # 画像ファイル
    location /images/ {
        expires 30d;  # 30日間キャッシュ
    }
    
    # 特定のファイル拡張子の処理
    location ~ \.(jpg|jpeg|png|gif|ico)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## リバースプロキシの基本設定

アプリケーションサーバー(例: Node.js)へリクエストを転送する場合の設定です。

```nginx
server {
    listen 80;
    server_name app.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

この設定では、ポート80に来たリクエストをローカルホストのポート3000で動作しているアプリケーションに転送します。

## 設定ファイルの管理方法

実際の運用では、設定を分割して管理します。

```nginx
# /etc/nginx/nginx.conf
http {
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

個別のサイト設定は `/etc/nginx/sites-available/` に配置し、有効にしたいものを `/etc/nginx/sites-enabled/` にシンボリックリンクを作成します。

```bash
# 設定ファイルを作成
sudo nano /etc/nginx/sites-available/example.com

# シンボリックリンクを作成して有効化
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
```

## 設定の確認とリロード

設定変更後は、必ず文法チェックを行ってから再読み込みします。

```bash
# 設定ファイルの文法チェック
sudo nginx -t

# 問題がなければリロード
sudo systemctl reload nginx

# または
sudo nginx -s reload
```

## よく使う設定例

### エラーページのカスタマイズ

```nginx
server {
    listen 80;
    server_name example.com;
    
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /var/www/error;
        internal;
    }
    
    location = /50x.html {
        root /var/www/error;
        internal;
    }
}
```

### リダイレクト設定

```nginx
# HTTPからHTTPSへのリダイレクト
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

# wwwなしからwwwありへのリダイレクト
server {
    listen 80;
    server_name example.com;
    return 301 http://www.example.com$request_uri;
}
```

### 基本認証の設定

```nginx
location /admin/ {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

パスワードファイルは以下のコマンドで作成します。

```bash
sudo htpasswd -c /etc/nginx/.htpasswd username
```

## まとめ

NGINXの基本的な設定は以下の流れで行います。

1. `/etc/nginx/nginx.conf` または `/etc/nginx/sites-available/` に設定ファイルを作成
2. `server` ブロックでドメインとポートを指定
3. `location` ブロックでパスごとの処理を定義
4. `nginx -t` で文法チェック
5. `systemctl reload nginx` で設定を反映

