# ライブ配信機能 — Firestore セットアップ手順

ライブ配信URL機能（試合画面右上のビデオアイコン → 公開URL発行）を有効化するために必要な Firebase / Firestore 側の設定手順をまとめます。

## 1. Firestore セキュリティルールの追加

Firebase コンソール → Firestore → ルール で、`liveMatches` コレクション用のルールを追加してください。

```firestore-rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 既存のルール（scoresコレクション等）は維持

    // ライブ配信用コレクション
    match /liveMatches/{liveId} {
      // 認証なしで読み取り可能（OBS等の配信ソフトから直接アクセスするため）
      allow read: if true;

      // 書き込みは認証済みユーザーのみ
      // 試合の主催者（appUserId が match.matchId に紐付くユーザー）のみが理想だが
      // 試合途中で頻繁に更新するため、認証のみをチェック。
      allow create, update: if request.auth != null;

      // 削除は認証済みユーザーのみ（クリーンアップ用）
      allow delete: if request.auth != null;
    }
  }
}
```

## 2. TTL（Time To Live）ポリシーの設定

公開URLは「試合終了から24時間後」に自動削除する仕様です。Cloud Functions ではなく Firestore のネイティブ TTL 機能を使います。

### 設定手順

1. Google Cloud Console → Firestore → TTL を開く
   - https://console.cloud.google.com/firestore/databases/-default-/ttl
2. 「ポリシーを作成」をクリック
3. 以下を入力：
   - **コレクション ID**: `liveMatches`
   - **タイムスタンプ フィールド**: `expiresAt`
4. 「作成」をクリック

**注意**: TTL の削除タイミングは「設定時刻 + 最大24時間以内」の幅があります（Firestore の仕様）。ライブ配信終了から最長 48 時間程度で削除される可能性があります。

## 3. 動作確認

1. Easy Molkky Score にサインインして試合を開始
2. AppBar 右上のビデオアイコン（▶️）をタップ
3. 「発行する」を押す
4. 表示された URL を別タブで開く → スコアが表示されること
5. 試合中にスコアを入力 → 公開ページがリアルタイム更新されること

## 4. 既知の制約

- ライブ表示 URL は試合画面の State 内でのみ保持される（画面を出ると再発行が必要だが、同じ `matchId` のため Firestore 上は同じドキュメントが更新される）
- 同じ試合で複数の `liveId` が発行される可能性は理論上ある（`issueOrGetLiveId` で `matchId` の既存検索を行うため低確率）
- 1試合 = 1 URL（複数URL発行はサポート外）
