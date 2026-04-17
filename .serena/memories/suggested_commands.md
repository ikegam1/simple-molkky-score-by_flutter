# 開発コマンド一覧

## 実行
```bash
flutter run
```

## テスト
```bash
flutter test                          # 単体・Widgetテスト
flutter test test/game_logic_test.dart  # 特定ファイルのみ
```

## ビルド
```bash
flutter build apk       # Android
flutter build ios       # iOS
flutter build web       # Web
```

## 静的解析・フォーマット
```bash
flutter analyze         # 静的解析（flutter_lints使用）
dart format lib/        # フォーマット
dart format test/
```

## パッケージ
```bash
flutter pub get
flutter pub upgrade
```

## コード生成（build_runner使用時）
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Firebase
```bash
flutterfire configure   # Firebase設定の再生成
```

## システムユーティリティ（Darwin/macOS）
```bash
ls -la          # ファイル一覧
find . -name "*.dart"  # Dartファイル検索
grep -r "keyword" lib/ # コード内検索
git log --oneline -10  # 最近のコミット
git status
```
