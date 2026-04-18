# PromptLore

CLAUDE.md と skills を手軽に共有できる、Claude Code 向けの SNS 型プラットフォーム。
非エンジニアでもファイルをコピペするだけで使い始められる設計を目指しました。

**Live:** https://promptlore.fly.dev/

---

## 1. 概要

Claude Code は非エンジニアを含む幅広い層で使われ始めていますが、本来の力を引き出す `CLAUDE.md` や `skills` は、GitHub での fork / ブランチ運用が前提のものが多く、導入ハードルが高いのが現状です。
エンジニアにとっても「どの CLAUDE.md / skills を使うべきか分からない」という選択コストがあります。

PromptLore は、この 2 つの課題を同時に解決する **CLAUDE.md / skills 共有 SNS** です。

- **非エンジニア**：コピペだけで Claude Code のカスタマイズを始められる
- **エンジニア**：他人の実践的な設定を素早く試し、自分の設定もバージョン管理しながら共有できる

## 2. 主要機能

| 機能 | 内容 |
|---|---|
| **アップロード** | ファイルを選択するだけで `CLAUDE.md` / `skills` を自動判別。バージョン履歴を最大 5 件保存。Public / Private を切替可能 |
| **ダウンロード** | コピペするだけで即使用できる UI。コピペ後の配置手順も明記。WEB 版 Claude Code・ローカル版 Claude Code の両方に対応 |
| **プリセット** | `CLAUDE.md` と `skills` の抱き合わせリポジトリを一括アップロード／ダウンロード |
| **高評価 / Official** | Like によるモチベーション設計と、管理者検証済みリポジトリへの Official バッジ付与 |
| **検索** | キーワード・タグ・カテゴリによる横断検索 |
| **アカウント** | Devise によるメール＋パスワード認証。ユーザー名・アイコン設定可能 |

## 3. 技術スタック

- **言語 / フレームワーク**：Ruby 3.4.9 / Ruby on Rails 8.1
- **データベース**：SQLite
- **バックエンド周辺**：Solid Cache / Solid Queue / Solid Cable（Rails 8 Solid Trifecta）
- **フロントエンド**：Hotwire（Turbo / Stimulus） / Propshaft / Importmap
- **認証**：Devise
- **ファイル**：ActiveStorage + image_processing
- **Markdown**：Redcarpet + Rouge（プレビュー＆シンタックスハイライト）
- **ページング**：Pagy
- **セキュリティ**：Rack::Attack / Brakeman / bundler-audit
- **デプロイ**：Kamal + Docker + Fly.io
- **テスト**：Capybara + Selenium WebDriver

## 4. データモデル（主要）

- `User`（Devise）
- `Repository` — `CLAUDE.md` または `skills` を表すエンティティ。`file_type`（claude_md / skill）、`visibility`（public / private）、`official` フラグを持つ
- `RepositoryVersion` — バージョン履歴（最大 5 件）
- `Preset` / `PresetItem` / `PresetVersion` — `CLAUDE.md` と `skills` の組み合わせ
- `Tag` / `Category` — 横断検索用
- `Like` / `PresetLike` — 高評価

## 5. セットアップ

```bash
# Ruby 3.4.9 が必要
bundle install

# DB とシード投入
bin/rails db:prepare

# 開発サーバー起動
bin/dev
```

ブラウザで http://localhost:3000 にアクセス。

## 6. デプロイ

Kamal + Fly.io を使用しています。

```bash
bin/kamal deploy
```

詳細は `config/deploy.yml` および `fly.toml` を参照。

## 7. 今後の課題

- 豊富な CLAUDE.md / skills のシード投入（キラーコンテンツの拡充）
- CSS リファクタによるデザイン性の向上
- **API 連携による完全自動配布**：コピペ作業を廃し、Claude Code と直接連携して CLAUDE.md / skills を自動反映する
- 動作テストの整備（モデル / システムテスト）
- ユーザー獲得・コミュニティ形成

## 8. ライセンス

MIT License
