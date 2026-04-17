# プロジェクト概要: Easy Molkky Score

## 目的
フィンランド発祥のスポーツ「モルック（Mölkky）」のスコアを管理するFlutterアプリ。

## バージョン
現在: v1.9.3+44

## 主要ルール
- 50点ピッタリを目指す（50点超過で25点に戻る）
- 3回連続ミスで失格
- サバイバルルール（失格者スキップ、最後の一人で終了）
- セット数固定モード（1, 2, 10セット等）
- セルフ5ターンモード（一人練習用、5連続成功が目標）

## テックスタック
- Flutter / Dart (SDK ^3.7.0)
- Firebase: Firestore, Authentication
- shared_preferences（ローカル保存）
- speech_to_text（音声入力）
- patrol（E2Eテスト）
- uuid, intl

## コードベース構造
```
lib/
  main.dart          # エントリーポイント + 全UI（SetupScreen, GameScreen, HistoryPage等）
  firebase_options.dart
  logic/
    game_logic.dart  # スコア計算ロジック（GameLogicクラス）
  models/
    game_models.dart # データモデル（Player, TurnRecord, SetRecord, MolkkyMatch, MatchType）
test/
  game_logic_test.dart
  molkky_match_rules_test.dart
  self5turn_test.dart
  match_winner_fixed_sets_test.dart
  bug_fixes_test.dart
  voice_input_test.dart
  widget_test.dart
integration_test/   # Patrolによるインテグレーションテスト
e2e_tests/
assets/
  icon/app_icon.png
```

## MatchType enum
- `raceTo`: 先取りモード
- `fixedSets`: セット数固定モード
- `self5Turn`: セルフ5ターン練習モード
