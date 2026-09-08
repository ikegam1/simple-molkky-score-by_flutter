# App Store 審査 Guideline 2.1 追加情報要求への回答 (英語草案)

**却下 (Rejected)** ではなく、**新規デベロッパー向けの追加情報要求**。以下 6 項目
に回答することでほぼ確実に承認されます。

App Store Connect の対象バージョン → **App Review** タブ → 「Reviewer に返信」
または「App Review Information」の Notes 欄に貼り付けてください。

---

## 英語回答文案 (そのまま貼り付け OK)

```
Thank you for reviewing our submission. Below is the requested information.

1. SCREEN RECORDING
A screen recording (mp4) is attached via App Store Connect, showing:
- Adding players, starting a match, entering scores via numeric buttons
- 50-point win detection and overshoot reset to 25
- Sign in with Apple / Google, and account deletion flow

2. APP PURPOSE & TARGET AUDIENCE
Easy Molkky Score is a free scoreboard for Mölkky, a Finnish throwing game. The sport has complex rules (exactly 50 to win, reset to 25 on overshoot, disqualification after 3 misses, survivor mode). The app automates all rule enforcement so players can focus on the game.

Target: Mölkky players, tournament organizers, and casual groups worldwide.

Key differentiators:
- One-tap score input: buttons 1-12 always visible, one tap records the result. No multi-step dialogs.
- Rich match formats: 1v1, team, round-robin, 3-game series, solo practice, and casual modes.

3. SETUP INSTRUCTIONS
No account required. Steps:
1. Launch → enter player names → tap "ゲーム開始" (Start)
2. Tap buttons 1-12 for scores, or "0" for miss
3. Play until someone reaches 50 points
Optional sign-in (Apple/Google) enables cross-device history sync only.

4. EXTERNAL SERVICES
- Firebase Auth: anonymous auth + optional Google/Apple sign-in
- Firebase Firestore: optional match history sync (signed-in only)
- Google Sign-In SDK & Sign in with Apple (per Guideline 4.8)
No ads, analytics, IAP, or subscriptions.

5. REGIONAL DIFFERENCES
None. Identical functionality worldwide. Localized in Japanese and English.

6. REGULATED INDUSTRY / PROTECTED MATERIAL
Not applicable. Mölkky rules are publicly documented with no licensing restrictions.

CONTACT
Developer: ikegami
Email: masrao2002@outlook.com
Response time: within 24-48 hours
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
