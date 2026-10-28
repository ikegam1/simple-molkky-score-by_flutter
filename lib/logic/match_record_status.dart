// 戦績 (Firestore `scores`) のレコードを読むときの判定。
//
// 画面から切り離してあるのは、**取り違えると利用者の記録が見えなくなる**
// ところだから。テストで固定しておきたい。

/// セルフ 5/6 ターンの記録か。
bool isSelfTurnRecord(Map<String, dynamic> data) =>
    data['matchType'] == 'MatchType.self5Turn' ||
    data['matchType'] == 'MatchType.self6Turn';

/// 決着した試合か。
///
/// **項目が無ければ完了扱い。** 途中経過を残すようにしたのは 2026-10-28
/// からで、それ以前の戦績には `completed` が入っていない。ここを逆にすると、
/// 過去の記録が全部「未完了」に落ちて戦績から消える。
bool isCompletedRecord(Map<String, dynamic> data) => data['completed'] != false;

/// 戦績の一覧に出すか。
///
/// **未完了は既定で出さない。** 中断した試合で埋まると、普段見たい記録が
/// 探しにくくなる。`filter` が `incomplete` のときだけ未完了を出す。
bool matchesHistoryFilter(Map<String, dynamic> data, String filter) {
  if (filter == 'incomplete') return !isCompletedRecord(data);
  if (!isCompletedRecord(data)) return false;
  if (filter == 'all') return true;
  final type = data['matchType'];
  if (filter == 'self5Turn') return type == 'MatchType.self5Turn';
  if (filter == 'self6Turn') return type == 'MatchType.self6Turn';
  // 'normal'
  return !isSelfTurnRecord(data);
}

/// 選択肢から消えた値を持ち続けないよう、実際に使う値へ寄せる。
///
/// **「選択肢がいくつあるか」ではなく「その値が選択肢にあるか」で見る。**
/// 3 種別あるうち選んでいた 1 つだけが無くなった場合、種別の選択肢自体は
/// 残っているので件数で見ると見逃す (codex 指摘 2026-10-28)。選択肢に無い値を
/// 持ち続けると画面が落ちる。
String effectiveHistoryFilter({
  required String filter,
  required Set<String> available,
}) => available.contains(filter) ? filter : 'all';

/// フィルタの選択肢。`all` は常にある。
Set<String> historyFilterOptions({
  required bool hasNormal,
  required bool hasSelf5Turn,
  required bool hasSelf6Turn,
  required bool hasIncomplete,
}) => <String>{
  'all',
  // **種別は 2 つ以上あるときだけ選ばせる。** 1 種別しかないなら
  // 「すべて」と同じ意味になり、選ぶ意味が無い。
  if ((hasNormal ? 1 : 0) + (hasSelf5Turn ? 1 : 0) + (hasSelf6Turn ? 1 : 0) >
      1) ...<String>{
    if (hasNormal) 'normal',
    if (hasSelf5Turn) 'self5Turn',
    if (hasSelf6Turn) 'self6Turn',
  },
  if (hasIncomplete) 'incomplete',
};

/// 戦績に保存されている文字列から試合形式の呼び名を作る。
/// 試合中に出しているものと同じ言い回しに揃えてある。
String matchTypeLabelOf(Map<String, dynamic> data) {
  final limit = data['limit'];
  switch (data['matchType']) {
    case 'MatchType.raceTo':
      return '$limit先取';
    case 'MatchType.fixedSets':
      return '$limitセット';
    case 'MatchType.hyakin':
      return '百均モード';
    case 'MatchType.self5Turn':
      return 'セルフ5ターン';
    case 'MatchType.self6Turn':
      return 'セルフ6ターン';
    case 'MatchType.threeGame':
      return '3番';
  }
  return '';
}
