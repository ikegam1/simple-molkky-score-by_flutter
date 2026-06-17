import '../models/game_models.dart';

/// 試合終了直前の状態スナップショット。
/// 「点数を修正する」用に、勝者の setsWon +1 など試合終了処理で
/// 起きた状態変化を巻き戻すために使う。
class PostMatchSnapshot {
  final int currentSetIndex;
  final int currentTurnInSet;
  final SetRecord currentSetRecord;
  final int completedSetsLen;
  final List<Map<String, dynamic>> playerStates;

  PostMatchSnapshot._({
    required this.currentSetIndex,
    required this.currentTurnInSet,
    required this.currentSetRecord,
    required this.completedSetsLen,
    required this.playerStates,
  });

  /// 試合終了直後の状態を記録する。
  /// [setWinner] が指定された場合、その勝者の setsWon は試合終了処理で
  /// +1 されているはずなので -1 補正して保存する（引き分けの場合は null）。
  /// 試合終了時の `finalizeCurrentSetIfNeeded()` で全員の `setFinalScores` に
  /// 最終セット分が追加されているので、`setFinalScoresLen` も -1 補正する。
  factory PostMatchSnapshot.capture({
    required MolkkyMatch match,
    required int currentTurnInSet,
    Player? setWinner,
  }) {
    return PostMatchSnapshot._(
      currentSetIndex: match.currentSetIndex,
      currentTurnInSet: currentTurnInSet,
      currentSetRecord: match.currentSetRecord,
      completedSetsLen: match.completedSets.length,
      playerStates:
          match.players
              .map(
                (p) => <String, dynamic>{
                  'id': p.id,
                  'currentScore': p.currentScore,
                  'consecutiveMisses': p.consecutiveMisses,
                  'isDisqualified': p.isDisqualified,
                  'setsWon': p == setWinner ? p.setsWon - 1 : p.setsWon,
                  'scoreHistory': List<int>.from(p.scoreHistory),
                  'scoreSnapshot': List<int>.from(p.scoreSnapshot),
                  'matchScoreHistoryLen': p.matchScoreHistory.length,
                  // 試合終了処理の finalize で +1 されているため、-1 補正
                  'setFinalScoresLen':
                      p.setFinalScores.isEmpty
                          ? 0
                          : p.setFinalScores.length - 1,
                },
              )
              .toList(),
    );
  }
}

/// Undo を適用した結果（currentTurnInSet, currentPlayerIndex）を返す。
class PostMatchUndoResult {
  final int currentTurnInSet;
  final int currentPlayerIndex;
  const PostMatchUndoResult({
    required this.currentTurnInSet,
    required this.currentPlayerIndex,
  });
}

/// 試合終了処理を巻き戻して、勝利ターンの開始位置に戻す。
/// 呼び出し側は戻り値を使って自身の `currentTurnInSet` / `currentPlayerIndex`
/// を更新すること（widget 状態は呼び出し側の責務）。
PostMatchUndoResult applyPostMatchUndo(
  MolkkyMatch match,
  PostMatchSnapshot snap,
) {
  // prepareNextSet で追加された completedSet を除去
  while (match.completedSets.length > snap.completedSetsLen) {
    match.completedSets.removeLast();
  }
  match.completedSets.removeWhere(
    (s) => s.setNumber == snap.currentSetRecord.setNumber,
  );

  // currentSetRecord と currentSetIndex を復元
  match.currentSetRecord = snap.currentSetRecord;
  match.currentSetIndex = snap.currentSetIndex;

  // 前セットの投げ順（playerOrder）に players を並び替える
  final orderIds = snap.currentSetRecord.playerOrder;
  match.players.sort(
    (a, b) => orderIds.indexOf(a.id).compareTo(orderIds.indexOf(b.id)),
  );

  // プレイヤー状態をスナップショットから復元
  for (final p in match.players) {
    final ps = snap.playerStates.firstWhere((s) => s['id'] == p.id);
    p.currentScore = ps['currentScore'] as int;
    p.consecutiveMisses = ps['consecutiveMisses'] as int;
    p.isDisqualified = ps['isDisqualified'] as bool;
    p.setsWon = ps['setsWon'] as int;
    p.scoreHistory = List<int>.from(ps['scoreHistory'] as List);
    p.scoreSnapshot = List<int>.from(ps['scoreSnapshot'] as List);
    while (p.matchScoreHistory.length > (ps['matchScoreHistoryLen'] as int)) {
      p.matchScoreHistory.removeLast();
    }
    while (p.setFinalScores.length > (ps['setFinalScoresLen'] as int)) {
      p.setFinalScores.removeLast();
    }
  }

  // 勝利ターンの TurnRecord を削除し、そのターンの投擲も全て取り消す
  if (snap.currentSetRecord.turns.isNotEmpty) {
    final winTurn = snap.currentSetRecord.turns.removeLast();
    for (final p in match.players) {
      if (!winTurn.scores.containsKey(p.id)) continue;
      if (winTurn.systemCalculatedPlayerIds.contains(p.id)) {
        // システム自動計算: scoreSnapshot エントリなし
        final gained = winTurn.scores[p.id] ?? 0;
        p.currentScore -= gained;
        if (p.scoreHistory.isNotEmpty) p.scoreHistory.removeLast();
        if (p.matchScoreHistory.isNotEmpty) p.matchScoreHistory.removeLast();
        p.isDisqualified = false;
      } else {
        // 通常の手動投擲
        if (p.scoreHistory.isNotEmpty) p.scoreHistory.removeLast();
        if (p.scoreSnapshot.isNotEmpty) {
          p.currentScore = p.scoreSnapshot.removeLast();
        }
        if (p.matchScoreHistory.isNotEmpty) p.matchScoreHistory.removeLast();
      }
    }
  }

  return PostMatchUndoResult(
    currentTurnInSet: snap.currentTurnInSet,
    currentPlayerIndex: 0,
  );
}
