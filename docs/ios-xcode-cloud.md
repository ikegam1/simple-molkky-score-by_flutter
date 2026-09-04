# Xcode Cloud セットアップ手順 (main push → TestFlight 自動配布)

App Store Connect API Key + Xcode Cloud で、**main branch への push を
きっかけに TestFlight ビルドを自動配布**するパイプラインを構築する手順です。

## 前提と情報

- Apple Developer Program 加入済 (Individual)
- Team ID: `<YOUR_TEAM_ID>` (公開ドキュメントではマスク)
- Bundle ID: `com.ikegam1.simple-molkky-score`
- App Store Connect API Key:
  - **Key ID**: `<YOUR_APP_STORE_CONNECT_KEY_ID>` (公開ドキュメントではマスク)
  - **Issuer ID**: `<YOUR_APP_STORE_CONNECT_ISSUER_ID>` (公開ドキュメントではマスク)
  - .p8 ファイル: ikegamiさん側でパスワードマネージャ等に安全保管
- 前提の PR (Sign in with Apple + docs/ios-setup.md) がマージ済であること

---

## 全体像: Phase 1〜4 の作業順序

iOS 版 App Store リリースまでの作業を **4 フェーズ**に整理しています。
Phase 1〜2 は **ikegamiさんの手動作業** (ブラウザ + Xcode)、Phase 3 は
Xcode Cloud 自体のセットアップ、Phase 4 はマージ後の自動化フローと初回審査です。

| Phase | 内容 | 作業場所 | 目安時間 | 詳細 |
|---|---|---|---|---|
| **1** | Apple Developer Portal + Firebase Console | ブラウザ | 30〜45 分 | `docs/ios-setup.md` §1-2 |
| **2** | Xcode 設定 + App Store Connect アプリ登録 | Xcode.app + ブラウザ | 20〜30 分 | `docs/ios-setup.md` §3-4 + 本ドキュメント §2-a |
| **3** | Xcode Cloud Workflow 設定 | Xcode.app | 15〜20 分 | 本ドキュメント §2-b, 2-c |
| **4** | 動作確認 → 内部テスト → App Store 審査 | Xcode Cloud + iPhone + ブラウザ | 数日 | 本ドキュメント §3 + `docs/ios-setup.md` §6 |

**重要**: Phase 1 と 2 は Xcode Cloud では自動化できません (Apple / Firebase
の管理画面での手作業が必要)。Phase 3 の Xcode Cloud 設定は Phase 1〜2 が
完了していないと Workflow 実行時にエラーになるので、順番を守ってください。

### Phase 1: Apple Developer Portal + Firebase Console (30〜45 分)

- **場所**: https://developer.apple.com/account + https://console.firebase.google.com
- **やること**: App ID 作成 + Sign in with Apple 有効化 → Services ID → Private Key (.p8) → Firebase Console の Apple provider 設定
- **成果物**: `.p8` ファイル (再ダウンロード不可、安全保管必須) + Key ID (10文字英数)
- **詳細手順**: [`docs/ios-setup.md` §1-2](./ios-setup.md#1-apple-developer-portal-側の準備) を上から順にこなす

### Phase 2: Xcode 設定 + App Store Connect アプリ登録 (20〜30 分)

- **場所**: `open ios/Runner.xcworkspace` (Mac Xcode.app) + https://appstoreconnect.apple.com
- **やること**:
  1. Xcode で Team 選択 + Sign In with Apple Capability 追加 (差分を PR コミットしておく)
  2. **iOS 実機で `flutter run --release`** で Apple サインインが動くか確認
  3. App Store Connect でアプリレコード新規作成 (Bundle ID / SKU / カテゴリ)
  4. (推奨) App Store Connect API Key (`<YOUR_APP_STORE_CONNECT_KEY_ID>`) の Access を「App Manager」以上に設定 (default で OK なはず、後述 §2-a 参照)
- **詳細手順**: [`docs/ios-setup.md` §3-4](./ios-setup.md#3-xcode-側の準備) + 本ドキュメント §2-a

### Phase 3: Xcode Cloud Workflow 設定 (15〜20 分)

- **場所**: Xcode.app (Report Navigator ⌘9 → Cloud タブ)
- **やること**: GitHub アカウント連携 → Workflow (`TestFlight (main auto)`) を作成 → 「Save & Start」で初回試し打ち
- **詳細手順**: 本ドキュメント §2-b (下記)
- **成果物**: main push で自動的に Xcode Cloud が動く状態

### Phase 4: 動作確認 → 内部テスト → App Store 審査 (数日)

- **場所**: Xcode Cloud (App Store Connect 内タブ) + iPhone (TestFlight app) + App Store Connect (App Store タブ)
- **やること**:
  1. main に空コミット or 軽い変更を push → Xcode Cloud が Archive → TestFlight にアップロード確認 (10〜15 分)
  2. TestFlight app で自分の iPhone にインストール → Sign in with Apple / Google Sign-In / スコア入力 / Firebase 同期を全部触って動作確認
  3. スクリーンショット (6.7"/6.5"/5.5", iPad 12.9") を撮って App Store Connect にアップロード
  4. App Privacy / レビュー用ノートを入力
  5. **Submit for Review** → 通常 24〜72h で結果
- **詳細手順**: 本ドキュメント §3 + [`docs/ios-setup.md` §6](./ios-setup.md#6-審査提出)

## 1. リポジトリ側の準備 (この PR で対応済 = 追加作業なし)

### `ios/ci_scripts/ci_post_clone.sh`
Xcode Cloud のクリーン VM には Flutter が入っていないので、
このスクリプトが clone 直後に:
- Flutter SDK (`3.41.2`) を `~/flutter` に clone
- `flutter pub get`
- `flutter precache --ios`
- `pod install --deployment` (Podfile.lock 尊重)

**場所**: `ios/ci_scripts/ci_post_clone.sh` (Xcode Cloud が自動検出する固定パス)。
**シェル**: `/bin/sh` + `set -euo pipefail`。

> **Phase 3 の準備段階**: このファイルはリポジトリに既にコミット済 (PR #203)
> なので、ikegamiさん側での追加操作は不要です。Xcode Cloud の Workflow が
> 初回実行時に自動検出します。

## 2. Xcode Cloud を有効化 (Phase 3)

### 2-a. App Store Connect 側の準備 (Phase 2 完了が前提)

以下は Phase 2 で完了しているはずですが、Phase 3 に入る前に再確認します:

1. App Store Connect にアプリレコードが新規登録済であること (`docs/ios-setup.md` §4)
   - 登録済でないと Xcode Cloud の Workflow 保存時に「アプリが見つからない」エラー
2. https://appstoreconnect.apple.com/access/api を開く
3. Keys タブ → Team Keys の下、対象の Key (`<YOUR_APP_STORE_CONNECT_KEY_ID>`) の Access を「App Manager」以上に (default で App Manager になっている)
4. ikegamiさん自身の Apple ID が App Store Connect の Users and Access に「Admin」または「App Manager」で登録されていること (Individual アカウントなら自動でオーナー)

### 2-b. Xcode で Workflow を作成 (Phase 3 メイン作業)
1. `open ios/Runner.xcworkspace`
2. Project navigator で Runner project を選択
3. Report navigator (⌘9) → 上部の **Cloud** タブ
4. 「Get Started」→ App Store Connect にサインイン
5. Team `<YOUR_TEAM_ID>` を選択
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
有効になっていること (Phase 2 = `docs/ios-setup.md` §3-a で対応済み) が前提です。
Xcode Cloud は entitlements ファイルを尊重するので、追加設定不要。

## 3. 動作確認 (Phase 4)

Phase 3 の Workflow が「Save & Start」で初回試し打ちを成功させた後は、
以下が自動フローで回るようになります:

1. 適当な変更 (README の typo 修正等) を PR → main に merge
2. Xcode Cloud が自動で archive → TestFlight にアップロード
3. TestFlight tab に反映されるまで 10〜15 分
4. 内部テスターの iPhone に通知が届く → インストール

### Phase 4 の推奨動作確認チェックリスト

初回 TestFlight ビルドで実機確認する項目:

- [ ] アプリが起動する (splash → main 画面)
- [ ] 匿名 (未サインイン) 状態でスコア入力ができる
- [ ] Google Sign-In できる (アカウント選択 → Firebase Auth 連携完了)
- [ ] **Sign in with Apple ができる (Guideline 4.8 の要件、審査で必ずチェックされる)**
- [ ] Firebase Firestore への試合結果同期が動く (再ログインで履歴が復元)
- [ ] アカウント削除フロー (「アカウント削除」→ 確認 → 完了) が動く
- [ ] プライバシーポリシー / 利用規約リンクが機能する
- [ ] iPad で表示崩れがない (Universal app なので iPad でも通る)

### 審査提出まで

Phase 4 の最終ステップは App Store 審査提出です。詳細手順は
[`docs/ios-setup.md` §6](./ios-setup.md#6-審査提出) を参照してください。
主なチェックポイント:

- スクリーンショット (iPhone 6.7"/6.5"/5.5", iPad 12.9" 必須)
- App Privacy: Firebase Auth / Firestore で扱うデータの宣言
- レビュー用ノート: 「モルック (フィンランド発祥のスポーツ) スコア管理アプリ、
  匿名で遊べる」旨を明記 (テストアカウント不要と伝える)
- Sign in with Apple 提供の申告 (App Store Connect のバージョン情報)

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

---

## Appendix: Phase 別チェックリスト

Phase を進める前後で「これができていれば次に進んで OK」の判定用チェックリストです。

### Phase 1 完了判定 ✅

- [ ] Apple Developer Portal で App ID `com.ikegam1.simple-molkky-score` が作成されている
- [ ] App ID の Capabilities に「Sign In with Apple」チェックが入っている
- [ ] Services ID `com.ikegam1.simple-molkky-score.web` が作成され、Return URLs に `https://simple-molkky-score.firebaseapp.com/__/auth/handler` が登録済
- [ ] Sign in with Apple 用 Key を作成、`.p8` ファイルをダウンロード済 (再ダウンロード不可なので必ず安全保管)
- [ ] Key ID (10文字英数) を控え済
- [ ] Firebase Console → Authentication → Sign-in method で Apple provider を有効化済
- [ ] Firebase Console に Services ID / Team ID / Key ID / `.p8` の内容を貼り付け保存済

### Phase 2 完了判定 ✅

- [ ] `open ios/Runner.xcworkspace` を実行して Xcode で Runner project を開いた
- [ ] Signing & Capabilities → Team に `<YOUR_TEAM_ID>` を選択済 (Automatic Signing)
- [ ] 「+ Capability」で「Sign In with Apple」を追加、`Runner/Runner.entitlements` が Code Signing Entitlements に紐付いた
- [ ] Bundle Identifier が `com.ikegam1.simple-molkky-score` になっている
- [ ] iPhone 実機で `flutter run --release` して Sign in with Apple が動作した (シミュレータでは動かないので注意)
- [ ] App Store Connect でアプリレコード新規作成 (Bundle ID / SKU / 日本語名 / カテゴリ Sports)
- [ ] Xcode 側の変更差分を PR にコミット済 (Xcode Cloud も同じ差分を使うので必須)

### Phase 3 完了判定 ✅

- [ ] Xcode → Report Navigator (⌘9) → Cloud タブから「Get Started」できた
- [ ] App Store Connect にサインイン + Team `<YOUR_TEAM_ID>` を選択できた
- [ ] GitHub アカウント連携 + `ikegam1/simple-molkky-score-by_flutter` の Grant Access 完了
- [ ] Workflow `TestFlight (main auto)` を作成、「Save & Start」で初回ビルドをキックできた
- [ ] 初回ビルドが「Archive」ステップまで進んだ (エラーが出た場合は §4 トラブルシュートを参照)
- [ ] TestFlight タブにビルド番号が反映された (10〜15 分待つ)

### Phase 4 完了判定 ✅

- [ ] 自分の iPhone に TestFlight app 経由でビルドをインストールできた
- [ ] §3 動作確認チェックリストの全項目が通った
- [ ] スクリーンショット (必要な全解像度) を App Store Connect にアップロード済
- [ ] App Privacy 設定完了
- [ ] レビュー用ノート入力完了
- [ ] Submit for Review ボタンを押した
- [ ] 24〜72h 後、App Store Connect でステータスが「Ready for Sale」または「In Review → Approved」になった
- [ ] App Store 公開 URL を Discord / 関係者に共有した 🎉
