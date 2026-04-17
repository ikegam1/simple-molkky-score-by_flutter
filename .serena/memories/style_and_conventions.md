# コードスタイルと規約

## 言語・フレームワーク
- Dart (null-safety必須)
- Flutter公式スタイルガイド（Effective Dart）に準拠
- flutter_lints パッケージによるLint

## 命名規則
| 対象 | 規則 | 例 |
|------|------|-----|
| クラス・Widget | PascalCase | `GameScreen`, `MolkkyMatch` |
| 関数・変数 | camelCase | `currentPlayerIndex`, `_submitThrow` |
| ファイル | snake_case | `game_logic.dart`, `game_models.dart` |
| 定数 | lowerCamelCase or SCREAMING_SNAKE_CASE | |
| プライベートメンバー | 先頭に `_` | `_nameController`, `_initApp` |

## コード構造
- Widgetは役割ごとに細かく分割（可読性重視）
- ロジックは `lib/logic/` に分離
- モデルは `lib/models/` に分離
- UIは現状 `lib/main.dart` に集約（今後分割予定）

## フォーマット
- 1行の長さは適宜調整
- 末尾カンマを活用してフォーマットを安定させる（trailing comma）

## テスト
- flutter_test フレームワーク使用
- ロジック変更時は必ずテストコードも更新/追加
- test/ ディレクトリに配置

## 多言語対応
- L10n / L10nDelegate クラスで多言語化管理
- flutter_localizations 使用
