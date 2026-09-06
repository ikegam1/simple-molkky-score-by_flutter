# App Store 審査 Guideline 2.1 追加情報要求への回答 (英語草案)

**却下 (Rejected)** ではなく、**新規デベロッパー向けの追加情報要求**。以下 6 項目
に回答することでほぼ確実に承認されます。

App Store Connect の対象バージョン → **App Review** タブ → 「Reviewer に返信」
または「App Review Information」の Notes 欄に貼り付けてください。

---

## 英語回答文案 (そのまま貼り付け OK)

```
Thank you for reviewing our submission. Below is the information requested.

===============================
1. SCREEN RECORDING
===============================
A screen recording (mp4) has been uploaded separately via App Store Connect.
It demonstrates the following user flows:
- Launch of the app (portrait, iPhone)
- Adding player names and starting a match
- Entering scores using the on-screen numeric buttons
- Automatic 50-point win detection and 25-point overshoot reset
- Match completion dialog
- Anonymous sign-in (default, no account required)
- Optional Sign in with Apple / Google Sign-In from the account icon
- Account deletion via Settings → Delete Account → confirmation

===============================
2. APP PURPOSE & TARGET AUDIENCE
===============================
Easy Molkky Score is a free scoreboard app for Mölkky, a Finnish
outdoor throwing game. Mölkky has complex rules (reaching exactly 50
points to win, dropping to 25 on overshoots, disqualification after
three consecutive misses, and survivor mode for group play). Manual
scorekeeping requires constant rule enforcement, which distracts
players from the game itself.

The app automates all rule enforcement, allowing players and organizers
to focus on gameplay. Target audience:
- Mölkky tournament participants and organizers
- Casual players in Japan and internationally (Finnish sport gaining
  popularity globally)
- Community groups holding recreational matches

Differentiation from other Mölkky scoreboard apps:
- **One-tap score input**: numeric buttons 1-12 (matching Mölkky's
  12 numbered pins) are always visible on the main score screen, so
  a single tap records the pin number or miss. Competing apps often require multi-step dialogs (select player
  → select score → confirm), which slows down live match play.
- **Rich variety of match formats**: 1v1, team battles, round-robin,
  3-game series, self-play modes (5-turn / 6-turn solo practice), and
  a "100-kin" casual variant mode. Most competing apps only support
  basic 1v1 or free-form scoring.

Value delivered: eliminates scorekeeping errors, records match history,
and supports up to 8 players with multiple tournament formats. The
one-tap UX means scorekeepers can enter a full match's scores in real
time without pausing gameplay.

===============================
3. SETUP AND ACCESS INSTRUCTIONS
===============================
The app is fully usable WITHOUT any account creation or sign-in.

To reproduce the main flow:
1. Launch the app.
2. Enter one or more player names (e.g. "Player 1", "Player 2") and
   tap the plus icon after each.
3. Tap "ゲーム開始" (Start Match) to begin.
4. Tap the numeric buttons (1-12) to record which pin was knocked
   down (Mölkky uses 12 numbered pins), or "0 (miss)" for a missed
   throw.
5. Continue until a player reaches exactly 50 points or is disqualified.
6. Tap "OK" on the result dialog to return to the top screen.

No test account is required — the app is purpose-built to be played
anonymously. Optional Google or Apple sign-in only enables match
history sync across multiple devices; it is not required to use the app.

If a demo account is preferred, please use any personal Apple ID for
Sign in with Apple testing.

===============================
4. EXTERNAL SERVICES USED
===============================
The following external services are used to deliver core functionality:

- Firebase Authentication (Google): anonymous authentication and
  optional user sign-in (Google / Apple).
- Firebase Firestore (Google): optional cross-device match history
  synchronization (only when signed in).
- Google Sign-In SDK (google_sign_in Flutter plugin): OAuth 2.0 client
  for signing in with a Google account.
- Sign in with Apple (Apple's AuthenticationServices framework via
  sign_in_with_apple Flutter plugin): required per Guideline 4.8.

No advertising SDKs, analytics beyond Firebase's default, or payment
processors are used. There are no in-app purchases or subscriptions.

===============================
5. REGIONAL DIFFERENCES
===============================
The app functions identically in all regions. All features, content,
and rule enforcement are the same worldwide. The app is localized in
Japanese and English (auto-switching based on device language). No
region-restricted content or features exist.

===============================
6. REGULATED INDUSTRY / PROTECTED MATERIAL
===============================
Not applicable. Mölkky (Mölkky, モルック) is a Finnish outdoor
throwing game whose rules are publicly documented and not subject to
any trademark, copyright, or licensing restriction that would apply to
a scorekeeping app. The app does not use any proprietary logos,
graphics, or content associated with any specific Mölkky federation or
tournament body. All rules implemented are publicly documented sport
rules used worldwide.

===============================
DEMO ACCOUNT (Not Required)
===============================
As noted above, the app is anonymous by default and does not require an
account. If the reviewer wishes to test the optional sign-in flows,
please use the reviewer's own Apple ID or a personal Google account.
No shared demo credentials are provided because none are needed for
full app functionality.

===============================
CONTACT
===============================
Developer: ikegami
Email: [ikegam1 の連絡先メール — ikegamiさん記入]
Response time: within 24-48 hours

Thank you for the thorough review. Please let us know if you need any
additional information.
```

---

## App Store Connect での操作手順

1. App Store Connect → 対象アプリ → **App Review** タブ
2. リジェクト通知の下にある **「App Review に返信」** をクリック
3. 上記の英文をコピー貼付
4. 併せて **App Store Information の Notes 欄**にも同じ内容を貼付
   (今後の申請でも参照される)
5. **「送信」**

## 画面録画の撮り方 (ikegamiさん iPhone で)

1. iPhone 設定 → コントロールセンター → 「画面収録」を追加
2. Easy Molkky Score を起動する前にコントロールセンターを開く
3. 画面収録ボタン (⊙) を長押し → マイクは OFF (音声不要) → 「収録を開始」
4. アプリを起動して以下フローを実行:
   - プレイヤー名 2〜3 人登録
   - ゲーム開始
   - スコア入力 (数回 tap して 50 点到達)
   - 試合結果ダイアログ → OK
   - 右上の人型アイコン → Google または Apple サインイン → 成功
   - 右上人型アイコン (緑) タップして連携済み確認
   - 設定 → アカウント削除 → 確認 → 削除完了
5. 収録停止 → 写真アプリに保存される
6. .mov または .mp4 として保存 → **App Store Connect** の対象バージョン →
   「Reviewer に添付ファイル追加」で upload

**録画時間目安: 2〜4 分程度**

## 私 (@claude君) が API 経由でできること

上記の英文回答を **App Store Connect API 経由で Notes 欄に自動反映**することも
可能です (Firebase Secret の `.p8` 使用)。

もし自動反映希望なら:
```
Discord で「Notes 欄に自動反映して」と一言ください
```
→ 私が API で書き込み、確認完了報告します。

**Reviewer への返信** (App Review タブ) は自動化できないので、そちらは
ikegamiさんが手動でコピペ + 送信をお願いします 🙏
