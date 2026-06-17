/// 横レイアウト判定の状態を保持し、画面サイズの一時的な変化（特にキーボード表示で
/// 縦幅だけ縮む状況）で判定結果が揺れないようにするヘルパー。
///
/// iPhone17 などの Web ブラウザでは、テキスト入力時にソフトウェアキーボードが
/// 表示されると `BoxConstraints.maxHeight` が急減して、横レイアウト条件
/// (横幅 >= 縦幅 * 1.25 かつ 縦幅 < 500) を満たしてしまい、入力中に
/// レイアウトが切り替わってしまう不具合があった。
///
/// このクラスは、横幅が変わらず縦幅だけが縮んだ場合は **前回の判定** を維持し、
/// 横幅が変わった（画面回転など）場合や縦幅が広がった場合は再判定する。
class LandscapeDetector {
  double? _stableWidth;
  double? _stableHeight;
  bool? _stableLandscape;

  /// 横レイアウトかどうかを判定する。
  /// [maxWidth] / [maxHeight] は LayoutBuilder の constraints から渡す想定。
  bool resolve(double maxWidth, double maxHeight) {
    final widthChanged =
        _stableWidth == null || (maxWidth - _stableWidth!).abs() > 1;
    if (widthChanged) {
      // 画面回転等、横幅が変わった場合は素直に再判定して状態を更新する
      _stableWidth = maxWidth;
      _stableHeight = maxHeight;
      _stableLandscape = _classify(maxWidth, maxHeight);
      return _stableLandscape!;
    }

    // 幅は同じ。縦が広がった場合のみ再判定（キーボードが閉じられたケース等）
    if (maxHeight > _stableHeight!) {
      _stableHeight = maxHeight;
      _stableLandscape = _classify(maxWidth, maxHeight);
    }
    // 縦が縮んだ場合は前回判定を維持（キーボード表示時のレイアウトブレを防ぐ）
    return _stableLandscape!;
  }

  /// テスト用に内部状態をリセットする。
  void reset() {
    _stableWidth = null;
    _stableHeight = null;
    _stableLandscape = null;
  }

  /// 横レイアウト判定の元ロジック。横幅 >= 縦幅 * 1.25 かつ 縦幅 < 500。
  static bool _classify(double width, double height) {
    return width >= height * 1.25 && height < 500;
  }
}
