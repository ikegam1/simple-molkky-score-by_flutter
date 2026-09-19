class Player {
  final String id;
  final String name;
  final int initialOrder;
  int currentScore = 0;
  int consecutiveMisses = 0;
  bool isDisqualified = false;
  int setsWon = 0;
  List<int> scoreHistory = [];
  List<int> scoreSnapshot = []; // 各投擲前の currentScore を記録（アンドゥ用）
  // 各投擲前の consecutiveMisses を記録 (アンドゥ用)。
  // scoreSnapshot と 1:1 対応。undo 時にこれを pop することで、
  // 「非ミス投擲 → undo」の際も miss count を投擲前の状態に戻せる。
  // (元は last==0 のときだけ consecutiveMisses-- していたが、
  //  非ミス投擲を undo すると processThrow で miss=0 にリセットされた値が
  //  戻せず、直後にミスを入れても 3-miss 失格が発火しなかった。)
  List<int> missSnapshot = [];
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
    scoreSnapshot = [];
    missSnapshot = [];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'initialOrder': initialOrder,
    'currentScore': currentScore,
    'consecutiveMisses': consecutiveMisses,
    'isDisqualified': isDisqualified,
    'setsWon': setsWon,
    'scoreHistory': scoreHistory,
    'scoreSnapshot': scoreSnapshot,
    'missSnapshot': missSnapshot,
    'matchScoreHistory': matchScoreHistory,
    'setFinalScores': setFinalScores,
  };

  factory Player.fromJson(Map<String, dynamic> j) {
    final p = Player(
      id: j['id'] as String,
      name: j['name'] as String,
      initialOrder: (j['initialOrder'] as num).toInt(),
    );
    p.currentScore = (j['currentScore'] as num?)?.toInt() ?? 0;
    p.consecutiveMisses = (j['consecutiveMisses'] as num?)?.toInt() ?? 0;
    p.isDisqualified = j['isDisqualified'] as bool? ?? false;
    p.setsWon = (j['setsWon'] as num?)?.toInt() ?? 0;
    p.scoreHistory = List<int>.from((j['scoreHistory'] as List?) ?? const []);
    p.scoreSnapshot = List<int>.from((j['scoreSnapshot'] as List?) ?? const []);
    // missSnapshot は 0.6.32 以前のスナップショットには含まれないので空 fallback。
    p.missSnapshot = List<int>.from((j['missSnapshot'] as List?) ?? const []);
    p.matchScoreHistory = List<int>.from(
      (j['matchScoreHistory'] as List?) ?? const [],
    );
    p.setFinalScores = List<int>.from(
      (j['setFinalScores'] as List?) ?? const [],
    );
    return p;
  }
}

class TurnRecord {
  final int turnNumber;
  final Map<String, int> scores;
  final Set<String> systemCalculatedPlayerIds;
  // 0=通常 / 1=◯囲み（単品狙い成功） / 2=□囲み（本数ガシャ成功）
  final Map<String, int> scoreAnnotations;

  TurnRecord(
    this.turnNumber,
    this.scores, {
    Set<String>? systemCalculated,
    Map<String, int>? scoreAnnotations,
  }) : systemCalculatedPlayerIds = systemCalculated ?? {},
       scoreAnnotations = scoreAnnotations ?? {};
  Map<String, dynamic> toJson() => <String, dynamic>{
    'turnNumber': turnNumber,
    'scores': scores,
    'systemCalculatedPlayerIds': systemCalculatedPlayerIds.toList(),
    'scoreAnnotations': scoreAnnotations,
  };

  factory TurnRecord.fromJson(Map<String, dynamic> j) => TurnRecord(
    (j['turnNumber'] as num).toInt(),
    Map<String, int>.from(
      (j['scores'] as Map).map((k, v) => MapEntry('$k', (v as num).toInt())),
    ),
    systemCalculated: Set<String>.from(
      (j['systemCalculatedPlayerIds'] as List?)?.map((e) => '$e') ?? const [],
    ),
    scoreAnnotations: Map<String, int>.from(
      (j['scoreAnnotations'] as Map?)?.map(
            (k, v) => MapEntry('$k', (v as num).toInt()),
          ) ??
          const {},
    ),
  );
}

class SetRecord {
  final int setNumber;
  final List<TurnRecord> turns = [];
  final Map<String, int> finalCumulativeScores = {};
  final List<String> playerOrder; // このセットの実際の投擲順
  final String starterPlayerId;
  SetRecord(this.setNumber, this.starterPlayerId, this.playerOrder);

  bool get hasContent => turns.isNotEmpty || finalCumulativeScores.isNotEmpty;
  Map<String, dynamic> toJson() => <String, dynamic>{
    'setNumber': setNumber,
    'starterPlayerId': starterPlayerId,
    'playerOrder': playerOrder,
    'turns': turns.map((t) => t.toJson()).toList(),
    'finalCumulativeScores': finalCumulativeScores,
  };

  factory SetRecord.fromJson(Map<String, dynamic> j) {
    final rec = SetRecord(
      (j['setNumber'] as num).toInt(),
      j['starterPlayerId'] as String,
      List<String>.from((j['playerOrder'] as List).map((e) => '$e')),
    );
    for (final t in (j['turns'] as List? ?? const [])) {
      rec.turns.add(TurnRecord.fromJson(Map<String, dynamic>.from(t as Map)));
    }
    rec.finalCumulativeScores.addAll(
      Map<String, int>.from(
        (j['finalCumulativeScores'] as Map?)?.map(
              (k, v) => MapEntry('$k', (v as num).toInt()),
            ) ??
            const {},
      ),
    );
    return rec;
  }
}

enum MatchType { raceTo, fixedSets, self5Turn, self6Turn, hyakin, threeGame }

class MolkkyMatch {
  List<Player> players;
  final int targetScore = 50;
  final int burstResetScore = 25;
  final int maxMisses = 3;

  /// セット数 / 先取数。
  ///
  /// **final ではない。** セット間に「2 先 → 3 先」「10 番 → 12 番」と
  /// 増やせるようにしたため (ユーザ要望 2026-09-19)。増やすのは
  /// [extendLimit] からだけで、減らすことはできない。
  int limit;
  final MatchType type;
  final int? turnLimitPerSet;
  final int? matchTimeLimitSeconds;
  int currentSetIndex = 1;

  /// **final ではない。** 中断した試合を再開するとき、保存時の値に戻すため
  /// (試合の識別や経過時間の基準になるので、再開で作り直すとずれる)。
  DateTime startTime;

  List<SetRecord> completedSets = [];
  SetRecord currentSetRecord;
  int consecutiveSuccesses = 0; // for self5Turn mode

  MolkkyMatch({
    required this.players,
    required this.limit,
    required this.type,
    this.turnLimitPerSet,
    this.matchTimeLimitSeconds,
  }) : startTime = DateTime.now(),
       currentSetRecord = SetRecord(
         1,
         players.first.id,
         players.map((p) => p.id).toList(),
       );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'players': players.map((p) => p.toJson()).toList(),
    'limit': limit,
    'type': type.name,
    'turnLimitPerSet': turnLimitPerSet,
    'matchTimeLimitSeconds': matchTimeLimitSeconds,
    'currentSetIndex': currentSetIndex,
    'startTime': startTime.toIso8601String(),
    'completedSets': completedSets.map((s) => s.toJson()).toList(),
    'currentSetRecord': currentSetRecord.toJson(),
    'consecutiveSuccesses': consecutiveSuccesses,
  };

  factory MolkkyMatch.fromJson(Map<String, dynamic> j) {
    final players =
        (j['players'] as List)
            .map((p) => Player.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
    final match = MolkkyMatch(
      players: players,
      limit: (j['limit'] as num).toInt(),
      type: MatchType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => MatchType.raceTo,
      ),
      turnLimitPerSet: (j['turnLimitPerSet'] as num?)?.toInt(),
      matchTimeLimitSeconds: (j['matchTimeLimitSeconds'] as num?)?.toInt(),
    );
    match.currentSetIndex = (j['currentSetIndex'] as num?)?.toInt() ?? 1;
    final startIso = j['startTime'] as String?;
    if (startIso != null) {
      match.startTime = DateTime.parse(startIso);
    }
    match.completedSets =
        ((j['completedSets'] as List?) ?? const [])
            .map((e) => SetRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    if (j['currentSetRecord'] != null) {
      match.currentSetRecord = SetRecord.fromJson(
        Map<String, dynamic>.from(j['currentSetRecord'] as Map),
      );
    }
    match.consecutiveSuccesses =
        (j['consecutiveSuccesses'] as num?)?.toInt() ?? 0;
    return match;
  }

  bool get _isCurrentSetAlreadyFinalized =>
      completedSets.any((s) => s.setNumber == currentSetRecord.setNumber);

  void finalizeCurrentSetIfNeeded() {
    if (_isCurrentSetAlreadyFinalized) return;

    for (var p in players) {
      currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
      p.setFinalScores.add(p.currentScore);
    }
    completedSets.add(currentSetRecord);
  }

  bool get isMatchOver {
    if (type == MatchType.self5Turn || type == MatchType.self6Turn)
      return false; // managed explicitly in GameScreen
    if (type == MatchType.hyakin) return completedSets.length >= 2;
    if (type == MatchType.threeGame) return completedSets.length >= 3;
    // 修正: completedSets.length で判定することで、指定セット数が「完了」するまで終わらないようにする
    if (type == MatchType.fixedSets) return completedSets.length >= limit;
    for (var p in players) {
      if (p.setsWon >= limit) {
        if (limit == 11) return matchWinner != null;
        return true;
      }
    }
    return false;
  }

  /// 3番: 合計点1位が複数いる場合（共同優勝）は draw として扱う
  bool get isThreeGameCoWin =>
      type == MatchType.threeGame &&
      completedSets.length >= 3 &&
      threeGameTopScorers.length > 1;

  /// 3番の合計点最高プレイヤー全員を返す（共同優勝判定用）
  List<Player> get threeGameTopScorers {
    if (type != MatchType.threeGame || completedSets.length < 3) return [];
    final maxScore = players
        .map((p) => p.totalMatchScore)
        .reduce((a, b) => a > b ? a : b);
    return players.where((p) => p.totalMatchScore == maxScore).toList();
  }

  /// 2番・10番の fixedSets で、全セット完了後にセット数・合計点数が同じ場合は引き分け
  bool get isMatchDraw {
    if (type == MatchType.threeGame) return isThreeGameCoWin;
    if (type != MatchType.fixedSets) return false;
    if (limit != 2 && limit != 10) return false;
    if (completedSets.length < limit) return false;
    if (players.length < 2) return false;
    final sorted = List<Player>.from(players)..sort((a, b) {
      final sc = b.setsWon.compareTo(a.setsWon);
      if (sc != 0) return sc;
      return b.totalMatchScore.compareTo(a.totalMatchScore);
    });
    return sorted[0].setsWon == sorted[1].setsWon &&
        sorted[0].totalMatchScore == sorted[1].totalMatchScore;
  }

  Player? get matchWinner {
    // 3番: 合計点で順位付け（共同優勝の場合は initialOrder 最小を代表として返す）
    if (type == MatchType.threeGame) {
      if (completedSets.length < 3) return null;
      if (isThreeGameCoWin)
        return null; // 共同優勝は matchWinner = null（draw ダイアログで表示）
      final sorted = List<Player>.from(players)..sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore)
          return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.initialOrder.compareTo(b.initialOrder);
      });
      return sorted.first;
    }
    if (type == MatchType.hyakin) {
      if (completedSets.length < 2) return null;
      final sorted = List<Player>.from(players);
      sorted.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore)
          return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.totalMatchThrows.compareTo(b.totalMatchThrows);
      });
      return sorted.first;
    }
    if (type == MatchType.fixedSets) {
      // マッチが終わっていない（全セット完了していない）場合は勝者を決めない
      if (completedSets.length < limit) return null;
      // 引き分け判定（2番・10番のみ）
      if (isMatchDraw) return null;
      final sorted = List<Player>.from(players);
      sorted.sort((a, b) {
        if (b.setsWon != a.setsWon) return b.setsWon.compareTo(a.setsWon);
        if (b.totalMatchScore != a.totalMatchScore)
          return b.totalMatchScore.compareTo(a.totalMatchScore);
        return a.totalMatchThrows.compareTo(b.totalMatchThrows);
      });
      return sorted.first;
    } else {
      for (var p in players) {
        if (p.setsWon >= limit) {
          if (limit == 11) {
            int secondMax = 0;
            for (var other in players)
              if (other != p && other.setsWon > secondMax)
                secondMax = other.setsWon;
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

  /// 次のセットの投げ順を計算して返す。**[players] は変更しない。**
  ///
  /// 順序は [limit] に依存する (raceTo の最終セット付近は合計点順、
  /// 2 番の 2 セット目は逆順)。セット間に limit を変えられるようにしたため、
  /// 「この limit ならどういう順序になるか」を副作用なしに求められる必要が
  /// ある。ダイアログでのプレビューにも使う。
  ///
  /// [forLimit] を渡すと、その値で計算する (既定は現在の [limit])。
  List<Player> nextSetOrder({int? forLimit}) {
    final effectiveLimit = forLimit ?? limit;
    final nextIndex = currentSetIndex + 1;
    final ordered = List<Player>.from(players);

    bool shouldSortByScore = false;
    // 11先はデュース後も投げ順を変えない（合計点による並び替えなし）
    if (type == MatchType.raceTo && effectiveLimit != 11) {
      final decidingSetThreshold = (players.length * (effectiveLimit - 1)) + 1;
      if (nextIndex >= decidingSetThreshold) shouldSortByScore = true;
    }

    if (shouldSortByScore) {
      ordered.sort((a, b) {
        if (b.totalMatchScore != a.totalMatchScore) {
          return b.totalMatchScore.compareTo(a.totalMatchScore);
        }
        if (a.totalMatchThrows != b.totalMatchThrows) {
          return a.totalMatchThrows.compareTo(b.totalMatchThrows);
        }
        return a.initialOrder.compareTo(b.initialOrder);
      });
      return ordered;
    }
    if ((type == MatchType.fixedSets &&
            effectiveLimit == 2 &&
            nextIndex == 2) ||
        (type == MatchType.hyakin && nextIndex == 2)) {
      return ordered.reversed.toList();
    }
    if (ordered.length > 1) {
      final first = ordered.removeAt(0);
      ordered.add(first);
    }
    return ordered;
  }

  /// セット数 / 先取数を増やす。**減らすことはできない。**
  ///
  /// セット間に「2 先 → 3 先」「10 番 → 12 番」と延長するためのもの
  /// (ユーザ要望 2026-09-19)。対象は raceTo / fixedSets のみ。百均や
  /// セルフ練習はセット数の概念が違うので受け付けない。
  bool extendLimit(int newLimit) {
    if (type != MatchType.raceTo && type != MatchType.fixedSets) return false;
    if (newLimit <= limit) return false;
    limit = newLimit;
    return true;
  }

  // 次のセットの準備 (基本ロジック)
  void prepareNextSet({bool manualOrder = false}) {
    // 現在のセットの結果を記録（重複追加防止）
    finalizeCurrentSetIfNeeded();

    // マッチがここで終了判定になる場合は、新しいセットレコードを作らない
    if (isMatchOver) return;

    int nextIndex = currentSetIndex + 1;

    if (!manualOrder) {
      players = nextSetOrder();
    }

    currentSetIndex = nextIndex;
    currentSetRecord = SetRecord(
      currentSetIndex,
      players.first.id,
      players.map((p) => p.id).toList(),
    );
    for (var p in players) p.resetForNewSet();
  }

  // 手動で調整した順序を適用する
  void applyManualOrder(List<Player> newOrder) {
    players = List.from(newOrder);
    // prepareNextSet で作成された currentSetRecord を新しい順序で更新
    currentSetRecord = SetRecord(
      currentSetIndex,
      players.first.id,
      players.map((p) => p.id).toList(),
    );
  }
}
