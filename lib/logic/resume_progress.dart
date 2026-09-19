/// 中断した試合を再開するときの、進行状態の補正。
///
/// スナップショットは「試合データ (MolkkyMatch)」と「画面の進行状態
/// (currentTurnInSet など)」を別々に持つ。**この 2 つは食い違うことがある。**
/// セットが終わった瞬間は、試合データが次セットの開始状態 (スコア空) に
/// なっているのに、画面の状態は前セットの最終ターンのまま保存されうる
/// (ユーザ報告 2026-09-19: 再開すると空の行が並び、表示が壊れる)。
///
/// 食い違ったスナップショットは既に端末に残っている可能性があるので、
/// 保存側を直すだけでは足りない。**読み出す側で必ず突き合わせる。**
library;

/// 補正後の進行状態。
class ResumedProgress {
  /// 何ターン目から再開するか (1 始まり)。
  final int currentTurnInSet;

  /// セットが終わった状態で再開するか。
  final bool isSetFinished;

  /// 何番目のプレイヤーから投げるか (0 始まり)。
  final int currentPlayerIndex;

  /// 入力途中のターンの情報 (途中得点・記号・バースト) を捨てるべきか。
  ///
  /// 試合データ側に一投も記録が無いのに、画面の状態だけ前のセットのものが
  /// 残っている場合に true。そのまま復元すると、**他のプレイヤーの前セットの
  /// 得点が混ざったターンが記録される**。
  final bool discardPartialTurn;

  const ResumedProgress({
    required this.currentTurnInSet,
    required this.isSetFinished,
    required this.currentPlayerIndex,
    required this.discardPartialTurn,
  });
}

/// 保存されていた進行状態を、試合データと矛盾しない範囲に収める。
///
/// - [savedTurn] / [savedSetFinished] / [savedPlayerIndex] はスナップショットの値
/// - [recordedTurns] は試合データ側に実際に記録されている最大ターン数
///   (players の scoreHistory の長さの最大値)
/// - [playerCount] はプレイヤー数
ResumedProgress sanitizeResumedProgress({
  int? savedTurn,
  bool? savedSetFinished,
  int? savedPlayerIndex,
  required int recordedTurns,
  int? minRecordedTurns,
  required int playerCount,
}) {
  // 記録から、いま何ターン目のはずかは決まる。
  //
  // - 全員が n ターン投げ終わっている → 次は n+1 ターン目
  // - 一部の人だけ n ターン投げている (ターンの途中) → いまが n ターン目
  //
  // **ずれは両方向に起きる。** 進みすぎ (データが無いターンを描こうとして
  // 表示が壊れる) だけでなく、遅れすぎ (次の入力が実際には 6 ターン目として
  // 積まれるのに、画面は 1 ターン目と表示する) もありうる (codex 指摘)。
  final maxRecorded = recordedTurns;
  final minRecorded = minRecordedTurns ?? recordedTurns;
  final expectedTurn =
      minRecorded >= maxRecorded ? maxRecorded + 1 : maxRecorded;
  var turn = (savedTurn != null && savedTurn >= 1) ? savedTurn : expectedTurn;
  // 妥当なのは「いま投げているターン」か「次のターン」だけ。
  if (turn < maxRecorded || turn > maxRecorded + 1) turn = expectedTurn;
  if (turn < 1) turn = 1;

  // 一投も記録が無いのに「セット終了」で再開すると、点数を入れられない
  // 画面になって詰む。
  final setFinished = (savedSetFinished ?? false) && recordedTurns > 0;

  // 一投も記録が無いなら、セットはまだ始まっていない。画面の状態が前の
  // セットのものなら丸ごと捨てる。前セットの勝者から投げ始めてしまい、
  // 他の人の古い得点が混ざったターンが記録されるため (codex 指摘)。
  final startingFresh = maxRecorded == 0;

  var playerIndex =
      (savedPlayerIndex != null && savedPlayerIndex >= 0)
          ? savedPlayerIndex
          : 0;
  if (playerCount <= 0 || playerIndex >= playerCount || startingFresh) {
    playerIndex = 0;
  }

  return ResumedProgress(
    currentTurnInSet: turn,
    isSetFinished: setFinished,
    currentPlayerIndex: playerIndex,
    discardPartialTurn: startingFresh,
  );
}
