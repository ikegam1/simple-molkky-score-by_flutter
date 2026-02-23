
class Player {
  final String id;
  final String name;
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0; // 獲得セット数
  List<int> scoreHistory = [];

  Player({required this.id, required this.name});

  void resetForNewSet() {
    currentScore = 0;
    consecutiveMisses = 0;
    isDisqualified = false;
    scoreHistory = [];
  }
}

class MolkkyMatch {
  final List<Player> players;
  final int targetScore = 50;
  final int burstResetScore = 25;
  final int maxMisses = 3;
  final int totalSetsToWin; // 何セット先取で勝利か
  int currentSetIndex = 1;

  MolkkyMatch({required this.players, this.totalSetsToWin = 2});

  Player? get matchWinner {
    if (totalSetsToWin == 11) {
      // 11先独自のデュースルール
      int maxSets = 0;
      Player? topPlayer;
      for (var p in players) {
        if (p.setsWon > maxSets) {
          maxSets = p.setsWon;
          topPlayer = p;
        }
      }

      if (maxSets >= 11) {
        // 全員の中で2番目に高いスコアを取得
        int secondMax = 0;
        for (var p in players) {
          if (p != topPlayer && p.setsWon > secondMax) {
            secondMax = p.setsWon;
          }
        }
        
        // 10-10以降は2点差が必要
        if (maxSets >= 10 && secondMax >= 10) {
          if (maxSets - secondMax >= 2) return topPlayer;
          return null;
        }
        return topPlayer;
      }
      return null;
    } else {
      // 通常ルール
      for (var player in players) {
        if (player.setsWon >= totalSetsToWin) return player;
      }
      return null;
    }
  }
}
