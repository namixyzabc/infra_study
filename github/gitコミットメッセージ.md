
### コミットメッセージ一覧表 / Commit Message Cheat Sheet

| プレフィックス (Prefix) | 意味 (Meaning) | 日本語の例 (Japanese Example) | 英語の例 (English Example) |
| :--- | :--- | :--- | :--- |
| **feat** | **新機能**の追加 (A new feature) | `feat: ユーザー認証機能を追加` | `feat: Add user authentication feature` |
| **fix** | **バグ修正** (A bug fix) | `fix: ログイン時のリダイレクト不具合を修正` | `fix: Correct redirect bug on login` |
| **docs** | **ドキュメント**のみの変更 (Documentation only changes) | `docs: README.mdにセットアップ手順を追記` | `docs: Add setup instructions to README.md` |
| **style** | コードの**スタイル**調整（フォーマット、セミコロンなど）。ロジックの変更は含まない (Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)) | `style: linterの警告に従いコードフォーマットを修正` | `style: Format code according to linter warnings` |
| **refactor** | バグ修正や機能追加ではない**コードの改善**（リファクタリング） (A code change that neither fixes a bug nor adds a feature) | `refactor: 認証サービスクラスをリファクタリング` | `refactor: Refactor authentication service class` |
| **test** | **テスト**の追加や修正 (Adding missing tests or correcting existing tests) | `test: ユーザー作成機能のテストケースを追加` | `test: Add test cases for user creation feature` |
| **chore** | **雑多なタスク**。ビルドプロセスや補助ツール、ライブラリの変更など (Other changes that don't modify src or test files) | `chore: 依存ライブラリのバージョンを更新` | `chore: Update dependency library versions` |
| **perf** | **パフォーマンス**を向上させるコード変更 (A code change that improves performance) | `perf: 画像読み込み処理を最適化し表示を高速化` | `perf: Optimize image loading process to speed up display` |
| **ci** | **CI/CD**関連の設定ファイルやスクリプトの変更 (Changes to our CI configuration files and scripts) | `ci: GitHub Actionsのデプロイメントスクリプトを更新` | `ci: Update GitHub Actions deployment script` |
| **revert** | 以前のコミットを**取り消す** (Reverts a previous commit) | `revert: feat: ユーザー認証機能を追加` (取り消すコミットの件名をそのまま記述) | `revert: feat: Add user authentication feature` (Write the subject of the commit to be reverted) |
| **build** | **ビルドシステム**や外部依存に関する変更（npm, webpack, gulpなど） (Changes that affect the build system or external dependencies) | `build: Webpackのバージョンを5に更新` | `build: Update Webpack to version 5` |

---

### その他のベストプラクティス / Other Best Practices

上記のプレフィックスに加えて、以下のルールを守ることで、さらにコミット履歴が読みやすくなります。

In addition to the prefixes above, following these rules will make your commit history even more readable.

1.  **件名（1行目）は50文字以内にする / Keep the subject line (first line) to 50 characters or less**
    *   `git log --oneline`などで一覧表示した際に見やすくなります。

2.  **件名は命令形（現在形）で書く / Use the imperative mood in the subject line**
    *   「〜した」という過去形ではなく、「〜する」という命令形で書きます。これはGitが自動生成するメッセージ（例: `git merge`）のスタイルと一致させるためです。
    *   **良い例 (Good):** `fix: ユーザー登録の不具合を修正` / `fix: Correct user registration bug`
    *   **悪い例 (Bad):** `fix: ユーザー登録の不具合を修正しました` / `fix: Fixed user registration bug`

3.  **件名の末尾にピリオドを付けない / Do not end the subject line with a period**
    *   これは一貫したスタイルを保つための慣習です。
    *   **良い例 (Good):** `docs: Add contribution guide`
    *   **悪い例 (Bad):** `docs: Add contribution guide.`

4.  **件名と本文の間に1行の空行を入れる / Separate subject from body with a blank line**
    *   詳細な説明が必要な場合は、件名（1行目）のあとに必ず空行を1行入れてから本文を記述します。これにより、多くのGitツールが件名と本文を正しく認識できます。
    *   If you need a detailed description, always add a blank line after the subject line (first line) before writing the body. This allows many Git tools to correctly distinguish between the subject and the body.

5.  **本文で「なぜ」「何を」を説明する / Explain "what" and "why" in the body, not "how"**
    *   コードを見れば「どのように」変更したかは分かります。コミットメッセージでは、**「なぜ」**その変更が必要だったのか、**「何を」**解決したのかという背景や目的を説明しましょう。


#### 良いコミットメッセージの構造例 / Example of a good commit message structure

```
feat: 支払い失敗時のリトライ機能を追加

ユーザーが支払い処理に失敗した場合、これまでは最初からやり直す必要があった。
この変更により、ユーザーは一度だけ即時リトライが可能になり、
ユーザー体験が向上する。

外部決済APIのエラーコードXXXが返された場合にリトライボタンを表示する。
```


