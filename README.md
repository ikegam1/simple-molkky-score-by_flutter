# Simple Molkky Score

フィンランド発祥のスポーツ「モルック（Mölkky）」のスコアを管理するためのFlutterアプリです。
シンプルで直感的な操作感と、公式ルールに基づいた詳細なスコア管理を実現します。

## 公開ページ

https://ikegam1.github.io/simple-molkky-score-by_flutter/

## ✨ 主な機能
- **スコアボード機能:** 各ターンの得点と累計スコアを一覧表示（DataTable形式）。
- **ドラッグ＆ドロップ:** プレイヤーの投擲順を自由に並び替え可能。
- **公式ルール準拠:**
  - 50点ピッタリで上がり。
  - 50点を超えた場合は25点にバースト。
  - 3回連続ミス（0点）で失格。
- **多様なマッチ形式:**
  - 1番、2番、2先、3先、および **11先（デュースルール対応）**。
  - 11先では10-10以降、2点差がつくまで継続します。

## 🚀 ローカルでの起動方法

### 前提条件
- [Flutter SDK](https://docs.flutter.dev/get-started/install) がインストールされていること。

### 手順
1. リポジトリをクローンします。
   ```bash
   git clone https://github.com/ikegam1/simple-molkky-score-by_flutter.git
   cd simple-molkky-score-by_flutter
   ```

2. 依存関係を解決します。
   ```bash
   flutter pub get
   ```

3. Webブラウザで起動します。
   ```bash
   flutter run -d chrome --web-port 5000
   ```
   起動後、ブラウザで `http://localhost:5000` にアクセスしてください。

## 🛠️ 技術スタック
- Framework: Flutter (Web/Mobile)
- Language: Dart
- Architecture: Simple State Management

---
Developed by M1 with ikegami.
