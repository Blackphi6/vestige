# Vestige

macOS 用のアプリ完全アンインストーラーです。Apple Silicon ネイティブ (SwiftUI / arm64)。

`/Applications` からアプリを消しても、`~/Library` 配下の設定・キャッシュ・
Homebrew Cask の実体・プライバシー(TCC)権限が残り続けて、アンインストールした
はずのアプリが権限ダイアログなどで亡霊のように出てくることがあります。Vestige は
その残留物をアプリ単位で横断的に検出し、確認のうえで削除します。

## 機能

- `/Applications`・`~/Applications`・Homebrew Cask のインストール済みアプリを一覧表示
- アプリを選ぶと、次のカテゴリを横断スキャン
  - Application Support / Preferences / Caches / HTTPStorages / Containers /
    Saved Application State / WebKit / Logs
  - ユーザー LaunchAgents（システム LaunchAgents/Daemons は検出のみ、削除は対象外）
  - Homebrew Cask 本体（`brew uninstall --zap`）と、Cask 自身が定義する `zap` 削除リスト
  - プライバシー権限 (TCC) のリセット（Accessibility など、オプトイン）
  - 上記で拾いきれない残留物は Spotlight (`mdfind`) で保険的に検索
- 削除前に確認ダイアログ、デフォルトはゴミ箱に移動（完全削除も選択可）
- 既知のカテゴリ以外は削除対象にならないホワイトリスト方式

## インストール

1. [Releases](../../releases) から最新の `Vestige-*.zip` をダウンロードして展開
2. `Vestige.app` を `/Applications` に移動
3. 初回起動時に「開発元を確認できません」と表示された場合（Apple Developer
   Program 未加入の ad-hoc 署名のため）:
   - Finder で `Vestige.app` を **右クリック → 開く** → ダイアログで「開く」

## 使い方

1. サイドバーからアンインストールしたいアプリを選択
2. 自動でスキャンが走り、カテゴリ別に残留物候補が表示される
3. 不要な項目のチェックを外し、「削除」→ 確認ダイアログで実行

一部のパス（`~/Library/Containers/<bundle-id>` など、macOS がアプリごとに
サンドボックス管理している領域）は、システム設定 > プライバシーとセキュリティ >
**フルディスクアクセス** で Vestige を許可しないと削除できない場合があります。
エラーが出た場合はそちらを確認してください。

## 安全性について

- 削除対象は上記の既知カテゴリのみで、任意のパスを削除する機能はありません
- root 権限が必要な `/Library/LaunchAgents`・`/Library/LaunchDaemons` は検出して
  警告表示するだけで、削除は行いません（手動確認を推奨）
- 実行は必ず確認ダイアログを経由し、デフォルトはゴミ箱移動（取り消し可能）

**自己責任でご利用ください。** 誤った削除によるデータ損失について作者は責任を
負いません。

## 開発者向け: ビルド

```bash
brew install xcodegen
./Scripts/build-release.sh
```

`dist/Vestige-<version>-macos-arm64.zip` が生成されます。テストは:

```bash
xcodegen generate
xcodebuild -project Vestige.xcodeproj -scheme Vestige -destination 'platform=macOS,arch=arm64' test
```

## ライセンス

MIT License. [LICENSE](LICENSE) を参照してください。
