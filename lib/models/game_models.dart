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
  final Map<String, int> scores;
  TurnRecord(this.turnNumber, this.scores);
}

class SetRecord {
  final int setNumber;
  final List<TurnRecord> turns = [];
  final Map<String, int> finalCumulativeScores = {};
  final String starterPlayerId;
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
    for (var p in players) currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
    completedSets.add(currentSetRecord);
    
    int nextIndex = currentSetIndex + 1;
    bool isDecidingSetStartRule = false;
    
    // 先取形式(raceTo)の最終セットのみ、スコア順で先行を決める特殊ルールを適用
    if (type == MatchType.raceTo) {
      if (nextIndex == (limit * 2) - 1) isDecidingSetStartRule = true;
    }
    // 固定セット形式(fixedSets)は、常に交互(ローテーション)にするためここでは何もしない

    if (isDecidingSetStartRule) {
      players.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore) return b.totalMatchScore.compareTo(a.totalMatchScore);
        if (a.totalMatchThrows != b.totalMatchThrows) return a.totalMatchThrows.compareTo(b.totalMatchThrows);
        return a.initialOrder.compareTo(b.initialOrder);
      });
    } else {
      // 通常のローテーション
      if (players.length > 1) {
        final first = players.removeAt(0);
        players.add(first);
      }
    }

    currentSetIndex = nextIndex;
    currentSetRecord = SetRecord(currentSetIndex, players.first.id);
    for (var p in players) p.resetForNewSet();
  }
}
