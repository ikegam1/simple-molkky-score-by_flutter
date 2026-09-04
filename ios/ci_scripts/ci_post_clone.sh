#!/bin/sh
# Xcode Cloud のビルド前フックスクリプト。
#
# Xcode Cloud のクリーン仮想マシンには Flutter が入っていない (Xcode + macOS
# のみ)。この script は clone 直後・Xcode コマンド実行前に走り、Flutter SDK
# を入れて `flutter pub get` + `pod install` まで済ませる。
#
# ドキュメント: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
#
# 場所: ios/ci_scripts/ 直下 (この階層固定。Xcode Cloud が自動検出する)
# 実行タイミング: `xcodebuild archive` の前 (post-clone)。
# シェル: /bin/sh (bash 前提のコマンドは避ける)。
#
# 前提:
# - `pubspec.yaml` の環境で必要な Flutter 版が判別できる (現状は 3.41.2 固定)。
# - Xcode 15.3+ (Flutter iOS プラグインの要件)。
# - macOS 14+ (Xcode Cloud の VM は最新側)。

set -euo pipefail

echo "▶ ci_post_clone.sh (Flutter setup for Xcode Cloud) start"

# ------------------------------------------------------------
# Flutter を tag 指定で clone (Xcode Cloud VM には未 install)。
# バージョンは README / lib のビルド確認に合わせて 3.41.2 stable。
# 上げる場合はここを差し替え + pubspec.yaml `environment: sdk:` も再確認。
# ------------------------------------------------------------
FLUTTER_VERSION="3.41.2"
FLUTTER_ROOT="$HOME/flutter"

if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "▶ Cloning Flutter $FLUTTER_VERSION into $FLUTTER_ROOT"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
else
  echo "▶ Reusing existing Flutter at $FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true

# ------------------------------------------------------------
# プロジェクトルートまで戻って pub get + iOS Pod 生成。
# ci_scripts は `ios/ci_scripts/` 配下なので 2 階層上がプロジェクトルート。
# ------------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
echo "▶ Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

echo "▶ flutter pub get"
flutter pub get

echo "▶ flutter precache --ios"
flutter precache --ios

# Xcode Cloud VM の Cocoapods バージョン (1.17.0+) はローカル開発機
# (1.16.2 等) と異なることが多く、`--deployment` を付けると
# `[!] There were changes to the lockfile in deployment mode:` で
# fail する。CI 側では lock 差分を許容して pod install を回す。
# (Podfile.lock 自体は git 管理下だが、CI では書き戻さないので影響なし)
#
# また Cocoapods CDN (raw.githubusercontent.com) のタイムアウトが
# 稀に発生し、`Response: Timeout was reached` で fail する。3 回まで
# リトライして transient network エラーで即失敗しないようにする。
echo "▶ pod install --project-directory=ios (with retry)"
cd ios
POD_INSTALL_MAX_TRIES=3
POD_INSTALL_TRY=1
while [ "$POD_INSTALL_TRY" -le "$POD_INSTALL_MAX_TRIES" ]; do
  echo "  attempt $POD_INSTALL_TRY / $POD_INSTALL_MAX_TRIES"
  if pod install; then
    echo "  pod install succeeded on attempt $POD_INSTALL_TRY"
    break
  fi
  if [ "$POD_INSTALL_TRY" -eq "$POD_INSTALL_MAX_TRIES" ]; then
    echo "  pod install failed after $POD_INSTALL_MAX_TRIES attempts"
    exit 1
  fi
  echo "  pod install failed; retrying in 15 seconds..."
  sleep 15
  POD_INSTALL_TRY=$((POD_INSTALL_TRY + 1))
done
cd "$PROJECT_ROOT"

echo "✔ ci_post_clone.sh done"
