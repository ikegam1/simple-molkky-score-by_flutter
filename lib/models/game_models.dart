
class Player {
  final String id;
  final String name;
  final int initialOrder; // 第1セットの投擲順
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0;
  List<int> scoreHistory = []; // 現在のセットの履歴
  List<int> matchScoreHistory = []; // マッチ通算の履歴

  Player({required this.id, required this.name, required this.initialOrder});

  int get totalMatchScore => matchScoreHistory.fold(0, (a, b) => a + b);
  int get totalMatchThrows => matchScoreHistory.length; // 総投擲数

  void resetForNewSet() {
    currentScore = 0;
    consecutiveMisses = 0;
    isDisqualified = false;
    scoreHistory = [];
  }
}

class MolkkyMatch {
  List<Player> players;
  final int targetScore = 50;
  final int burstResetScore = 25;
  final int maxMisses = 3;
  final int totalSetsToWin;
  int currentSetIndex = 1;

  MolkkyMatch({required this.players, this.totalSetsToWin = 2});

  void prepareNextSet() {
    currentSetIndex++;
    
    // 最終セット（決着セット）かどうかの判定
    // 誰かが「あと1セットで勝利」かつ他の誰かも競っている状態、
    // または最大セット数に達する場合を「最終セット」的な扱いとする
    bool isDecidingSet = false;
    int maxSetsPossible = (totalSetsToWin * 2) - 1;
    if (currentSetIndex == maxSetsPossible) {
      isDecidingSet = true;
    }

    if (isDecidingSet) {
      // 最終セット：合計得点 > 平均点 > 初期順位 でソート
      players.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore) {
          return b.totalMatchScore.compareTo(a.totalMatchScore);
        }
        if (b.averageMatchScore != a.averageMatchScore) {
          return b.averageMatchScore.compareTo(a.averageMatchScore);
        }
        return a.initialOrder.compareTo(b.initialOrder);
      });
    } else {
      // 通常セット：ローテーション（1番手を最後に、2番手を1番手に）
      if (players.length > 1) {
        final first = players.removeAt(0);
        players.add(first);
      }
    }

    for (var p in players) {
      p.resetForNewSet();
    }
  }

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
