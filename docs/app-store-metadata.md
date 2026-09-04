# App Store Connect メタデータ (草案)

App Store 審査提出時に App Store Connect に入力するメタデータの草案です。
ikegamiさんがレビューして OK なら、私が App Store Connect API 経由で
一括反映します (`.p8` 経由の自動化)。

## 1. アプリ基本情報

| 項目 | 値 |
|---|---|
| App Name | Easy Molkky Score |
| Subtitle (副題) | モルック用スコア管理・戦績記録 |
| Bundle ID | `com.ikegam1.simple-molkky-score` |
| SKU | (App Store Connect 登録済み) |
| Primary Language | 日本語 (Japanese) |
| Category (Primary) | Sports |
| Category (Secondary) | Entertainment |
| Age Rating | 4+ |

## 2. 説明文 (Description)

### 日本語 (4000 字以内)

```
モルック (Mölkky) の試合スコアを、直感的なタップだけで正確に記録できる
無料スコア管理アプリです。フィンランド発祥のスポーツ「モルック」の複雑な
ルール (50点ピッタリ / 25点戻し / 3回連続ミスで失格 / サバイバル) を全部
自動で判定するので、ゲーム進行に集中できます。

■ 主な機能
・最大 8 人までの試合形式に対応 (1 vs 1 / 4 対戦 / 総当たり / 3 ゲーム)
・50点到達 / 25点戻し / 3ミス失格の自動判定
・獲得セット数の追跡 (1、2、10 セット固定モード)
・サバイバルルール (多人数戦で失格者をスキップ、最後の 1 人で終了)
・投擲順のシャッフル (ルーレット演出でランダム化)
・プレイ履歴の永続保存 (端末内 + Firebase 同期でクラウドバックアップ)
・「戦績」画面で過去の全試合を振り返り可能
・37点ルール、セルフ 5T / 6T モード、百均モード対応

■ こんな人におすすめ
・モルック大会や仲間内での試合スコア記録に
・複雑なルールを覚えたばかりで自動判定してほしい方
・過去の試合戦績を見返したい方
・タブレット / スマホでかんたんに管理したい方

■ ログイン
・匿名 (サインイン不要) でも全機能利用可能
・Google または Apple サインインで戦績データを他デバイスと同期
・「アカウント削除」でいつでも全データを削除可能

■ 対応環境
・iPhone / iPad
・iOS 15.0 以降

このアプリはコミュニティ有志が個人開発したもので、公式のモルック連盟
とは無関係です。バグ報告・機能要望は開発者連絡先までお願いします。
```

### 英語 (4000 字以内)

```
Easy Molkky Score is a free scoreboard app for Mölkky, the Finnish
outdoor throwing game. Complex rules — reaching exactly 50 points,
dropping to 25 on overshoots, disqualification after three consecutive
misses, and survivor mode — are handled automatically so you can focus
on the game.

■ Features
・Supports 1v1, team battles, round-robin, and 3-game tournaments
  (up to 8 players)
・Automatic scoring: exact-50 check, 25-point reset on overshoot,
  three-miss disqualification
・Set tracking (1, 2, or 10 set fixed modes)
・Survivor mode: skipped-turn handling for disqualified players
・Throw order shuffler with roulette animation
・Persistent match history (local + optional Firebase sync)
・Full match history browser
・Support for 37-point rule, Self-5T / Self-6T solo modes, and
  100-yen shop mode

■ Best for
・Recording scores at Mölkky tournaments or friendly matches
・New players who want automatic rule enforcement
・Reviewing past match history
・Quick, phone-friendly scoreboard operation

■ Sign-in
・Fully usable without signing in (anonymous mode)
・Sign in with Google or Apple to sync history across devices
・Delete-account feature erases all your data whenever you want

■ Requirements
・iPhone / iPad
・iOS 15.0 or later

This app is a community-developed project and is not affiliated
with any official Mölkky federation.
```

## 3. Keywords (100 字以内、カンマ区切り、日本語 30 字/英語 100 字目安)

### 日本語
```
モルック,モルックスコア,モルックアプリ,モルック大会,スコアボード,得点計算,モルック計算,Molkky
```

### 英語
```
molkky,molkky score,molkky app,scoreboard,mölkky,score calculator,finnish sport,outdoor game
```

## 4. Promotional Text (170 字、What's New と別で更新可能)

### 日本語 (170 字)
```
モルックの複雑なルール (50点ピッタリ / 25点戻し / 3ミス失格 / サバイバル) を全自動で判定。最大 8 人・4 種類の試合形式に対応。匿名利用も可能で、Google / Apple ID でログインすれば戦績を複数端末で同期できます。
```

### 英語 (170 字)
```
Mölkky scoreboard app with full automatic rule handling: exact-50 win, 25-point reset, three-miss disqualification, and survivor mode. Up to 8 players and 4 tournament formats. Works anonymously; optional Google / Apple sign-in syncs history.
```

## 5. What's New in This Version (4000 字、初版なのでシンプルに)

### 日本語
```
初回リリースです。App Store デビューにあたり、iPhone / iPad の縦横両方に対応、Sign in with Apple にも対応しました。ご意見・不具合報告は開発者連絡先までお願いします。
```

### 英語
```
Initial App Store release. Supports both portrait and landscape orientation on iPhone / iPad, and includes Sign in with Apple. Feedback and bug reports welcome via the developer contact.
```

## 6. URL

| 項目 | URL |
|---|---|
| **Marketing URL** | https://ikegam1.github.io/simple-molkky-score-by_flutter/ (Web 版) |
| **Support URL** | https://github.com/ikegam1/simple-molkky-score-by_flutter/issues |
| **Privacy Policy URL** | https://ikegam1.github.io/simple-molkky-score-by_flutter/#/legal-ja (要確認、実際の URL に合わせる) |

## 7. App Review Information

### Sign-In Information
```
このアプリは匿名利用が可能で、テスト用アカウントは不要です。
起動して「ゲーム開始」を押すだけで全機能をお試しいただけます。

Sign in with Apple / Google Sign-In は「戦績データの同期」用の任意機能で、
未サインインでも試合の記録 + 履歴閲覧はすべて動作します。
```

### Contact Information
```
Name: [ikegami]
Email: [ikegam1 の連絡先メール]
Phone: [連絡可能な電話番号 — App Store 審査でのみ使用]
```

### Notes for Reviewer (英語、審査チームは US 側なので英語推奨)
```
Easy Molkky Score is a scoreboard app for Mölkky, a Finnish outdoor
throwing game. Reviewer notes:

1. NO SIGN-IN REQUIRED: The app is fully functional in anonymous
   (guest) mode. Tap "Start Match" (ゲーム開始) after adding player
   names to begin. All match rules are enforced automatically.

2. SIGN IN WITH APPLE: We provide Apple ID sign-in via
   AppleAuthProvider (Firebase Auth) alongside Google Sign-In,
   fulfilling Guideline 4.8. Both sign-in methods are optional; they
   only enable cross-device history sync.

3. DATA DELETION: Users can delete all their data via
   Settings → Account → "Delete Account" (アカウント削除).
   Documented at Privacy Policy URL.

4. NO IN-APP PURCHASES / SUBSCRIPTIONS in this version.

5. PRIVACY: The app uses Firebase Auth for authentication and
   Firestore for optional match history sync. See attached App
   Privacy declaration.

Test suggestions:
- Add 2+ player names → "ゲーム開始" → tap score buttons (1-9, 0=miss)
- Try three consecutive misses → auto-disqualification
- Try Sign in with Apple button (人型 icon at top) — should succeed
- Try Delete Account flow

Thank you for reviewing!
```

## 8. App Privacy (Data Collection 宣言)

App Store Connect の「App Privacy」セクションで宣言する内容:

### 収集するデータ
| データ種別 | 用途 | ユーザー識別に紐付き? | トラッキング? |
|---|---|---|---|
| **Email Address** | Account Management (Firebase Auth) | Yes | No |
| **Name** | Account Management (Firebase Auth, optional from Apple/Google) | Yes | No |
| **User ID** | Account Management (Firebase Auth UID) | Yes | No |
| **Product Interaction** | App Functionality (match records) | Yes (only when signed in) | No |
| **Crash Data** | App Functionality (Firebase Crashlytics 未導入なら削除) | No | No |
| **Performance Data** | App Functionality (Firebase Performance 未導入なら削除) | No | No |

**Tracking (トラッキング) は使用しない** (`ATT` フレームワーク不要)。

### データ最小化の説明
- 匿名モードでは Firebase Auth UID (デバイス毎の匿名 ID) のみ発行、他データ収集なし
- Google/Apple サインイン時のみ email + display name を Firebase Auth に保存
- 試合データ (プレイヤー名、スコア、日時) は Firebase Auth UID をキーに Firestore に保存
- 「アカウント削除」で全データを完全消去 (Firebase Auth user 削除 + Firestore の該当 uid docs 削除)

## 9. Age Rating (レーティング詳細)

すべて **なし (None)** を選択:
- Cartoon or Fantasy Violence
- Realistic Violence
- Sexual Content or Nudity
- Profanity or Crude Humor
- Alcohol, Tobacco, or Drug Use or References
- Mature/Suggestive Themes
- Horror/Fear Themes
- Prolonged Graphic or Sadistic Realistic Violence
- Gambling
- Unrestricted Web Access
- Gambling and Contests

結果: **4+**

## 10. スクリーンショット仕様

以下解像度で **各 2〜10 枚**必要 (最低 2 枚推奨):

| デバイス | 解像度 | 必須 |
|---|---|---|
| iPhone 6.7" Display (14/15/16 Pro Max, 15 Plus 等) | 1290 × 2796 px | 必須 |
| iPhone 6.5" Display (11 Pro Max, XS Max 等) | 1242 × 2688 px | 必須 |
| iPhone 5.5" Display (8 Plus 等) | 1242 × 2208 px | 必須 |
| iPad Pro 12.9" (2nd gen) | 2048 × 2732 px | 必須 (Universal app なので) |
| iPad Pro 12.9" (6th gen) | 2048 × 2732 px | 推奨 |

### 撮影推奨シーン (2 枚以上)
1. **メイン画面** (プレイヤー登録画面、Easy Molkky Score タイトル + プレイヤー名入力)
2. **試合中画面** (スコア入力ボタン + 現在得点表示)
3. **試合終了ダイアログ** (結果表示、勝者ハイライト)
4. (任意) 戦績画面
5. (任意) 高度な設定画面

## 11. App Store Icon

`ios/Runner/Assets.xcassets/AppIcon.appiconset/` の 1024×1024 px アイコンを
使う。Xcode で管理されているのでアップロードは自動。

---

## 私 (@claude君) が API で自動反映できる項目

- ✅ 1. アプリ基本情報 (name / subtitle / category)
- ✅ 2. 説明文 (description) 日/英
- ✅ 3. Keywords 日/英
- ✅ 4. Promotional Text 日/英
- ✅ 5. What's New
- ✅ 6. URL 3 種
- ✅ 7. App Review Information (Sign-In Info / Contact / Notes)
- ✅ 8. App Privacy 宣言 (Data Collection)
- ✅ 9. Age Rating

## ikegamiさん手動作業

- ❌ 10. スクリーンショット撮影 → 私が API でアップロード可
- ❌ 11. Xcode Cloud ビルド完了 → TestFlight 反映
- ❌ **Submit for Review ボタン押下** (最終承認は人間)

---

## 承認いただきたい確認事項

1. **説明文 (日/英)** の内容 OK か? 追加/削除したい機能あるか?
2. **キーワード** に追加したい単語ある? (例: 大会名、地域名)
3. **サポート URL** = GitHub Issues で OK か? 別のフォーム希望なら教えて
4. **プライバシーポリシー URL** = Web 版の legal ページで OK か? 別ドメイン?
5. **開発者連絡先** (Email / Phone) — 私からは分からないので教えてください
6. **App Privacy 宣言** で Firebase Crashlytics / Performance は使用してますか? (使用なら Crash Data / Performance Data も宣言)
