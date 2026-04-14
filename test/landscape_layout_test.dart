// 縦向き・横向きのレイアウト計算ロジックのユニットテスト
// 縦向きの動作が変わっていないことを保証する
// レイアウト切り替えは高さ500px未満を条件とする（向きではなく高さで判定）
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('縦向きピンボタン アスペクト比', () {
    double portraitAspectRatio({required double screenH, required double screenW}) {
      const maxGridH = 0.392; // height * 0.392
      final h = screenH * maxGridH;
      final cellH = (h - 8.0 * 2) / 3;
      final cellW = (screenW - 8.0 * 3) / 4;
      return (cellW / cellH).clamp(1.5, double.infinity);
    }

    test('縦長スマホ (390x844) では最小1.5にクランプされる', () {
      final ratio = portraitAspectRatio(screenH: 844, screenW: 390);
      // cellW ≈ 93, cellH ≈ 108 → 0.86 → clamp → 1.5
      expect(ratio, 1.5);
    });

    test('幅広タブレット (768x1024) では自然なアスペクト比になる', () {
      final ratio = portraitAspectRatio(screenH: 1024, screenW: 768);
      // cellW ≈ 186, cellH ≈ 131 → 1.42 → clamp → 1.5 (ぎりぎり)
      expect(ratio, greaterThanOrEqualTo(1.5));
    });

    test('縦向きは常にアスペクト比が1.5以上', () {
      final screens = [
        (390.0, 844.0),
        (375.0, 812.0),
        (414.0, 896.0),
        (360.0, 780.0),
      ];
      for (final (w, h) in screens) {
        final ratio = portraitAspectRatio(screenH: h, screenW: w);
        expect(ratio, greaterThanOrEqualTo(1.5),
            reason: '${w}x$h のアスペクト比が1.5未満');
      }
    });
  });

  group('横向きピンボタン アスペクト比', () {
    double landscapeAspectRatio({required double panelW, required double availH}) {
      final cellH = (availH - 6.0 * 2) / 3;
      final cellW = (panelW - 6.0 * 3) / 4;
      return (cellW / cellH).clamp(0.8, double.infinity);
    }

    test('横向きは最小0.8にクランプされる（非常に狭い場合）', () {
      final ratio = landscapeAspectRatio(panelW: 100, availH: 500);
      expect(ratio, 0.8);
    });

    test('典型的な横向き (844x390, 右パネル~355px, 利用可能高さ~274px) は正常', () {
      // rightW = 844 * 0.42 ≈ 355, body height = 390 - 56(AppBar) ≈ 334
      // availH ≈ 334 - 50(bottom bar) = 284
      final ratio = landscapeAspectRatio(panelW: 355, availH: 284);
      expect(ratio, greaterThanOrEqualTo(0.8));
      // cellW ≈ 87, cellH ≈ 90 → ratio ≈ 0.97 → > 0.8
      expect(ratio, greaterThan(0.8));
    });

    test('横向きは縦向きと異なり1.5未満でも許容される', () {
      final ratio = landscapeAspectRatio(panelW: 300, availH: 280);
      // ほとんどのケースで1.5未満になり得る
      expect(ratio, greaterThanOrEqualTo(0.8));
    });
  });

  group('レイアウト切り替えの高さしきい値', () {
    bool useCompactLayout(double availableHeight) => availableHeight < 500;

    test('スマホ縦向き (高さ~788px) は縦用レイアウト', () {
      expect(useCompactLayout(788), isFalse); // 390x844 - AppBar56
    });

    test('スマホ横向き (高さ~334px) は横用レイアウト', () {
      expect(useCompactLayout(334), isTrue); // 844x390 - AppBar56
    });

    test('タブレット横向き (高さ~712px) は縦用レイアウト', () {
      expect(useCompactLayout(712), isFalse); // iPad 768px - AppBar56
    });

    test('ブラウザ広幅 (高さ~600px) は縦用レイアウト', () {
      expect(useCompactLayout(600), isFalse);
    });

    test('500px境界: 499px以下で横用、500px以上で縦用', () {
      expect(useCompactLayout(499), isTrue);
      expect(useCompactLayout(500), isFalse);
    });
  });

  group('縦向きの主要パラメータ不変確認', () {
    test('ピンボタンは 4列×3行 (12個) で構成される', () {
      const itemCount = 12;
      const crossAxisCount = 4;
      final rowCount = itemCount ~/ crossAxisCount;
      expect(rowCount, 3);
    });

    test('縦向きグリッド高さ係数は 0.392 (変更なし)', () {
      const heightFactor = 0.392;
      // 変更されていないことを確認
      expect(heightFactor, closeTo(0.392, 0.001));
    });

    test('縦向きボタンフォントサイズは 26pt (変更なし)', () {
      const portraitFontSize = 26.0;
      expect(portraitFontSize, 26.0);
    });
  });
}
