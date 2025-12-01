# **GETリクエストのクエリストリングとは**

## **基本概念**

クエリストリングとは、URLの末尾に?（クエスチョンマーク）を付けて、サーバーにデータを送信する方法です。主にGETリクエストで使用されます。

## **基本的な構造**

`https://example.com/search?key1=value1&key2=value2&key3=value3`

### **構成要素**

* ベースURL: https://example.com/search  
* 区切り文字: ?（クエリストリングの開始を示す）  
* パラメータ: key=valueの形式  
* 連結文字: &（複数のパラメータを繋ぐ）

## **具体例**

### **検索サイトの例**

`https://www.google.com/search?q=プログラミング&lang=ja&num=10`  
この例では：

* q=プログラミング：検索キーワード  
* lang=ja：言語設定（日本語）  
* num=10：表示件数

### **ECサイトの商品フィルター例**

`https://shop.com/products?category=electronics&price_min=1000&price_max=5000&sort=price_asc`

## **特徴とメリット**

### **✅ メリット**

* シンプル：URLに直接データが含まれる  
* ブックマーク可能：URLを保存すれば同じ検索結果を再現できる  
* キャッシュ可能：ブラウザがページをキャッシュできる  
* デバッグしやすい：URLを見ればどんなデータが送信されているかすぐ分かる

### **❌ 注意点**

* データが丸見え：URLに表示されるため機密情報は送れない  
* 文字数制限：ブラウザによってURLの長さに制限がある  
* 日本語は文字化け：エンコードが必要

## **エンコードについて**

日本語や特殊文字はURLエンコードが必要です。  
`元の文字: 東京都`  
`エンコード後: %E6%9D%B1%E4%BA%AC%E9%83%BD`

## **実際の使用場面**

### **1\. 検索機能**

`/search?keyword=JavaScript&category=programming`

### **2\. ページネーション**

`/articles?page=2&limit=20`

### **3\. フィルタリング**

`/products?color=red&size=M&brand=nike`

### **4\. 並び替え**

`/list?sort=date&order=desc`

## **プログラムでの取得方法**

### **JavaScript（ブラウザ側）**

`JavaScript`  
`const urlParams = new URLSearchParams(window.location.search);`  
`const keyword = urlParams.get('keyword');`  
`console.log(keyword); // 検索キーワードを取得`

| 1行目：クエリストリングを取得 `JavaScript window.location.search  // URLの"?"以降を文字列で取得 // 例：現在のURLが https://example.com/search?keyword=JavaScript の場合 // 結果："?keyword=JavaScript"` 2行目：URLSearchParamsオブジェクトを作成 `JavaScript new URLSearchParams(...)  // クエリストリングを操作しやすいオブジェクトに変換` 3行目：特定のパラメータを取得 `JavaScript urlParams.get('keyword')  // 'keyword'パラメータの値を取得 // 結果："JavaScript"（存在しない場合はnull）`  |
| :---- |

### **PHP（サーバー側）**

`PHP`  
`$keyword = $_GET['keyword'];`  
`echo $keyword; // 検索キーワードを表示`

## **まとめ**

クエリストリングは、シンプルでわかりやすいデータ送信方法です。検索機能やフィルタリング機能など、ユーザーが結果をブックマークしたい場面でよく使われます。ただし、機密情報の送信には適さないため、用途に応じて適切に使い分けることが大切です。  
