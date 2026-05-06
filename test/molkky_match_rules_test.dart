import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

Player p(String id, int order) => Player(id: id, name: id, initialOrder: order);

void main() {
  group('MolkkyMatch fixedSets / raceTo rules', () {
    test('fixedSets winner: setsWon first, then totalMatchScore on tie', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 10,
        type: MatchType.fixedSets,
      );

      a.setsWon = 6;
      b.setsWon = 4;
      for (int i = 1; i <= 9; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      match.currentSetIndex = 10;
      match.currentSetRecord = SetRecord(10, a.id, [a.id, b.id]);
      a.currentScore = 40;
      b.currentScore = 50;
      match.finalizeCurrentSetIfNeeded();

      expect(match.isMatchOver, isTrue);
      expect(match.matchWinner?.id, 'A');
    });

    test(
      'fixedSets (limit=2) is a draw when sets and total scores are tied',
      () {
        final a = p('A', 0);
        final b = p('B', 1);
        final match = MolkkyMatch(
          players: [a, b],
          limit: 2,
          type: MatchType.fixedSets,
        );

        a.setsWon = 1;
        b.setsWon = 1;
        a.setFinalScores.add(50);
        b.setFinalScores.add(50);
        // a.matchScoreHistory = List.filled(8, 1);
        // b.matchScoreHistory = List.filled(10, 1);

        match.completedSets.add(SetRecord(1, a.id, [a.id, b.id]));
        match.currentSetIndex = 2;
        match.currentSetRecord = SetRecord(2, a.id, [a.id, b.id]);
        a.currentScore = 30;
        b.currentScore = 30;
        match.finalizeCurrentSetIfNeeded();

        expect(match.isMatchDraw, isTrue);
        expect(match.matchWinner, isNull);
      },
    );

    test(
      'fixedSets (limit=3) tie-break by totalMatchThrows after score tie',
      () {
        final a = p('A', 0);
        final b = p('B', 1);
        final match = MolkkyMatch(
          players: [a, b],
          limit: 3,
          type: MatchType.fixedSets,
        );

        // 1-1-1 or whatever that leads to tied sets won
        a.setsWon = 1;
        b.setsWon = 1;
        a.setFinalScores = [50, 40];
        b.setFinalScores = [40, 50];
        a.matchScoreHistory = List.filled(20, 1);
        b.matchScoreHistory = List.filled(25, 1);

        match.completedSets.add(SetRecord(1, a.id, [a.id, b.id]));
        match.completedSets.add(SetRecord(2, a.id, [a.id, b.id]));
        match.currentSetIndex = 3;
        match.currentSetRecord = SetRecord(3, a.id, [a.id, b.id]);
        a.currentScore = 50;
        b.currentScore = 50;
        match.finalizeCurrentSetIfNeeded();

        expect(match.isMatchOver, isTrue);
        expect(match.isMatchDraw, isFalse); // Only 2/10 sets support draw
        expect(match.matchWinner?.id, 'A'); // fewer throws wins
      },
    );

    test('raceTo 11: 10-10 はデュース（試合継続）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 10;
      b.setsWon = 10;
      expect(match.matchWinner, isNull);
      expect(match.isMatchOver, isFalse);
    });

    test('raceTo 11: 11-10 はデュース継続（1セット差では勝利にならない）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 11;
      b.setsWon = 10;
      expect(match.matchWinner, isNull);
      expect(match.isMatchOver, isFalse);
    });

    test('raceTo 11: 11-11 はデュース継続', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 11;
      b.setsWon = 11;
      expect(match.matchWinner, isNull);
      expect(match.isMatchOver, isFalse);
    });

    test('raceTo 11: 12-10 で勝利（2セット差）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 12;
      b.setsWon = 10;
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchOver, isTrue);
    });

    test('raceTo 11: 13-11 でも勝利（2セット差）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 13;
      b.setsWon = 11;
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchOver, isTrue);
    });

    test('raceTo 11: 11-9 はデュースなしの通常勝利（B が10に達していない）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      a.setsWon = 11;
      b.setsWon = 9;
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchOver, isTrue);
    });

    test('raceTo 11: デュース後のセットで投げ順が合計点でソートされない', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 11,
        type: MatchType.raceTo,
      );

      // 10-10 デュース状態を手動で設定
      a.setsWon = 10;
      b.setsWon = 10;

      // 合計点を大きく差をつけておく（ソートが発生すると順序が変わる）
      for (int i = 0; i < 100; i++) a.matchScoreHistory.add(1); // A: 100点
      // B はスコアなし（0点）

      // 21セット目以降（デュース突入後）を模擬
      for (int i = 1; i <= 20; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      match.currentSetIndex = 20;
      match.currentSetRecord = SetRecord(20, a.id, [a.id, b.id]);

      final orderBefore = match.players.map((p) => p.id).toList();
      match.prepareNextSet();

      // 投げ順の先頭が変わっていないこと（合計点でソートされていないこと）
      // 通常のローテーション（先頭→末尾）は起きる
      expect(
        match.players.map((p) => p.id).toList(),
        isNot(equals([a.id, b.id]..sort())),
      );
      // Aが先頭ではなくB（通常ローテーション）になっていること
      expect(match.players.first.id, b.id);
    });

    test('prepareNextSet stores set once and increments index', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 3,
        type: MatchType.raceTo,
      );

      a.currentScore = 50;
      b.currentScore = 20;

      match.prepareNextSet();
      expect(match.completedSets.length, 1);
      expect(match.currentSetIndex, 2);

      // Double-call should only finalize current set once
      match.finalizeCurrentSetIfNeeded();
      expect(match.completedSets.where((s) => s.setNumber == 1).length, 1);
    });
  });

  group('3番 (threeGame) rules', () {
    test('3セット完了で試合終了', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 3,
        type: MatchType.threeGame,
      );

      for (int i = 1; i <= 3; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      expect(match.isMatchOver, isTrue);
    });

    test('2セットではまだ試合継続', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 3,
        type: MatchType.threeGame,
      );

      for (int i = 1; i <= 2; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      expect(match.isMatchOver, isFalse);
    });

    test('合計点が高い方が勝者', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 3,
        type: MatchType.threeGame,
      );

      a.setFinalScores = [50, 40, 30]; // 計120
      b.setFinalScores = [30, 35, 40]; // 計105
      for (int i = 1; i <= 3; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchDraw, isFalse);
    });

    test('合計点が同じなら共同優勝（matchWinner=null, isMatchDraw=true）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(
        players: [a, b],
        limit: 3,
        type: MatchType.threeGame,
      );

      a.setFinalScores = [50, 30, 40]; // 計120
      b.setFinalScores = [40, 50, 30]; // 計120
      for (int i = 1; i <= 3; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id]));
      }
      expect(match.matchWinner, isNull);
      expect(match.isMatchDraw, isTrue);
      expect(
        match.threeGameTopScorers.map((p) => p.id),
        containsAll(['A', 'B']),
      );
    });

    test('3人以上で合計点1位が1人なら単独優勝', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final c = p('C', 2);
      final match = MolkkyMatch(
        players: [a, b, c],
        limit: 3,
        type: MatchType.threeGame,
      );

      a.setFinalScores = [50, 50, 50]; // 計150
      b.setFinalScores = [40, 40, 40]; // 計120
      c.setFinalScores = [30, 30, 30]; // 計90
      for (int i = 1; i <= 3; i++) {
        match.completedSets.add(SetRecord(i, a.id, [a.id, b.id, c.id]));
      }
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchDraw, isFalse);
    });

    test('投げ順が左ローテーション（ABC→BCA→CAB）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final c = p('C', 2);
      final match = MolkkyMatch(
        players: [a, b, c],
        limit: 3,
        type: MatchType.threeGame,
      );

      // Set1: A, B, C
      expect(match.players.map((p) => p.id).toList(), ['A', 'B', 'C']);

      match.prepareNextSet();
      // Set2: B, C, A
      expect(match.players.map((p) => p.id).toList(), ['B', 'C', 'A']);

      match.prepareNextSet();
      // Set3: C, A, B
      expect(match.players.map((p) => p.id).toList(), ['C', 'A', 'B']);
    });

    test('4人の投げ順ローテーション（ABCD→BCDA→CDAB）', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final c = p('C', 2);
      final d = p('D', 3);
      final match = MolkkyMatch(
        players: [a, b, c, d],
        limit: 3,
        type: MatchType.threeGame,
      );

      expect(match.players.map((p) => p.id).toList(), ['A', 'B', 'C', 'D']);

      match.prepareNextSet();
      expect(match.players.map((p) => p.id).toList(), ['B', 'C', 'D', 'A']);

      match.prepareNextSet();
      expect(match.players.map((p) => p.id).toList(), ['C', 'D', 'A', 'B']);
    });
  });
}
