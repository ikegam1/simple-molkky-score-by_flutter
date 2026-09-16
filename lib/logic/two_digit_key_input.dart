/// テンキーで 10 / 11 / 12 を 2 桁として打てるようにするための判定。
///
/// 10〜12 は numpadMultiply / numpadSubtract / numpadAdd に割り当てているが、
/// テンキーが手元に無い環境では打てない。そこで「1 を押した直後に 0 / 1 / 2 を
/// 続けて押したら 2 桁として扱う」入力を用意する。
///
/// - 1 → 0 : 10
/// - 1 → 1 : 11
/// - 1 → 2 : 12
///
/// 続けて押されたかどうかは [kTwoDigitKeyWindow] で判断する。窓を過ぎたら
/// 最初の 1 はそのまま 1 点として確定する。
library;

/// 「続けて押した」とみなす時間。これを過ぎたら 2 桁にまとめない。
const Duration kTwoDigitKeyWindow = Duration(milliseconds: 500);

/// 1 の直後に [next] が押されたときの合成結果。
///
/// 合成できない数字なら null を返す。呼び元は「1 を確定してから [next] を
/// 別の投擲として処理する」ことになる。
int? combineAfterOne(int next) {
  switch (next) {
    case 0:
      return 10;
    case 1:
      return 11;
    case 2:
      return 12;
    default:
      return null;
  }
}
