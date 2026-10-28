import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/result_image_scale.dart';

/// 結果画像の倍率のテスト。
///
/// 背景 (利用者報告 2026-10-28):
/// 「10番を2回回した。スコアを画像保存しようとしたけど、2回ともダウンロード中に
/// アプリが落ちて保存できなかった」
///
/// 結果カードはセットごとに明細を積むので、セット数が多いと非常に縦長になる。
/// 倍率 3 固定で画像にしていたため、数千万画素になってメモリを使い切っていた。
///
/// **普通の試合では今までどおりの画質を保ち、大きくなりすぎるときだけ下げる。**
void main() {
  // 画素数の上限 (既定 400 万) と 1 辺の上限 (既定 8192)。
  const maxPixels = 4000000;
  const maxSide = 8192;

  int pixelsOf(double w, double h) {
    final r = resultImagePixelRatio(w, h);
    return (w * r).round() * (h * r).round();
  }

  group('普通の試合では既定の倍率を使う', () {
    // 結果カードは文字と枠しか無いので 2 倍で足りる (依頼者の判断)。
    // 文字の大きさは 10〜13 なので、2 倍なら 20〜26 画素になる。
    test('1 セットのカード', () {
      expect(resultImagePixelRatio(400, 900), 2.0);
    });

    test('3 セットくらいのカード', () {
      expect(resultImagePixelRatio(400, 1200), 2.0);
    });
  });

  group('大きくなりすぎるときは下げる', () {
    test('10 セット相当の縦長カードでは倍率が下がる', () {
      final r = resultImagePixelRatio(400, 6000);
      expect(r, lessThan(2.0));
      expect(r, greaterThan(0.5));
    });

    test('どんな大きさでも画素数の上限を超えない', () {
      for (final h in <double>[900, 2000, 4000, 6000, 10000, 20000]) {
        expect(
          pixelsOf(400, h),
          lessThanOrEqualTo(maxPixels + 10000), // 丸め誤差の余裕
          reason: '高さ $h で画素数が上限を超えた',
        );
      }
    });

    test('1 辺の上限も超えない', () {
      for (final h in <double>[4000, 10000, 30000]) {
        final r = resultImagePixelRatio(400, h);
        expect(
          (h * r).round(),
          lessThanOrEqualTo(maxSide + 10),
          reason: '高さ $h',
        );
      }
    });
  });

  group('内部処理が軽くなっていること', () {
    test('以前 (倍率 3) より画素数が半分以下になる', () {
      // 文字と枠しか無いので細かさは要らない、という判断で 3 → 2 にした。
      // 画素数は 4/9 = 約 44%。画像を作るときのメモリと時間もその分減る。
      final now = pixelsOf(400, 1200);
      final before = (400 * 3).round() * (1200 * 3).round();
      expect(now / before, lessThan(0.5));
    });

    test('10 セット相当でも 400 万画素に収まる', () {
      // 以前は 2160 万画素 (生データ 86MB) になって落ちていた。
      expect(pixelsOf(400, 6000), lessThanOrEqualTo(maxPixels + 10000));
    });
  });

  group('上限は必ず守る', () {
    test('極端に長いカードでは 1 倍を下回ってでも上限に収める', () {
      // 読みやすさより落ちないことを優先する。読めない画像でも
      // 「落ちて何も残らない」よりはまし。
      final r = resultImagePixelRatio(400, 100000);
      expect(r, lessThan(1.0));
      expect((100000 * r).round(), lessThanOrEqualTo(maxSide + 10));
    });
  });

  group('おかしな大きさでは等倍', () {
    test('0 や負の値', () {
      expect(resultImagePixelRatio(0, 1000), 1.0);
      expect(resultImagePixelRatio(400, 0), 1.0);
      expect(resultImagePixelRatio(-1, 1000), 1.0);
    });

    test('NaN や無限大', () {
      expect(resultImagePixelRatio(double.nan, 1000), 1.0);
      expect(resultImagePixelRatio(400, double.infinity), 1.0);
    });
  });
}
