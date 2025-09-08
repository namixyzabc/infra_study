

## **CORSって何？**

「違うサイト同士が安全にやり取りするためのルール」

### **わかりやすい例**

`myapp.com → weather-api.com に「天気教えて！」`  
`ブラウザ：「ちょっと待って、本当に大丈夫？」`  
`weather-api.com：「myapp.comならOKだよ！」`  
`ブラウザ：「じゃあ通すね！」`

### **正式名称**

CORS \= Cross-Origin Resource Sharing（オリジン間リソース共有）

## **なぜ必要？同一オリジンポリシーとは？**

### **オリジンの構成要素**

`https://myapp.com:443/api`  
`├── プロトコル: https`  
`├── ドメイン: myapp.com`  
`└── ポート: 443`

### **セキュリティの理由**

悪い例：制限がない場合  
`JavaScript`  
`// 悪いサイトから`  
`fetch('https://your-bank.com/balance') // 😱 残高が盗まれる`  
`fetch('https://facebook.com/messages') // 😱 メッセージが読まれる`  
だから...

* ブラウザ：「違うオリジン同士のやり取りは基本禁止！」  
* これが 同一オリジンポリシー

## **CORSエラーが起こる場面**

### **よくあるパターン**

`JavaScript`  
`// localhost:3000 (フロントエンド) から実行`  
`fetch('https://api.example.com/users') // ❌ CORS エラー！`  
`fetch('http://localhost:8080/api/data') // ❌ ポートが違うのでエラー！`

### **実際のエラーメッセージ**

`❌ Access to fetch at 'https://api.example.com/users' from origin 'http://localhost:3000'`   
`has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present.`

### **エラーが出ない場合（同一オリジン）**

`JavaScript`  
`// https://myapp.com から実行`  
`fetch('/api/users') // ✅ 同じオリジンなのでOK`  
`fetch('https://myapp.com/data') // ✅ 同じオリジンなのでOK`

## **CORSの仕組み**

### **1\. シンプルリクエスト**

条件：

* メソッド：GET, POST, HEAD  
* 基本的なヘッダーのみ  
* Content-Type が text/plain など

流れ：  
`http`  
`GET /api/users HTTP/1.1`  
`Origin: https://myapp.com`

`↓ サーバーレスポンス ↓`

`HTTP/1.1 200 OK`  
`Access-Control-Allow-Origin: https://myapp.com`  
`Content-Type: application/json`

### **2\. プリフライトリクエスト（事前確認）**

複雑なリクエストの場合：  
`http`  
`OPTIONS /api/users HTTP/1.1`  
`Origin: https://myapp.com`  
`Access-Control-Request-Method: PUT`  
`Access-Control-Request-Headers: Content-Type`

`↓ サーバーが許可すれば ↓`

`HTTP/1.1 200 OK`  
`Access-Control-Allow-Origin: https://myapp.com`  
`Access-Control-Allow-Methods: GET, POST, PUT, DELETE`  
`Access-Control-Allow-Headers: Content-Type`

## **設定する場所と方法**

### **✅ 正解：API側（データを提供する側）で設定**

#### **パターン1：自分でAPIを開発している場合**

Node.js \+ Express  
`JavaScript`  
`const express = require('express');`  
`const app = express();`

`// 基本的な設定`  
`app.use((req, res, next) => {`  
  `res.header('Access-Control-Allow-Origin', 'https://myapp.com');`  
  `res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');`  
  `res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');`  
  `next();`  
`});`

`// プリフライト対応`  
`app.options('*', (req, res) => {`  
  `res.sendStatus(200);`  
`});`  
Python \+ Flask  
`Python`  
`from flask import Flask`  
`from flask_cors import CORS`

`app = Flask(__name__)`  
`# 特定のオリジンのみ許可`  
`CORS(app, origins=['https://myapp.com'])`

`@app.route('/api/users')`  
`def get_users():`  
    `return {'users': ['Alice', 'Bob']}`  
PHP  
`PHP`  
**`<?php`**  
`// レスポンスヘッダーを設定`  
`header('Access-Control-Allow-Origin: https://myapp.com');`  
`header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');`  
`header('Access-Control-Allow-Headers: Content-Type, Authorization');`

`// プリフライト対応`  
`if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {`  
    `http_response_code(200);`  
    `exit();`  
`}`

`echo json_encode(['users' => ['Alice', 'Bob']]);`  
**`?>`**

#### **パターン2：クラウドサービス利用の場合**

Vercel  
`json`  
`// vercel.json`  
`{`  
  `"headers": [`  
    `{`  
      `"source": "/api/(.*)",`  
      `"headers": [`  
        `{`  
          `"key": "Access-Control-Allow-Origin",`  
          `"value": "https://myapp.com"`  
        `},`  
        `{`  
          `"key": "Access-Control-Allow-Methods",`   
          `"value": "GET, POST, PUT, DELETE"`  
        `}`  
      `]`  
    `}`  
  `]`  
`}`  
AWS Lambda  
`JavaScript`  
`exports.handler = async (event) => {`  
  `return {`  
    `statusCode: 200,`  
    `headers: {`  
      `'Access-Control-Allow-Origin': 'https://myapp.com',`  
      `'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',`  
      `'Access-Control-Allow-Headers': 'Content-Type, Authorization'`  
    `},`  
    `body: JSON.stringify({ users: ['Alice', 'Bob'] })`  
  `};`  
`};`

### **パターン3：外部API（制御できない）の場合**

#### **解決策1：プロキシサーバーを作る**

`JavaScript`  
`// あなたのサーバー (proxy-server.js)`  
`const express = require('express');`  
`const fetch = require('node-fetch');`  
`const app = express();`

`app.use((req, res, next) => {`  
  `// あなたのフロントエンドには許可`  
  `res.header('Access-Control-Allow-Origin', 'https://myapp.com');`  
  `next();`  
`});`

`app.get('/proxy/weather', async (req, res) => {`  
  `// 外部APIを呼び出し（サーバー間通信なのでCORSなし）`  
  `const response = await fetch('https://weather-api.com/current');`  
  `const data = await response.json();`  
  `res.json(data);`  
`});`

#### **解決策2：開発時のプロキシ設定**

React (package.json)  
`json`  
`{`  
  `"name": "my-app",`  
  `"proxy": "https://api.example.com",`  
  `"dependencies": {`  
    `"react": "^18.0.0"`  
  `}`  
`}`  
Vite (vite.config.js)  
`JavaScript`  
`export default {`  
  `server: {`  
    `proxy: {`  
      `'/api': {`  
        `target: 'https://api.example.com',`  
        `changeOrigin: true,`  
        `pathRewrite: { '^/api': '' }`  
      `}`  
    `}`  
  `}`  
`}`

## **重要なCORSヘッダー**

### **サーバーが返すヘッダー**

| ヘッダー | 役割 | 設定例 |
| ----- | ----- | ----- |
| Access-Control-Allow-Origin | 許可するオリジン | https://myapp.com または \* |
| Access-Control-Allow-Methods | 許可するHTTPメソッド | GET, POST, PUT, DELETE |
| Access-Control-Allow-Headers | 許可するヘッダー | Content-Type, Authorization |
| Access-Control-Allow-Credentials | クッキー送信許可 | true または false |
| Access-Control-Max-Age | プリフライトの有効期間 | 86400（24時間） |

### **注意：\* の制限**

`JavaScript`  
`// ❌ これは動かない`  
`res.header('Access-Control-Allow-Origin', '*');`  
`res.header('Access-Control-Allow-Credentials', 'true');`

`// ✅ 認証情報を使う場合は具体的なオリジン指定`  
`res.header('Access-Control-Allow-Origin', 'https://myapp.com');`  
`res.header('Access-Control-Allow-Credentials', 'true');`

## **よくあるトラブルと解決法**

### **1\. 認証情報（クッキー）が送られない**

`JavaScript`  
`// ❌ クッキーが送られない`  
`fetch('https://api.example.com/profile')`

`// ✅ 正しい設定`  
`fetch('https://api.example.com/profile', {`  
  `credentials: 'include' // クッキーを含める`  
`});`  
サーバー側も対応が必要：  
`JavaScript`  
`res.header('Access-Control-Allow-Credentials', 'true');`  
`res.header('Access-Control-Allow-Origin', 'https://myapp.com'); // * は使用不可`

### **2\. プリフライトが失敗する**

`JavaScript`  
`// カスタムヘッダーを使う場合`  
`fetch('https://api.example.com/data', {`  
  `headers: {`  
    `'X-Custom-Header': 'value' // これがあるとプリフライト発生`  
  `}`  
`});`  
サーバー側でヘッダー許可：  
`JavaScript`  
`res.header('Access-Control-Allow-Headers', 'Content-Type, X-Custom-Header');`

### **3\. 開発環境と本番環境で動作が違う**

`JavaScript`  
`// 環境に応じた設定`  
`const allowedOrigins = process.env.NODE_ENV === 'production'`   
  `? ['https://myapp.com']`  
  `: ['http://localhost:3000', 'http://localhost:3001'];`

`app.use((req, res, next) => {`  
  `const origin = req.headers.origin;`  
  `if (allowedOrigins.includes(origin)) {`  
    `res.header('Access-Control-Allow-Origin', origin);`  
  `}`  
  `next();`  
`});`

## **確認・デバッグ方法**

### **ブラウザの開発者ツール**

* F12 で開発者ツールを開く  
* Network タブを確認  
* 失敗したリクエスト をクリック  
* Response Headers に CORS ヘッダーがあるか確認

### **curl コマンドでテスト**

`bash`  
`# プリフライトリクエストをテスト`  
`curl -X OPTIONS \`  
  `-H "Origin: https://myapp.com" \`  
  `-H "Access-Control-Request-Method: POST" \`  
  `-H "Access-Control-Request-Headers: Content-Type" \`  
  `https://api.example.com/users`

## **セキュリティのベストプラクティス**

### **1\. 最小権限の原則**

`JavaScript`  
`// ❌ 危険：全て許可`  
`res.header('Access-Control-Allow-Origin', '*');`

`// ✅ 安全：必要最小限`  
`const allowedOrigins = [`  
  `'https://myapp.com',`  
  `'https://admin.myapp.com'`  
`];`

### **2\. 本番環境での注意**

`JavaScript`  
`// 環境変数で管理`  
`const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];`

`app.use((req, res, next) => {`  
  `const origin = req.headers.origin;`  
  `if (allowedOrigins.includes(origin)) {`  
    `res.header('Access-Control-Allow-Origin', origin);`  
  `}`  
  `next();`  
`});`

## **まとめ 💡**

### **重要ポイント**

* CORS \= ブラウザのセキュリティ機能  
* 設定は必ず API側（データ提供側）で行う  
* フロントエンド側では基本的に解決できない  
* 外部APIは プロキシサーバー で解決  
* 開発時は プロキシ設定 で回避可能

### **開発フロー**

`1. CORSエラーが発生 ❌`  
`2. API側でCORSヘッダー設定 🔧`  
`3. 必要に応じてプリフライト対応 ⚡`  
`4. テスト・確認 ✅`  
`5. 本番デプロイ 🚀`  
これでCORSを完全マスター！安全なWebアプリケーションを作りましょう 🎉
