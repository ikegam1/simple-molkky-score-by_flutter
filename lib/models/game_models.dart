
class Player {
  final String id;
  final String name;
  final int initialOrder;
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0;
  List<int> scoreHistory = []; // 現在のセットの投擲履歴
  List<int> matchScoreHistory = []; // 全セット通算の投擲履歴
  List<int> setFinalScores = []; // 各セット終了時のスコア

  Player({required this.id, required this.name, required this.initialOrder});

  int get totalMatchScore => matchScoreHistory.fold(0, (a, b) => a + b);
  int get totalMatchThrows => matchScoreHistory.length;

  void resetForNewSet() {
    currentScore = 0;
    consecutiveMisses = 0;
    isDisqualified = false;
    scoreHistory = [];
  }
}

enum MatchType { raceTo, fixedSets }

class MolkkyMatch {
  List<Player> players;
  final int targetScore = 50;
  final int burstResetScore = 25;
  final int maxMisses = 3;
  final int limit; // 先取数 or 合計セット数
  final MatchType type;
  int currentSetIndex = 1;
  final DateTime startTime;

  MolkkyMatch({
    required this.players,
    required this.limit,
    required this.type,
  }) : startTime = DateTime.now();

  bool get isMatchOver {
    if (type == MatchType.fixedSets) {
      return currentSetIndex > limit;
    } else {
      // Race To (2先, 3先, 11先...)
      if (limit == 11) {
        // 11先デュースルール
        return matchWinner != null;
      } else {
        for (var p in players) {
          if (p.setsWon >= limit) return true;
        }
      }
    }
    return false;
  }

  Player? get matchWinner {
    if (type == MatchType.fixedSets) {
      if (currentSetIndex <= limit) return null;
      // セット数終了後の勝者（セット獲得数 > 通算得点 > 投数 で判定）
      players.sort((a, b) {
        if (b.setsWon != a.setsWon) return b.setsWon.compareTo(a.setsWon);
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.totalMatchThrows.compareTo(b.totalMatchThrows);
      });
      return players.first;
    } else {
      // Race To
      if (limit == 11) {
        int maxSets = 0;
        Player? top;
        for (var p in players) {
          if (p.setsWon > maxSets) {
            maxSets = p.setsWon;
            top = p;
          }
        }
        if (maxSets < 11) return null;
        int second = 0;
        for (var p in players) {
          if (p != top && p.setsWon > second) second = p.setsWon;
        }
        if (maxSets >= 10 && second >= 10) {
          if (maxSets - second >= 2) return top;
          return null;
        }
        return top;
      } else {
        for (var p in players) {
          if (p.setsWon >= limit) return p;
        }
      }
    }
    return null;
  }

  void prepareNextSet() {
    currentSetIndex++;
    if (isMatchOver) return;

    // 最終セット判定
    bool isDeciding = false;
    if (type == MatchType.raceTo) {
      int maxPossible = (limit * 2) - 1;
      if (currentSetIndex == maxPossible) isDeciding = true;
    } else {
      if (currentSetIndex == limit) isDeciding = true;
    }

    if (isDeciding) {
      players.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        if (a.totalMatchThrows != b.totalMatchThrows) return a.totalMatchThrows.compareTo(b.totalMatchThrows);
        return a.initialOrder.compareTo(b.initialOrder);
      });
    } else {
      if (players.length > 1) {
        final first = players.removeAt(0);
        players.add(first);
      }
    }

    for (var p in players) p.resetForNewSet();
  }
}
