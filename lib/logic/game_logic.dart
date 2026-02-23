
import '../models/game_models.dart';

class GameLogic {
  static void processThrow(Player player, List<int> knockedDownSkitels, MolkkyMatch match) {
    if (player.isDisqualified) return;

    int points = 0;
    if (knockedDownSkitels.isEmpty) {
      // ミス
      points = 0;
      player.consecutiveMisses++;
      if (player.consecutiveMisses >= match.maxMisses) {
        player.isDisqualified = true;
      }
    } else {
      // ミス回数をリセット
      player.consecutiveMisses = 0;

      if (knockedDownSkitels.length == 1) {
        // 1本だけ倒れた場合はその数字が得点
        points = knockedDownSkitels.first;
      } else {
        // 2本以上倒れた場合はその本数が得点
        points = knockedDownSkitels.length;
      }

      // スコア加算
      int nextScore = player.currentScore + points;
      if (nextScore > match.targetScore) {
        // バースト：指定点数（25点）に戻る
        player.currentScore = match.burstResetScore;
      } else {
        player.currentScore = nextScore;
      }
    }

    player.scoreHistory.add(points);
  }

  static bool checkSetWinner(Player player, MolkkyMatch match) {
    if (player.currentScore == match.targetScore) {
      player.setsWon++;
      return true;
    }
    return false;
  }
}
