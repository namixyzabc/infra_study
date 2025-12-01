

## 1. 事前準備

### 1-1. Git のインストール確認

VS Code のターミナルで:

```bash
git --version
```

バージョンが表示されればOKです。  
インストールされていなければ、[Git公式サイト](https://git-scm.com/)からインストールしてください。

### 1-2. GitHub アカウントとリポジトリURL

編集したいGitHubリポジトリのページを開き、  
`Code` ボタン → `HTTPS` か `SSH` のURLをコピーしておきます。  
例: `https://github.com/ユーザー名/リポジトリ名.git`

---

## 2. リポジトリをローカルにclone

VS Code を開き、メニューから:

- `表示` → `ターミナル` を開く（ショートカット: ``Ctrl+` ``）

任意の作業ディレクトリに移動して、`git clone`:

```bash
cd 作業したいフォルダのパス
git clone https://github.com/ユーザー名/リポジトリ名.git
```

cloneされたフォルダに移動:

```bash
cd リポジトリ名
```

VS Codeでそのフォルダを開いていない場合は:

```bash
code .
```



