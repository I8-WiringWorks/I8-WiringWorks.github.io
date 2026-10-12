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

## ディレクトリ構成

```
circle_site_jekyll_template/
├── _config.yml               # コレクション（works/events）設定済み設定ファイル
├── index.md                  # トップページ（最新作品・イベント掲載）
├── about.md                  # サークル紹介・リンク集
├── works.html                # 作品一覧ページ（カードグリッド表示）
├── events.html               # 参加イベント・お品書き一覧ページ
│
├── _layouts/                 # 共通レイアウト
│   ├── default.html          # HTML基盤・ヘッダー・フッター枠組み
│   ├── work.html             # 作品詳細ページ（ステータス・価格・PDFボタン対応）
│   └── event.html            # イベント詳細ページ
│
├── _includes/                # 再利用コンポーネント
│   ├── head.html             # メタタグ・OGP・CSS読み込み
│   ├── header.html           # ナビゲーションバー
│   ├── footer.html           # コピーライト表示
│   └── work-card.html        # 作品一覧・トップ用カード部品
│
├── _works/                   # 【作品ごとの自己完結ディレクトリ】
│   ├── kit-01/
│   │   ├── index.md          # 作品詳細（Front Matter＋Markdown本文）
│   │   ├── photo.svg         # サンプル基板プレビュー画像
│   │   └── manual.pdf        # サンプル取扱説明書・回路図PDF（実バイナリ）
│   └── kit-02/
│       ├── index.md
│       └── photo.svg
│
├── _events/                  # 【参加イベント・お品書き】
│   └── 2026-11-techbook.md
│
├── assets/
│   ├── css/
│   │   └── style.css         # レスポンシブ対応のスタイルシート
│   └── images/
│       └── images.png
└── README.md                 # 使い方・デプロイ手順書
```
