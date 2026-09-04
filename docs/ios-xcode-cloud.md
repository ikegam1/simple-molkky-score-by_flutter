# Xcode Cloud セットアップ手順 (main push → TestFlight 自動配布)

App Store Connect API Key + Xcode Cloud で、**main branch への push を
きっかけに TestFlight ビルドを自動配布**するパイプラインを構築する手順です。

## 前提と情報

- Apple Developer Program 加入済 (Individual)
- Team ID: `78H6QT2YTT`
- Bundle ID: `com.ikegam1.simple-molkky-score`
- App Store Connect API Key:
  - **Key ID**: `L4LM9463TQ`
  - **Issuer ID**: `6a85e516-5c71-4b70-a4bb-ae08f8c05833`
  - .p8 ファイル: ikegamiさん側でパスワードマネージャ等に安全保管
- 前提の PR (Sign in with Apple + docs/ios-setup.md) がマージ済であること

## 1. リポジトリ側の準備 (この PR で対応)

### `ios/ci_scripts/ci_post_clone.sh`
Xcode Cloud のクリーン VM には Flutter が入っていないので、
このスクリプトが clone 直後に:
- Flutter SDK (`3.41.2`) を `~/flutter` に clone
- `flutter pub get`
- `flutter precache --ios`
- `pod install --deployment` (Podfile.lock 尊重)

**場所**: `ios/ci_scripts/ci_post_clone.sh` (Xcode Cloud が自動検出する固定パス)。
**シェル**: `/bin/sh` + `set -euo pipefail`。

## 2. Xcode Cloud を有効化

### 2-a. App Store Connect 側の準備 (このアプリが存在している必要)
1. まず App Store Connect にアプリを新規登録済であること (別 docs `ios-setup.md` の Step 4 参照)
2. https://appstoreconnect.apple.com/access/api を開く
3. Keys タブ → Team Keys の下、この Key (`L4LM9463TQ`) の Access を「App Manager」以上に (default で App Manager になっている)

### 2-b. Xcode で Workflow を作成
1. `open ios/Runner.xcworkspace`
2. Project navigator で Runner project を選択
3. Report navigator (⌘9) → 上部の **Cloud** タブ
4. 「Get Started」→ App Store Connect にサインイン
5. Team `78H6QT2YTT` を選択
6. **Grant Access to Source Code** → GitHub アカウント連携 → `ikegam1/simple-molkky-score-by_flutter` を選択
7. Workflow 設定:
   - **Name**: `TestFlight (main auto)`
   - **Description**: `main push → TestFlight`
   - **Start Conditions**: Branch Changes → **Branch: `main`** / Changes to any file
   - **Environment**: macOS 14+ / Xcode 15.3+ / **Clean: false** (推奨)
   - **Actions**:
     - **Archive** — Platform: iOS / Deployment Preparation: Prepare for TestFlight and App Store
   - **Post-Actions**:
     - **TestFlight Internal Testing** — Group: Internal Testing (自動で作られる)、Test information: `App Store Connect App Information` から取得
8. 「Save」→ 「Save & Start」で試し打ち

### 2-c. Sign in with Apple + Firebase Auth の対応
Xcode Cloud 側で Runner target の **Sign in with Apple** capability が既に
有効になっていること (`docs/ios-setup.md` Step 3-a で対応済) が前提です。
Xcode Cloud は entitlements ファイルを尊重するので、追加設定不要。

## 3. 動作確認

1. 適当な変更 (README の typo 修正等) を PR → main に merge
2. Xcode Cloud が自動で archive → TestFlight にアップロード
3. TestFlight tab に反映されるまで 10〜15 分
4. 内部テスターの iPhone に通知が届く → インストール

## 4. トラブルシュート

### `ci_post_clone.sh: Permission denied`
`chmod +x` が git 上で保たれているか確認: `git ls-files -s ios/ci_scripts/ci_post_clone.sh` の mode が `100755` になっているか。この PR では `chmod +x` 済。

### Flutter clone に時間がかかる
Xcode Cloud のキャッシュに Flutter を保存する仕組みは無いので、毎回 clone。
`--depth 1` で軽量化しているが 30-60 秒はかかる想定。

### `pod install` で `PhaseScriptExecution failed`
Xcode Cloud のログを見て `xcbeautify` 前の生ログで詳細を確認。よくある原因:
- Podfile 内の `platform :ios, '11.0'` が古すぎる (Firebase 系は iOS 13+ 必須) → `ios/Podfile` の `platform :ios, '13.0'` に更新
- `Runner.xcworkspace` を開いた状態で pod install した際の permissions 不整合 → 一旦 Xcode を閉じる

### TestFlight に届かない (Archive まで成功したのに)
- App Store Connect Users and Access → Integrations → Xcode Cloud で自動的に生成される「Xcode Cloud Service Account」に App Manager 以上の権限があるか確認
- Xcode Cloud の Workflow のログで「Distribution」ステップの詳細を確認

### 「No Team available」
Xcode で Preferences → Accounts に Apple ID を追加してから Report navigator の Cloud タブを再開する。

## 5. 監視 / 通知

- Xcode Cloud は Workflow 結果を **App Store Connect の Xcode Cloud タブ**で確認
- **Slack/Webhook 通知**: Xcode Cloud の Workflow 設定 → Post-Actions で「Notify」を追加可能 (メール / Slack / Webhook)
- ビルド時間の消費: 無料枠 25 時間/月 (Team 全体)、超過は課金 ($14.99/月 で +100 時間、$49.99/月 で +250 時間)。1 ビルド 15-25 分なので、月 60-90 回はいける計算
