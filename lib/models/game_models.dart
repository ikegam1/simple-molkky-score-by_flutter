
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
    for (var player in players) {
      if (player.setsWon >= totalSetsToWin) return player;
    }
    return null;
  }
}
