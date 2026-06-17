import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/post_match_undo.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// 試合終了時のフローを再現するヘルパー。
/// 実際のコード（main.dart）で起きていることをテスト用に再現する:
///   1. 勝者の setsWon を +1
///   2. 勝利ターンを currentSetRecord に追加
///   3. finalizeCurrentSetIfNeeded() を呼ぶ（completedSets と setFinalScores 更新）
void _simulateMatchEnd(
  MolkkyMatch match, {
  required Player? winner,
  required TurnRecord lastTurn,
}) {
  if (winner != null) winner.setsWon++;
  match.currentSetRecord.turns.add(lastTurn);
  match.finalizeCurrentSetIfNeeded();
}

void main() {
  group('PostMatchSnapshot + applyPostMatchUndo', () {
    late Player alice;
    late Player bob;
    late MolkkyMatch match;

    setUp(() {
      alice = Player(id: 'a', name: 'Alice', initialOrder: 0);
      bob = Player(id: 'b', name: 'Bob', initialOrder: 1);
      match = MolkkyMatch(
        players: [alice, bob],
        limit: 1, // 1セット先取（即試合終了）
        type: MatchType.fixedSets,
      );
    });

    test('1セット先取: 勝者のsetsWonと最終セットが正しく巻き戻される', () {
      // Alice が最終ターンで勝利する直前の状態
      alice.currentScore = 50;
      alice.scoreHistory.addAll([12, 12, 12, 12, 2]);
      alice.scoreSnapshot.addAll([0, 12, 24, 36, 48]);
      alice.matchScoreHistory.addAll([12, 12, 12, 12, 2]);
      bob.currentScore = 30;
      bob.scoreHistory.addAll([10, 10, 10]);
      bob.scoreSnapshot.addAll([0, 10, 20]);
      bob.matchScoreHistory.addAll([10, 10, 10]);

      // 試合終了処理を再現
      _simulateMatchEnd(
        match,
        winner: alice,
        lastTurn: TurnRecord(5, {alice.id: 2}),
      );

      // 終了処理後の確認
      expect(alice.setsWon, 1, reason: '試合終了で setsWon が +1 されている');
      expect(alice.setFinalScores, [
        50,
      ], reason: 'finalize で setFinalScores が追加されている');
      expect(bob.setFinalScores, [30]);
      expect(match.completedSets.length, 1);

      // 試合終了直前の状態をスナップショット（setWinner=alice）
      final snap = PostMatchSnapshot.capture(
        match: match,
        currentTurnInSet: 5,
        setWinner: alice,
      );

      // Undo を適用
      final result = applyPostMatchUndo(match, snap);

      // setsWon が 0 に戻ること（バグ報告: 増え続ける不具合の修正）
      expect(alice.setsWon, 0, reason: 'setsWonが+1分巻き戻されるべき');
      expect(bob.setsWon, 0);

      // setFinalScores が空に戻ること（重複追加を防ぐ）
      expect(alice.setFinalScores, isEmpty);
      expect(bob.setFinalScores, isEmpty);

      // completedSets から最終セットが除去されること
      expect(match.completedSets, isEmpty);

      // 勝利ターンが取り消されて、Aliceのスコアが直前に戻ること
      expect(alice.currentScore, 48, reason: '勝利投擲(+2)が取り消されて48に戻る');
      expect(alice.scoreHistory, [12, 12, 12, 12]);

      // currentTurnInSet と currentPlayerIndex が勝利ターン開始位置
      expect(result.currentTurnInSet, 5);
      expect(result.currentPlayerIndex, 0);
    });

    test('引き分け終了時はsetsWon変化なし、setFinalScoresは巻き戻し', () {
      // 引き分けに至る直前の状態
      alice.currentScore = 25;
      alice.scoreHistory.addAll([12, 13]);
      alice.scoreSnapshot.addAll([0, 12]);
      alice.matchScoreHistory.addAll([12, 13]);
      bob.currentScore = 25;
      bob.scoreHistory.addAll([10, 15]);
      bob.scoreSnapshot.addAll([0, 10]);
      bob.matchScoreHistory.addAll([10, 15]);

      // 引き分け処理（winner=null、最終ターン追加、finalize）
      _simulateMatchEnd(
        match,
        winner: null,
        lastTurn: TurnRecord(2, {alice.id: 13, bob.id: 15}),
      );

      // 引き分けスナップショット
      final snap = PostMatchSnapshot.capture(match: match, currentTurnInSet: 2);

      final result = applyPostMatchUndo(match, snap);

      // setsWon は変化なし
      expect(alice.setsWon, 0);
      expect(bob.setsWon, 0);

      // setFinalScores が空に戻る
      expect(alice.setFinalScores, isEmpty);
      expect(bob.setFinalScores, isEmpty);

      // 勝利ターン投擲が取り消されて、スコアが直前に戻る
      expect(alice.currentScore, 12);
      expect(bob.currentScore, 10);

      expect(result.currentTurnInSet, 2);
      expect(result.currentPlayerIndex, 0);
    });

    test('複数セット試合: 2セット先取で2セット目に勝利→過去セットは保持', () {
      final m = MolkkyMatch(
        players: [alice, bob],
        limit: 2,
        type: MatchType.fixedSets,
      );

      // 1セット目は alice 勝利済み（completedSets / setFinalScores に保存済み）
      final pastSet = SetRecord(1, alice.id, [alice.id, bob.id]);
      pastSet.turns.add(TurnRecord(4, {alice.id: 14, bob.id: 8}));
      pastSet.finalCumulativeScores[alice.id] = 50;
      pastSet.finalCumulativeScores[bob.id] = 40;
      m.completedSets.add(pastSet);
      alice.setFinalScores.add(50);
      bob.setFinalScores.add(40);
      alice.setsWon = 1;

      // 2セット目: alice が再度勝利する直前
      m.currentSetIndex = 2;
      m.currentSetRecord = SetRecord(2, alice.id, [alice.id, bob.id]);
      alice.currentScore = 50;
      alice.scoreHistory.addAll([12, 12, 12, 14]);
      alice.scoreSnapshot.addAll([0, 12, 24, 36]);
      bob.currentScore = 18;
      bob.scoreHistory.addAll([8, 10]);
      bob.scoreSnapshot.addAll([0, 8]);

      // 2セット目終了処理
      _simulateMatchEnd(
        m,
        winner: alice,
        lastTurn: TurnRecord(4, {alice.id: 14}),
      );

      // 試合終了後の状態確認
      expect(alice.setsWon, 2);
      expect(alice.setFinalScores, [50, 50]);
      expect(bob.setFinalScores, [40, 18]);
      expect(m.completedSets.length, 2);

      // スナップショット & Undo
      final snap = PostMatchSnapshot.capture(
        match: m,
        currentTurnInSet: 4,
        setWinner: alice,
      );
      applyPostMatchUndo(m, snap);

      // alice.setsWon が 2 → 1 に戻る（過去セット分は残る）
      expect(alice.setsWon, 1);
      // setFinalScores も最新セット分が取り消される（過去セット分は残る）
      expect(alice.setFinalScores, [50]);
      expect(bob.setFinalScores, [40]);
      // completedSets から2セット目分のみ除去
      expect(m.completedSets.length, 1);
      expect(m.completedSets.first.setNumber, 1);
      // 勝利ターンが取り消されて、Aliceのスコアが直前に戻る
      expect(alice.currentScore, 36);
    });

    test('Bob勝利時はBobのsetsWonのみ-1される', () {
      bob.currentScore = 50;
      bob.scoreHistory.addAll([12, 12, 12, 12, 2]);
      bob.scoreSnapshot.addAll([0, 12, 24, 36, 48]);
      bob.matchScoreHistory.addAll([12, 12, 12, 12, 2]);
      alice.currentScore = 40;
      alice.scoreHistory.addAll([12, 12, 12, 4]);
      alice.scoreSnapshot.addAll([0, 12, 24, 36]);
      alice.matchScoreHistory.addAll([12, 12, 12, 4]);

      _simulateMatchEnd(
        match,
        winner: bob,
        lastTurn: TurnRecord(5, {bob.id: 2, alice.id: 4}),
      );

      final snap = PostMatchSnapshot.capture(
        match: match,
        currentTurnInSet: 5,
        setWinner: bob,
      );
      applyPostMatchUndo(match, snap);

      // Bob は setsWon が 0 に戻る、Alice は変化なし
      expect(bob.setsWon, 0);
      expect(alice.setsWon, 0);
      // Bob のスコアは勝利投擲(+2)を取り消し
      expect(bob.currentScore, 48);
      // Alice のスコアも投擲(+4)を取り消し
      expect(alice.currentScore, 36);
      // setFinalScores は両方空に
      expect(alice.setFinalScores, isEmpty);
      expect(bob.setFinalScores, isEmpty);
    });
  });
}
