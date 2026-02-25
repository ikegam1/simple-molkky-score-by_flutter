class Player {
  final String id;
  final String name;
  final int initialOrder;
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0;
  List<int> scoreHistory = []; 
  List<int> matchScoreHistory = [];
  List<int> setFinalScores = [];

  Player({required this.id, required this.name, required this.initialOrder});

  int get totalMatchScore => setFinalScores.fold(0, (a, b) => a + b);
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
  final Map<String, int> scores;
  final Set<String> systemCalculatedPlayerIds;
  TurnRecord(this.turnNumber, this.scores, {Set<String>? systemCalculated}) 
    : systemCalculatedPlayerIds = systemCalculated ?? {};
}

class SetRecord {
  final int setNumber;
  final List<TurnRecord> turns = [];
  final Map<String, int> finalCumulativeScores = {};
  final List<String> playerOrder; // このセットの実際の投擲順
  final String starterPlayerId;
  SetRecord(this.setNumber, this.starterPlayerId, this.playerOrder);
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
  
  List<SetRecord> completedSets = [];
  SetRecord currentSetRecord;

  MolkkyMatch({
    required this.players,
    required this.limit,
    required this.type,
  }) : startTime = DateTime.now(),
       currentSetRecord = SetRecord(1, players.first.id, players.map((p) => p.id).toList());

  bool get isMatchOver {
    if (type == MatchType.fixedSets) return currentSetIndex >= limit;
    for (var p in players) {
      if (p.setsWon >= limit) {
        if (limit == 11) return matchWinner != null;
        return true;
      }
    }
    return false;
  }

  Player? get matchWinner {
    if (type == MatchType.fixedSets) {
      if (currentSetIndex < limit) return null;
      final sorted = List<Player>.from(players);
      sorted.sort((a, b) {
        if (b.setsWon != a.setsWon) return b.setsWon.compareTo(a.setsWon);
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.totalMatchThrows.compareTo(b.totalMatchThrows);
      });
      return sorted.first;
    } else {
      for (var p in players) {
        if (p.setsWon >= limit) {
          if (limit == 11) {
            int secondMax = 0;
            for (var other in players) if (other != p && other.setsWon > secondMax) secondMax = other.setsWon;
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
    for (var p in players) {
      currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
      p.setFinalScores.add(p.currentScore);
    }
    completedSets.add(currentSetRecord);
    
    int nextIndex = currentSetIndex + 1;
    bool shouldSortByScore = false;
    
    if (type == MatchType.raceTo) {
      // 全員に先行が1回ずつ回るサイクルが終わった後の決着セット判定
      // 例: 4人、2先(limit=2) なら 4 * (2-1) + 1 = 5セット目
      int decidingSetThreshold = (players.length * (limit - 1)) + 1;
      if (nextIndex == decidingSetThreshold) {
        shouldSortByScore = true;
      }
    }

    if (shouldSortByScore) {
      // 決着セット：スコア順
      players.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        if (a.totalMatchThrows != b.totalMatchThrows) return a.totalMatchThrows.compareTo(b.totalMatchThrows);
        return a.initialOrder.compareTo(b.initialOrder);
      });
    } else {
      // 特殊ルール: 「2番」(Fixed 2 sets) の第2セットは逆順 (表裏)
      if (type == MatchType.fixedSets && limit == 2 && nextIndex == 2) {
        players = players.reversed.toList();
      } else {
        // 通常セット：ローテーション (スライド)
        if (players.length > 1) {
          final first = players.removeAt(0);
          players.add(first);
        }
      }
    }

    currentSetIndex = nextIndex;
    // playerOrder を今の players リストの状態から固定
    currentSetRecord = SetRecord(currentSetIndex, players.first.id, players.map((p) => p.id).toList());
    for (var p in players) p.resetForNewSet();
  }
}
