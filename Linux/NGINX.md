# NGINXの設定方法

## NGINXとは

NGINXは高性能なWebサーバー・リバースプロキシサーバーです。軽量で高速な処理が特徴で、静的コンテンツの配信やロードバランサー、リバースプロキシとして広く利用されています。

## インストール

### Ubuntu/Debianの場合

```bash
sudo apt update
sudo apt install nginx
```

### CentOS/RHELの場合

```bash
sudo yum install epel-release
sudo yum install nginx
```

### インストール確認

```bash
nginx -v
```

## 基本的なディレクトリ構成

- `/etc/nginx/nginx.conf` - メイン設定ファイル
- `/etc/nginx/conf.d/` - 追加の設定ファイル用ディレクトリ
- `/etc/nginx/sites-available/` - 利用可能なサイト設定（Debian系）
- `/etc/nginx/sites-enabled/` - 有効化されたサイト設定（Debian系）
- `/var/log/nginx/` - ログファイル
- `/usr/share/nginx/html/` - デフォルトのドキュメントルート

## 基本的な設定ファイルの構造

NGINXの設定ファイルは「ディレクティブ」と「ブロック」で構成されます。

```nginx
# シンプルディレクティブ
user nginx;
worker_processes auto;

# ブロックディレクティブ
http {
    # httpブロック内の設定
    server {
        # serverブロック内の設定
        location / {
            # locationブロック内の設定
        }
    }
}
```

## メイン設定ファイル（nginx.conf）の基本

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
```

### 主要ディレクティブの説明

- `user` - NGINXを実行するユーザー
- `worker_processes` - ワーカープロセス数（autoで自動設定）
- `worker_connections` - 1つのワーカーが処理できる同時接続数
- `keepalive_timeout` - クライアント接続の維持時間（秒）
- `sendfile` - ファイル送信の最適化
- `include` - 外部ファイルの読み込み

## 基本的なWebサーバー設定

### 静的サイトの設定例

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

### ディレクティブの説明

- `listen` - 待ち受けるポート番号
- `server_name` - サーバーのドメイン名
- `root` - ドキュメントルートディレクトリ
- `index` - デフォルトのインデックスファイル
- `try_files` - ファイルの検索順序を指定

## locationブロックの使い方

locationブロックはURLパターンに応じた処理を定義します。

### 完全一致

```nginx
location = /specific-page {
    return 200 "This is exact match";
}
```

### 前方一致

```nginx
location /images/ {
    root /var/www;
    # /var/www/images/にアクセス
}
```

### 正規表現マッチ（大文字小文字を区別）

```nginx
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm.sock;
    include fastcgi_params;
}
```

### 正規表現マッチ（大文字小文字を区別しない）

```nginx
location ~* \.(jpg|jpeg|png|gif)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

### 優先順位の高い前方一致

```nginx
location ^~ /static/ {
    root /var/www;
}
```

## リバースプロキシの設定

バックエンドサーバーへリクエストを転送する設定です。

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### プロキシ設定の説明

- `proxy_pass` - 転送先のバックエンドサーバー
- `proxy_set_header` - バックエンドに送信するヘッダー
- `X-Real-IP` - クライアントの実際のIPアドレス
- `X-Forwarded-For` - プロキシ経由のIPアドレスリスト
- `X-Forwarded-Proto` - 元のプロトコル（http/https）

## 複数サイトの設定

### サイト設定ファイルの作成

`/etc/nginx/sites-available/site1.conf`

```nginx
server {
    listen 80;
    server_name site1.example.com;
    root /var/www/site1;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 設定の有効化

```bash
sudo ln -s /etc/nginx/sites-available/site1.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL/TLS（HTTPS）の設定

### 基本的なSSL設定

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

### Let's Encryptを使用する場合

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

## アクセス制御

### IPアドレスによる制限

```nginx
location /admin {
    allow 192.168.1.0/24;
    allow 10.0.0.1;
    deny all;
}
```

### Basic認証

```bash
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd username
```

```nginx
location /private {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

## ログ設定

### アクセスログのカスタマイズ

```nginx
http {
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       '$request_time $upstream_response_time';
    
    access_log /var/log/nginx/access.log detailed;
}
```

### 特定のlocationでログを無効化

```nginx
location /health-check {
    access_log off;
    return 200 "OK";
}
```

## リダイレクト設定

### 恒久的なリダイレクト（301）

```nginx
server {
    listen 80;
    server_name old-domain.com;
    return 301 https://new-domain.com$request_uri;
}
```

### 一時的なリダイレクト（302）

```nginx
location /old-page {
    return 302 /new-page;
}
```

### rewriteディレクティブの使用

```nginx
location /products {
    rewrite ^/products/(.*)$ /items/$1 permanent;
}
```

## 静的ファイルの最適化

### キャッシュ設定

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Gzip圧縮

```nginx
http {
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
}
```

## エラーハンドリング

### カスタムエラーページ

```nginx
server {
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /var/www/errors;
        internal;
    }
    
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
}
```

## ロードバランシング

### アップストリームの定義

```nginx
upstream backend {
    server backend1.example.com:8080 weight=3;
    server backend2.example.com:8080;
    server backend3.example.com:8080 backup;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### ロードバランシング方式

```nginx
# ラウンドロビン（デフォルト）
upstream backend {
    server server1.example.com;
    server server2.example.com;
}

# 最小接続数
upstream backend {
    least_conn;
    server server1.example.com;
    server server2.example.com;
}

# IPハッシュ
upstream backend {
    ip_hash;
    server server1.example.com;
    server server2.example.com;
}
```

## パフォーマンスチューニング

### バッファサイズの調整

```nginx
http {
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;
}
```

### タイムアウト設定

```nginx
http {
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;
}
```

### ワーカープロセスの最適化

```nginx
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

## 設定ファイルのテストとリロード

### 設定ファイルの文法チェック

```bash
sudo nginx -t
```

### 設定の再読み込み

```bash
sudo systemctl reload nginx
# または
sudo nginx -s reload
```

### NGINXの起動・停止

```bash
# 起動
sudo systemctl start nginx

# 停止
sudo systemctl stop nginx

# 再起動
sudo systemctl restart nginx

# 自動起動の有効化
sudo systemctl enable nginx
```

## セキュリティ設定

### サーバー情報の非表示

```nginx
http {
    server_tokens off;
}
```

### セキュリティヘッダーの追加

```nginx
server {
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
```

### レート制限

```nginx
http {
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=mylimit burst=20 nodelay;
        }
    }
}
```

## デバッグとトラブルシューティング

### デバッグログの有効化

```nginx
error_log /var/log/nginx/error.log debug;
```

### よくある設定エラー

```nginx
# 誤り：セミコロン忘れ
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

### ログの確認

```bash
# エラーログの確認
sudo tail -f /var/log/nginx/error.log

# アクセスログの確認
sudo tail -f /var/log/nginx/access.log
```

## 実践的な設定例

### WordPressサイトの設定

```nginx
server {
    listen 80;
    server_name wordpress.example.com;
    root /var/www/wordpress;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 1y;
        log_not_found off;
    }
    
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    
    location ~ /\. {
        deny all;
    }
}
```

### Node.jsアプリケーションの設定

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
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /static/ {
        alias /var/www/app/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## まとめのポイント

NGINXの設定を行う際の基本的な流れは次のとおりです。

1. 設定ファイルを編集する
2. `nginx -t`で文法チェックを行う
3. エラーがなければ`systemctl reload nginx`で設定を反映する
4. ログを確認して動作を検証する

設定を変更する際は必ずバックアップを取り、少しずつ変更を加えながらテストすることで、問題が発生した場合も素早く対処できます。
