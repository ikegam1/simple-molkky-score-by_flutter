import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

Player p(String id, int order) => Player(id: id, name: id, initialOrder: order);

void main() {
  group('MolkkyMatch fixedSets / raceTo rules', () {
    test('fixedSets winner: setsWon first, then totalMatchScore on tie', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(players: [a, b], limit: 10, type: MatchType.fixedSets);

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

    test('fixedSets (limit=2) is a draw when sets and total scores are tied', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(players: [a, b], limit: 2, type: MatchType.fixedSets);

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
    });

    test('fixedSets (limit=3) tie-break by totalMatchThrows after score tie', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(players: [a, b], limit: 3, type: MatchType.fixedSets);

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
    });

    test('raceTo 11 requires 2-set lead after 10-10+', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(players: [a, b], limit: 11, type: MatchType.raceTo);

      a.setsWon = 11;
      b.setsWon = 10;
      expect(match.matchWinner, isNull);
      expect(match.isMatchOver, isFalse);

      a.setsWon = 12;
      b.setsWon = 10;
      expect(match.matchWinner?.id, 'A');
      expect(match.isMatchOver, isTrue);
    });

    test('prepareNextSet stores set once and increments index', () {
      final a = p('A', 0);
      final b = p('B', 1);
      final match = MolkkyMatch(players: [a, b], limit: 3, type: MatchType.raceTo);

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
}
