# straceコマンドの解説

## straceとは

**strace**は、プログラムが実行中に行う**システムコール**（プログラムがOSカーネルに依頼する処理）とシグナルを追跡・表示するLinuxのデバッグツールです。

## 何ができるのか

```bash
strace ls
```

このように実行すると、`ls`コマンドが裏で何をしているかが見えます：

- どのファイルを開いているか
- どんなデータを読み書きしているか
- どのプロセスと通信しているか
- どこでエラーが起きているか

## 主な使い方

### 基本的な使用例

```bash
# コマンドのシステムコールを追跡
strace ls -la

# 実行中のプロセスにアタッチ
strace -p 1234

# 出力をファイルに保存
strace -o output.txt ls
```

### よく使うオプション

| オプション | 説明 | 例 |
|----------|------|-----|
| `-p PID` | 実行中のプロセスに接続 | `strace -p 1234` |
| `-o file` | 出力をファイルに保存 | `strace -o log.txt ls` |
| `-e trace=システムコール` | 特定のシステムコールだけ表示 | `strace -e trace=open,read ls` |
| `-c` | システムコールの統計を表示 | `strace -c ls` |
| `-t` | タイムスタンプを表示 | `strace -t ls` |
| `-f` | 子プロセスも追跡 | `strace -f ./script.sh` |

## 実用例

### 1. ファイルアクセスの確認

```bash
strace -e trace=open,openat cat /etc/passwd
```

`cat`コマンドがどのファイルを開いているか確認できます。

### 2. ネットワーク通信の確認

```bash
strace -e trace=connect,sendto,recvfrom curl google.com
```

どこに接続しているか、どんなデータを送受信しているかがわかります。

### 3. プログラムが遅い原因の調査

```bash
strace -c -p 1234
```

どのシステムコールに時間がかかっているか統計が出ます。

### 4. エラー原因の特定

```bash
strace ./myprogram 2>&1 | grep -i error
```

プログラムがどこで失敗しているか見つけられます。

## 出力の読み方

```bash
openat(AT_FDCWD, "/etc/passwd", O_RDONLY) = 3
read(3, "root:x:0:0:root:/root:/bin/bash\n", 4096) = 1024
close(3) = 0
```

- **openat** - システムコール名
- **(AT_FDCWD, "/etc/passwd", O_RDONLY)** - 引数
- **= 3** - 戻り値（この場合はファイルディスクリプタ番号）
- **= -1 ENOENT** - エラーの場合

## 実際の活用シーン

### ✅ 設定ファイルの場所がわからない

```bash
strace -e trace=openat myapp 2>&1 | grep "\.conf"
```

### ✅ なぜプログラムが起動しないのか

```bash
strace ./broken_program
```

不足しているライブラリやファイルが見つかります。

### ✅ どのポートに接続しているか

```bash
strace -e trace=connect wget example.com
```

## 注意点

⚠️ **パフォーマンス**: straceを使うとプログラムは大幅に遅くなります  
⚠️ **権限**: 他人のプロセスを追跡するにはroot権限が必要  
⚠️ **セキュリティ**: パスワードなどの機密情報が出力に含まれる可能性があります

## まとめ

straceは「プログラムの動作が見える化される」ツールです。トラブルシューティングや、プログラムの内部動作を理解するのに非常に便利で、Linux管理者や開発者にとって必須のツールと言えます。
