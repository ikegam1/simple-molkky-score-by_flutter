# iOS ビルド / App Store 提出セットアップ手順

このドキュメントは、Easy Molkky Score を **App Store に提出できる状態にする**
ための Apple / Firebase / Xcode 側のセットアップ手順をまとめたものです。
コード側 (Sign in with Apple の Flutter 実装、`ios/Runner/Runner.entitlements`
の追加) は PR で完了しているので、ここに書かれているのは
「Apple / Firebase Console / Xcode で手で行う作業」だけです。

## 前提

- Apple Developer Program 加入済 (Individual)
- Team ID: `78H6QT2YTT`
- Bundle ID: `com.ikegam1.simple-molkky-score`

---

## 1. Apple Developer Portal 側の準備

### 1-a. App ID を作成 + Sign in with Apple capability を有効化

1. https://developer.apple.com/account/resources/identifiers/list を開く
2. 左サイドバー「Identifiers」→ 「+」ボタン
3. 「App IDs」→「App」を選択、Continue
4. Description: `Easy Molkky Score` / Bundle ID: **`com.ikegam1.simple-molkky-score`** (Explicit)
5. Capabilities で **Sign In with Apple** にチェック → Continue → Register

### 1-b. Services ID を作成 (Web/Android の web-based flow 用)

Sign in with Apple を **iOS 以外** (Web / Android) でも動かすために必要。
iOS だけで良い場合はスキップ可能ですが、Web 版 (`flutter build web` で
Firebase Hosting にデプロイする pipeline) がある場合は必須。

1. Identifiers → 「+」→ **Services IDs** → Continue
2. Description: `Easy Molkky Score Web` / Identifier: **`com.ikegam1.simple-molkky-score.web`**
3. Register 後、作成した Services ID をクリック
4. Sign In with Apple にチェック → **Configure**
5. Primary App ID: 1-a で作った `com.ikegam1.simple-molkky-score`
6. Domains and Subdomains: `simple-molkky-score.firebaseapp.com`
7. Return URLs: `https://simple-molkky-score.firebaseapp.com/__/auth/handler`
8. Save → Continue → Save

### 1-c. Sign in with Apple 用の Private Key を発行

Firebase Auth が Apple の identity token を検証するために必要。

1. サイドバー「Keys」→「+」
2. Key Name: `Sign in with Apple key`
3. **Sign in with Apple** にチェック → **Configure**
4. Primary App ID: `com.ikegam1.simple-molkky-score` → Save
5. Continue → Register
6. **`.p8` ファイルをダウンロード** (再ダウンロード不可、安全に保管)
7. **Key ID** (10文字英数、例: `ABC123DEFG`) を控える

---

## 2. Firebase Console → Authentication に Apple を追加

1. https://console.firebase.google.com/project/simple-molkky-score/authentication/providers
2. 「Sign-in method」タブ → **Apple** をクリック
3. 「Enable」をトグル
4. Services ID: 1-b で作った **`com.ikegam1.simple-molkky-score.web`**
5. OAuth code flow (下記全て入力):
   - Apple Team ID: **`78H6QT2YTT`**
   - Key ID: 1-c で控えた Key ID
   - Private key: 1-c でダウンロードした `.p8` ファイルの内容を貼り付け
6. Save

---

## 3. Xcode 側の準備

### 3-a. Runner.entitlements を Xcode プロジェクトに登録

PR で `ios/Runner/Runner.entitlements` は作成済みですが、Xcode プロジェクト
の Runner target と関連付ける必要があります。

1. `open ios/Runner.xcworkspace` で Xcode を開く
2. 左サイドバーで **Runner** プロジェクト → **Runner** target を選択
3. **Signing & Capabilities** タブ
4. **Team** ドロップダウンで自分の Apple Developer Team (`78H6QT2YTT`) を選択
5. **+ Capability** ボタンをクリック → **Sign in with Apple** を追加
   - これで `Runner.entitlements` が自動的にプロジェクトに紐付き、target の
     `Code Signing Entitlements` に `Runner/Runner.entitlements` が入る
6. Bundle Identifier が **`com.ikegam1.simple-molkky-score`** になっていることを確認
   (`.RunnerTests` は別 target なので触らない)

### 3-b. 実機で動作確認 (推奨)

シミュレータでは Apple ID ダイアログが出ないので、実 iPhone/iPad で試すのが
確実です。

1. iPhone を Mac に接続 → Xcode のデバイス選択で実機を選ぶ
2. `flutter run --release` (または Xcode Run ボタン)
3. アプリで人型アイコン → 「Appleでログイン」→ ダイアログが出て認証できるか確認

---

## 4. App Store Connect でアプリ登録

1. https://appstoreconnect.apple.com/apps
2. 「マイ App」→「+」→ **新規 App**
3. プラットフォーム: iOS / Name: Easy Molkky Score / Primary Language: 日本語
4. Bundle ID: `com.ikegam1.simple-molkky-score` (1-a で登録済のものが選択肢に出る)
5. SKU: `easy-molkky-score-ios` 等 (任意の一意 ID)
6. Continue → 各種メタデータ (説明文、キーワード、スクショ、アイコン等) を入力
7. Age Rating: 4+ (暴力・成人向け無し)
8. Category: Sports (primary) / Entertainment (secondary)

---

## 5. iOS Build + TestFlight アップロード

```bash
# .ipa を作成 (Xcode の Team 選択が完了している前提)
flutter build ipa --release

# 生成物: build/ios/ipa/*.ipa
# Transporter.app (Mac App Store) で App Store Connect にアップロード
open -a Transporter build/ios/ipa/*.ipa
```

アップロード後、App Store Connect の TestFlight タブに反映されるまで数分〜
15分ほどかかります。反映後、内部テスターグループを作って自分のメアドを
追加 → メールで TestFlight リンクが届く → iPhone の TestFlight app で
インストール可能。

---

## 6. 審査提出

1. App Store Connect → 対象 App → **App Store** タブ → 準備中のバージョン
2. スクリーンショット / 説明文 / What's New in This Version 等を入力
3. **App Privacy** セクション: 使っているデータ (アカウント作成のためのメール、
   Firebase Auth の UID 等) を宣言
4. Age Rating / Copyright / Sign-In Information (テスト用アカウント) を入力
5. Build を選択 (TestFlight にアップロードした build)
6. Submit for Review

通常 24〜48 時間で審査結果。よくある却下理由:

- **Sign in with Apple 未提供** ← このドキュメントで対応済
- Privacy Policy URL が機能しない
- Login demo アカウント / test 手順の記載不足 (匿名でも遊べるのでその旨を明記すれば OK)
- Data Deletion (アカウント削除) 機能が無い ← 既に実装済

---

## トラブルシュート

### Xcode で "No account for team 78H6QT2YTT" と出る

Xcode → Preferences → Accounts で Apple ID を追加 (Apple Developer 加入時と
同じ Apple ID)。

### `flutter build ipa` で `The identity used to sign the executable is no longer valid`

Xcode で Runner を開き、Signing & Capabilities の Team を再度選び直し、
"Automatically manage signing" を ON にする。

### Sign in with Apple ボタンをタップしても何も起きない (シミュレータ)

Sign in with Apple はシミュレータで動作しないことがあります。実機で確認して
ください。

### 「Invalid client_id」エラー (Web の Apple 経路)

Services ID (`com.ikegam1.simple-molkky-score.web`) と Firebase Console の
設定が一致しているか、Return URL が Firebase Hosting のドメインと一致するか
再確認してください。
