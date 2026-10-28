import 'dart:math' as math;

/// 結果カードを画像にするときの倍率を決める。
///
/// **大きくしすぎない。**
///
/// 結果カードはセットごとに明細を積むので、セット数が多いと**非常に縦長**に
/// なる。倍率 3 のまま画像にすると数千万画素になり、端末によっては作る途中で
/// メモリを使い切って**アプリごと落ちる**
/// (利用者報告 2026-10-28: 10 セットの試合で 2 回とも保存中に落ちた)。
///
/// 落ちると何も残らないので、**粗くても保存できるほう**を採る。普通の
/// 試合 (数セット) では今までどおり倍率 3 のままになる。
///
/// [maxPixels] は作る画像の総画素数の上限。1 画素 4 バイトなので、
/// 600 万画素で約 24MB。PNG にする途中でさらに一時的な領域が要る。
/// [maxSide] は 1 辺の上限。極端に細長い画像で描画が破綻するのを防ぐ。
/// **上限は必ず守る。** 読みやすさより落ちないことを優先する。極端に長い
/// カードでは倍率が 1 を下回るが、読めない画像でも「落ちて何も残らない」
/// よりはましと判断した。
double resultImagePixelRatio(
  double logicalWidth,
  double logicalHeight, {
  double preferred = 3.0,
  int maxSide = 8192,
  int maxPixels = 6000000,
}) {
  // 大きさが取れないときは等倍。無理に拡大しない。
  if (!logicalWidth.isFinite || !logicalHeight.isFinite) return 1.0;
  if (logicalWidth <= 0 || logicalHeight <= 0) return 1.0;

  var ratio = preferred;
  ratio = math.min(ratio, maxSide / logicalWidth);
  ratio = math.min(ratio, maxSide / logicalHeight);
  ratio = math.min(
    ratio,
    math.sqrt(maxPixels / (logicalWidth * logicalHeight)),
  );
  return ratio;
}
