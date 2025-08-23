# **curlコマンドとは**

curlは、URLを使ってサーバーとデータをやり取りするコマンドラインツールです。

## **基本的な使い方**

`bash`  
`# 基本形`  
`curl [オプション] URL`

`# 例：ウェブページを取得`  
`curl https://example.com`

## **主要なオプション**

| オプション | 説明 | 例 |
| ----- | ----- | ----- |
| \-o | 出力をファイルに保存 | curl \-o file.html https://example.com |
| \-L | リダイレクトを追跡 | curl \-L https://example.com |
| \-H | HTTPヘッダーを指定 | curl \-H "Content-Type: application/json" |
| \-X | HTTPメソッドを指定 | curl \-X POST https://api.example.com |
| \-d | データを送信（POST） | curl \-d "key=value" https://api.example.com |
| \-u | 認証情報を指定 | curl \-u user:pass https://example.com |
| \-v | 詳細な実行情報を表示 | curl \-v https://example.com |

## **よくある使用例**

`bash`  
`# ファイルをダウンロード`  
`curl -o image.jpg https://example.com/image.jpg`

`# JSON APIにPOSTリクエスト`  
`curl -X POST -H "Content-Type: application/json" \`  
     `-d '{"name":"太郎"}' https://api.example.com/users`

`# レスポンスヘッダーも表示`  
`curl -i https://example.com`  
主な用途: API のテスト、ファイルのダウンロード、Webサービスとの通信など  
