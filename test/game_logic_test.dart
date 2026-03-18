import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

void main() {
  group('GameLogic.processThrow', () {
    late Player p;
    late MolkkyMatch match;

    setUp(() {
      p = Player(id: 'p1', name: 'Player 1', initialOrder: 0);
      match = MolkkyMatch(players: [p], limit: 1, type: MatchType.fixedSets);
    });

    test('single skittle scores by number', () {
      GameLogic.processThrow(p, [12], match);
      expect(p.currentScore, 12);
      expect(p.scoreHistory.last, 12);
      expect(p.consecutiveMisses, 0);
    });

    test('multiple skittles scores by count', () {
      GameLogic.processThrow(p, [1, 3, 7], match);
      expect(p.currentScore, 3);
      expect(p.scoreHistory.last, 3);
    });

    test('burst resets to 25 when over 50', () {
      p.currentScore = 49;
      GameLogic.processThrow(p, [2], match); // +2 => 51 => burst
      expect(p.currentScore, 25);
      expect(p.scoreHistory.last, 2);
    });

    test('three consecutive misses disqualifies player', () {
      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match);
      expect(p.isDisqualified, isFalse);

      GameLogic.processThrow(p, [], match);
      expect(p.isDisqualified, isTrue);
      expect(p.consecutiveMisses, 3);
    });

    test('hit after misses resets miss counter', () {
      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match);
      expect(p.consecutiveMisses, 2);

      GameLogic.processThrow(p, [10], match);
      expect(p.consecutiveMisses, 0);
      expect(p.currentScore, 10);
    });
  });
}
