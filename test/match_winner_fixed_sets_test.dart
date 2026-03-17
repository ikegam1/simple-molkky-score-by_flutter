import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

void main() {
  test('fixedSets: final winner is decided by setsWon first', () {
    final p1 = Player(id: 'a', name: 'A', initialOrder: 0);
    final p2 = Player(id: 'b', name: 'B', initialOrder: 1);

    final match = MolkkyMatch(
      players: [p1, p2],
      limit: 10,
      type: MatchType.fixedSets,
    );

    p1.setsWon = 6;
    p2.setsWon = 4;

    // Final set scores (used in tie-break only)
    p1.currentScore = 40;
    p2.currentScore = 50;

    // Simulate first 9 sets already completed
    for (int i = 1; i <= 9; i++) {
      match.completedSets.add(SetRecord(i, p1.id, [p1.id, p2.id]));
    }

    match.currentSetIndex = 10;
    match.currentSetRecord = SetRecord(10, p1.id, [p1.id, p2.id]);
    match.finalizeCurrentSetIfNeeded();

    expect(match.isMatchOver, isTrue);
    expect(match.matchWinner?.name, 'A');
  });

  test('fixedSets: when sets are tied, totalMatchScore decides winner', () {
    final p1 = Player(id: 'a', name: 'A', initialOrder: 0);
    final p2 = Player(id: 'b', name: 'B', initialOrder: 1);

    final match = MolkkyMatch(
      players: [p1, p2],
      limit: 2,
      type: MatchType.fixedSets,
    );

    p1.setsWon = 1;
    p2.setsWon = 1;

    // Simulate first set already recorded
    p1.setFinalScores.add(50);
    p2.setFinalScores.add(45);

    // Final set current scores
    p1.currentScore = 30;
    p2.currentScore = 50;

    // Simulate first set already in completedSets
    match.completedSets.add(SetRecord(1, p1.id, [p1.id, p2.id]));

    match.currentSetIndex = 2;
    match.currentSetRecord = SetRecord(2, p1.id, [p1.id, p2.id]);
    match.finalizeCurrentSetIfNeeded();

    expect(match.isMatchOver, isTrue);
    // total: A=80, B=95
    expect(match.matchWinner?.name, 'B');
  });
}
