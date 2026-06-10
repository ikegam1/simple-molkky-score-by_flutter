import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_models.dart';

class LivePlayer {
  final String name;
  final int currentScore;
  final int setsWon;
  final List<int> recentThrows;
  final bool isDisqualified;

  const LivePlayer({
    required this.name,
    required this.currentScore,
    required this.setsWon,
    required this.recentThrows,
    required this.isDisqualified,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'currentScore': currentScore,
    'setsWon': setsWon,
    'recentThrows': recentThrows,
    'isDisqualified': isDisqualified,
  };

  factory LivePlayer.fromMap(Map<String, dynamic> map) => LivePlayer(
    name: (map['name'] as String?) ?? '',
    currentScore: (map['currentScore'] as num?)?.toInt() ?? 0,
    setsWon: (map['setsWon'] as num?)?.toInt() ?? 0,
    recentThrows:
        (map['recentThrows'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [],
    isDisqualified: (map['isDisqualified'] as bool?) ?? false,
  );

  factory LivePlayer.fromPlayer(Player p) {
    final history = p.scoreHistory;
    final start = history.length > 3 ? history.length - 3 : 0;
    return LivePlayer(
      name: p.name,
      currentScore: p.currentScore,
      setsWon: p.setsWon,
      recentThrows: history.sublist(start),
      isDisqualified: p.isDisqualified,
    );
  }
}

class LiveMatch {
  final String liveId;
  final String matchId;
  final List<LivePlayer> players;
  final int currentPlayerIndex;
  final int currentTurnInSet;
  final int currentSetIndex;
  final int matchTypeIndex;
  final bool isEnded;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LiveMatch({
    required this.liveId,
    required this.matchId,
    required this.players,
    required this.currentPlayerIndex,
    required this.currentTurnInSet,
    required this.currentSetIndex,
    required this.matchTypeIndex,
    required this.isEnded,
    required this.createdAt,
    required this.expiresAt,
  });

  MatchType get matchType {
    if (matchTypeIndex < 0 || matchTypeIndex >= MatchType.values.length) {
      return MatchType.fixedSets;
    }
    return MatchType.values[matchTypeIndex];
  }

  String get matchTypeLabel {
    switch (matchType) {
      case MatchType.raceTo:
        return 'Race to';
      case MatchType.fixedSets:
        return 'Fixed Sets';
      case MatchType.hyakin:
        return 'Hyakin';
      case MatchType.self5Turn:
        return 'Self 5-Turn';
      case MatchType.self6Turn:
        return 'Self 6-Turn';
      case MatchType.threeGame:
        return '3-Game';
    }
  }

  Map<String, dynamic> toMap() => {
    'liveId': liveId,
    'matchId': matchId,
    'players': players.map((p) => p.toMap()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'currentTurnInSet': currentTurnInSet,
    'currentSetIndex': currentSetIndex,
    'matchTypeIndex': matchTypeIndex,
    'isEnded': isEnded,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
  };

  factory LiveMatch.fromMap(Map<String, dynamic> map) => LiveMatch(
    liveId: (map['liveId'] as String?) ?? '',
    matchId: (map['matchId'] as String?) ?? '',
    players:
        (map['players'] as List?)
            ?.map(
              (e) => LivePlayer.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [],
    currentPlayerIndex: (map['currentPlayerIndex'] as num?)?.toInt() ?? 0,
    currentTurnInSet: (map['currentTurnInSet'] as num?)?.toInt() ?? 1,
    currentSetIndex: (map['currentSetIndex'] as num?)?.toInt() ?? 1,
    matchTypeIndex: (map['matchTypeIndex'] as num?)?.toInt() ?? 1,
    isEnded: (map['isEnded'] as bool?) ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt:
        (map['expiresAt'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(hours: 24)),
  );
}
