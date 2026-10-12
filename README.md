# 同人サークルサイト Jekyll テンプレート

GitHub Pagesの標準Jekyll環境で動作する、同人サークル向けのWebサイトテンプレートです。

## フォルダ構成の特徴
- 作品ごとに `_works/<作品フォルダ>/` を作成し、その中に `index.md`、画像（`photo.svg`/`photo.jpg`）、説明書（`manual.pdf`）を同梱して自己完結管理できます。
- 全体レイアウトやスタイルはルートの `_layouts/`、`_includes/`、`assets/` で一元管理されています。

## GitHub Pagesへのデプロイ手順
1. 本リポジトリ（または展開したフォルダの内容）をGitHubの公開リポジトリ（Public）にプッシュします。
2. GitHubリポジトリの **Settings** > **Pages** を開きます。
3. **Source** を `Deploy from a branch` に設定し、`main`（または `master`）ブランチの `/ (root)` を選択して **Save** します。
4. `_config.yml` の `title` や `url`, `baseurl` をご自身のリポジトリ環境に合わせて編集してください。
   - ユーザーサイト (`<user>.github.io`) の場合: `baseurl: ""`
   - プロジェクトサイト (`<user>.github.io/<repo>`) の場合: `baseurl: "/<repo>"`
