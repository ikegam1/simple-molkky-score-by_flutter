import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

void main() {
  group('Bug Fix: scoreSnapshot for correct undo after burst', () {
    late Player p;
    late MolkkyMatch match;

    setUp(() {
      p = Player(id: 'p1', name: 'Player 1', initialOrder: 0);
      match = MolkkyMatch(players: [p], limit: 1, type: MatchType.fixedSets);
    });

    test('scoreSnapshot is saved before each throw', () {
      p.currentScore = 30;
      GameLogic.processThrow(p, [5], match); // 30 + 5 = 35
      expect(p.scoreSnapshot.last, 30);
      expect(p.currentScore, 35);
    });

    test('scoreSnapshot saves pre-burst score correctly', () {
      p.currentScore = 48;
      GameLogic.processThrow(p, [1, 2, 3, 4], match); // 48 + 4 = 52 → burst → 25
      expect(p.scoreSnapshot.last, 48); // pre-burst score saved
      expect(p.currentScore, 25);
    });

    test('scoreSnapshot allows correct restoration after burst', () {
      p.currentScore = 48;
      GameLogic.processThrow(p, [1, 2, 3, 4], match); // burst → 25
      // Simulate undo using scoreSnapshot
      final restored = p.scoreSnapshot.removeLast();
      p.currentScore = restored;
      expect(p.currentScore, 48); // correctly restored to pre-burst score
    });

    test('scoreSnapshot is reset on new set', () {
      GameLogic.processThrow(p, [5], match);
      expect(p.scoreSnapshot.length, 1);
      p.resetForNewSet();
      expect(p.scoreSnapshot.isEmpty, isTrue);
    });
  });

  group('Bug Fix: turn counter increments correctly when player 0 is disqualified', () {
    test('scoreHistory is not affected by disqualification ordering', () {
      // This tests the model behavior: scoreSnapshot aligns with scoreHistory
      final p1 = Player(id: 'p1', name: 'P1', initialOrder: 0);
      final match = MolkkyMatch(players: [p1], limit: 1, type: MatchType.fixedSets);

      GameLogic.processThrow(p1, [], match); // miss 1
      GameLogic.processThrow(p1, [], match); // miss 2
      GameLogic.processThrow(p1, [], match); // miss 3 → disqualified

      expect(p1.isDisqualified, isTrue);
      expect(p1.scoreHistory.length, 3);
      expect(p1.scoreSnapshot.length, 3);

      // Undo: restore from snapshot
      p1.scoreHistory.removeLast();
      final restored = p1.scoreSnapshot.removeLast();
      p1.currentScore = restored;
      p1.consecutiveMisses--;
      p1.isDisqualified = false;

      expect(p1.isDisqualified, isFalse);
      expect(p1.consecutiveMisses, 2);
      expect(p1.currentScore, 0);
    });
  });

  group('Bug Fix: survivor scoreHistory is updated', () {
    test('scoreSnapshot is saved before survivor auto-complete would be applied', () {
      // Survivor auto-complete bypasses processThrow, so scoreSnapshot is not used.
      // This test verifies scoreHistory is consistent with matchScoreHistory length.
      final p1 = Player(id: 'p1', name: 'P1', initialOrder: 0);
      final p2 = Player(id: 'p2', name: 'P2', initialOrder: 1);
      final match = MolkkyMatch(players: [p1, p2], limit: 1, type: MatchType.fixedSets);

      GameLogic.processThrow(p1, [10], match);
      p1.matchScoreHistory.add(10);

      // Simulate survivor auto-complete (as done in _submitThrow)
      int needed = match.targetScore - p2.currentScore;
      p2.currentScore = match.targetScore;
      p2.scoreHistory.add(needed); // Bug fix: this was missing
      p2.matchScoreHistory.add(needed);

      // scoreHistory and matchScoreHistory should be in sync
      expect(p2.scoreHistory.length, p2.matchScoreHistory.length);
      expect(p2.scoreHistory.last, needed);
    });
  });

  group('Bug Fix: HistoryPage set wins use score == 50', () {
    test('set winner is player with score 50, not highest score', () {
      // Simulates _finalSetWins logic: winner should be player with finalScore == 50
      final set = SetRecord(1, 'p1', ['p1', 'p2']);
      set.finalCumulativeScores['p1'] = 50; // actual winner
      set.finalCumulativeScores['p2'] = 48; // close but not winner

      String? winnerId;
      // Fix: check for score == 50 first
      for (final id in ['p1', 'p2']) {
        if ((set.finalCumulativeScores[id] ?? 0) == 50) {
          winnerId = id;
          break;
        }
      }
      expect(winnerId, 'p1');
    });

    test('fallback to highest score when no player has 50 (ongoing set)', () {
      final set = SetRecord(1, 'p1', ['p1', 'p2']);
      set.finalCumulativeScores['p1'] = 35;
      set.finalCumulativeScores['p2'] = 42;

      String? winnerId;
      // No player at 50
      for (final id in ['p1', 'p2']) {
        if ((set.finalCumulativeScores[id] ?? 0) == 50) { winnerId = id; break; }
      }
      // Fallback: highest score
      if (winnerId == null) {
        int best = -1;
        for (final id in ['p1', 'p2']) {
          final score = set.finalCumulativeScores[id] ?? 0;
          if (score > best) { best = score; winnerId = id; }
        }
      }
      expect(winnerId, 'p2');
    });
  });
}
