import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

void main() {
  test('Player.resetForNewSet resets per-set state only', () {
    final player = Player(id: 'p1', name: 'Player 1', initialOrder: 0)
      ..currentScore = 42
      ..consecutiveMisses = 2
      ..isDisqualified = true
      ..setsWon = 3
      ..scoreHistory = [5, 7, 9]
      ..setFinalScores = [50, 48];

    player.resetForNewSet();

    expect(player.currentScore, 0);
    expect(player.consecutiveMisses, 0);
    expect(player.isDisqualified, isFalse);
    expect(player.scoreHistory, isEmpty);

    // match-level values remain
    expect(player.setsWon, 3);
    expect(player.setFinalScores, [50, 48]);
  });
}
