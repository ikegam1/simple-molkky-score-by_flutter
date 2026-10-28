import 'dart:math' as math;

/// 結果カードを画像にするときの倍率を決める。
///
/// **大きくしすぎない。**
///
/// 結果カードはセットごとに明細を積むので、セット数が多いと**非常に縦長**に
/// なる。大きい倍率のまま画像にすると数千万画素になり、端末によっては作る
/// 途中でメモリを使い切って**アプリごと落ちる**
/// (利用者報告 2026-10-28: 10 セットの試合で 2 回とも保存中に落ちた)。
///
/// 落ちると何も残らないので、**粗くても保存できるほう**を採る。
///
/// **[preferred] は 2 倍にしてある。**
///
/// 以前は 3 倍だった。結果カードは文字と枠しか無いので、そこまでの細かさは
/// 要らない (依頼者の判断 2026-10-28)。2 倍にすると画素数は 4/9 になり、
/// 画像を作るときのメモリと時間がその分減る。文字は 10〜13 の大きさなので、
/// 2 倍なら 20〜26 画素になり読むのに困らない。
///
/// [maxPixels] は作る画像の総画素数の上限。1 画素 4 バイトなので、
/// 400 万画素で約 16MB。PNG にする途中でさらに一時的な領域が要る。
/// [maxSide] は 1 辺の上限。極端に細長い画像で描画が破綻するのを防ぐ。
/// **上限は必ず守る。** 読みやすさより落ちないことを優先する。極端に長い
/// カードでは倍率が 1 を下回るが、読めない画像でも「落ちて何も残らない」
/// よりはましと判断した。
double resultImagePixelRatio(
  double logicalWidth,
  double logicalHeight, {
  double preferred = 2.0,
  int maxSide = 8192,
  int maxPixels = 4000000,
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
