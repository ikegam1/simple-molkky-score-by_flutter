import '../models/game_models.dart';

class ScoreDecision {
  final List<Player> leaders;

  const ScoreDecision(this.leaders);

  bool get isDraw => leaders.length != 1;
  Player? get winner => isDraw ? null : leaders.first;
}

class GameLogic {
  static void processThrow(
    Player player,
    List<int> knockedDownSkitels,
    MolkkyMatch match, {

    /// 「37 点ルール」: 37 点以上のプレイヤーが宣言型フォルトを受けた場合、
    /// 得点をバースト同様 25 点に戻す。呼び元 (client) で
    /// `player.currentScore >= 37` を検査済みの想定。knockedDownSkitels の
    /// 内容は無視され、常に points=0 (ミス扱い + consecutiveMisses++) となる。
    bool hillu37 = false,
  }) {
    if (player.isDisqualified) return;

    // アンドゥ用に投擲前スコア / 投擲前ミス回数を保存
    player.scoreSnapshot.add(player.currentScore);
    player.missSnapshot.add(player.consecutiveMisses);

    int points = 0;
    if (hillu37) {
      // 37 点ルール: 得点を 25 に戻す + ミス扱い (3 発で失格ルールは共通)
      player.currentScore = match.burstResetScore;
      player.consecutiveMisses++;
      if (player.consecutiveMisses >= match.maxMisses) {
        player.isDisqualified = true;
      }
      player.scoreHistory.add(points);
      return;
    }
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

  /// 100均モード Set 2 の投擲処理
  /// set1Score: このプレイヤーの1セット目の最終スコア
  static void processHyakinSet2Throw(
    Player player,
    List<int> knockedDownSkitels,
    MolkkyMatch match,
    int set1Score,
  ) {
    if (player.isDisqualified) return;

    // アンドゥ用に投擲前スコア / 投擲前ミス回数を保存
    player.scoreSnapshot.add(player.currentScore);
    player.missSnapshot.add(player.consecutiveMisses);

    final int target = 100 - set1Score;
    final int burstReset = 75 - set1Score;

    int points = 0;
    if (knockedDownSkitels.isEmpty) {
      points = 0;
      player.consecutiveMisses++;
      if (player.consecutiveMisses >= match.maxMisses) {
        player.currentScore = 0;
        player.isDisqualified = true;
      }
    } else {
      player.consecutiveMisses = 0;
      if (knockedDownSkitels.length == 1) {
        points = knockedDownSkitels.first;
      } else {
        points = knockedDownSkitels.length;
      }

      int nextScore = player.currentScore + points;
      if (nextScore > target) {
        player.currentScore = burstReset;
      } else {
        player.currentScore = nextScore;
      }
    }

    player.scoreHistory.add(points);
  }

  static ScoreDecision decideSetByCurrentScores(List<Player> players) {
    if (players.isEmpty) return const ScoreDecision([]);
    int bestScore = players.fold<int>(
      -1,
      (best, p) => p.currentScore > best ? p.currentScore : best,
    );
    final leaders = players.where((p) => p.currentScore == bestScore).toList();
    return ScoreDecision(leaders);
  }

  static ScoreDecision decideHyakinSet2ByCombinedTotals(List<Player> players) {
    if (players.isEmpty) return const ScoreDecision([]);
    int bestTotal = -1;
    final totals = <String, int>{};
    for (final p in players) {
      final set1 = p.setFinalScores.isNotEmpty ? p.setFinalScores.first : 0;
      final total = set1 + p.currentScore;
      totals[p.id] = total;
      if (total > bestTotal) bestTotal = total;
    }
    final leaders = players.where((p) => totals[p.id] == bestTotal).toList();
    return ScoreDecision(leaders);
  }

  static ScoreDecision decideMatchByStandings(List<Player> players) {
    if (players.isEmpty) return const ScoreDecision([]);

    final sorted = List<Player>.from(players)..sort((a, b) {
      if (b.setsWon != a.setsWon) return b.setsWon.compareTo(a.setsWon);
      if (b.totalMatchScore != a.totalMatchScore)
        return b.totalMatchScore.compareTo(a.totalMatchScore);
      return a.totalMatchThrows.compareTo(b.totalMatchThrows);
    });

    final top = sorted.first;
    final leaders =
        sorted
            .where(
              (p) =>
                  p.setsWon == top.setsWon &&
                  p.totalMatchScore == top.totalMatchScore,
            )
            .toList();
    return ScoreDecision(leaders);
  }
}
