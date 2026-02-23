class Player {
  final String id;
  final String name;
  final int initialOrder;
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0;
  
  // 履歴表示用
  List<int> scoreHistory = []; 
  List<int> matchScoreHistory = [];

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

class TurnRecord {
  final int turnNumber;
  final Map<String, int> scores; // playerId -> score in this turn
  TurnRecord(this.turnNumber, this.scores);
}

class SetRecord {
  final int setNumber;
  final List<TurnRecord> turns = [];
  final Map<String, int> finalCumulativeScores = {}; // セット終了時の全プレイヤーの通算得点
  final String starterPlayerId; // このセットの先行
  SetRecord(this.setNumber, this.starterPlayerId);
}

enum MatchType { raceTo, fixedSets }

class MolkkyMatch {
  List<Player> players;
  final int targetScore = 50;
  final int burstResetScore = 25;
  final int maxMisses = 3;
  final int limit;
  final MatchType type;
  int currentSetIndex = 1;
  final DateTime startTime;
  
  // 構造化された履歴
  List<SetRecord> completedSets = [];
  SetRecord currentSetRecord;

  MolkkyMatch({
    required this.players,
    required this.limit,
    required this.type,
  }) : startTime = DateTime.now(),
       currentSetRecord = SetRecord(1, players.first.id);

  bool get isMatchOver {
    if (type == MatchType.fixedSets) return currentSetIndex >= limit;
    if (limit == 11) return matchWinner != null;
    for (var p in players) if (p.setsWon >= limit) return true;
    return false;
  }

  Player? get matchWinner {
    if (type == MatchType.fixedSets) {
      if (currentSetIndex < limit) return null; // まだ終わっていない
      final sorted = List<Player>.from(players);
      sorted.sort((a, b) {
        if (b.setsWon != a.setsWon) return b.setsWon.compareTo(a.setsWon);
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.totalMatchThrows.compareTo(b.totalMatchThrows);
      });
      return sorted.first;
    } else {
      // Race To (2先, 11先など)
      for (var p in players) {
        if (p.setsWon >= limit) {
          // 11先の場合は2点差チェックが必要
          if (limit == 11) {
            int secondMax = 0;
            for (var other in players) {
              if (other != p && other.setsWon > secondMax) secondMax = other.setsWon;
            }
            if (p.setsWon >= 10 && secondMax >= 10) {
              if (p.setsWon - secondMax >= 2) return p;
              return null;
            }
          }
          return p;
        }
      }
    }
    return null;
  }

  void prepareNextSet() {
    // 現在のセットを通算履歴に保存
    for (var p in players) {
      currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
    }
    completedSets.add(currentSetRecord);
    
    currentSetIndex++;
    
    // 順位入れ替えロジック
    bool isDeciding = false;
    if (type == MatchType.raceTo) {
      if (currentSetIndex == (limit * 2) - 1) isDeciding = true;
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

    // 新しいセットの記録準備
    currentSetRecord = SetRecord(currentSetIndex, players.first.id);
    for (var p in players) p.resetForNewSet();
  }
}
