import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';
import 'package:simple_molkky_score/models/live_match.dart';

void main() {
  group('LivePlayer.fromPlayer', () {
    test('recentThrows は最新3投のみを切り出す', () {
      final p =
          Player(id: 'p1', name: 'Alice', initialOrder: 0)
            ..currentScore = 35
            ..setsWon = 1
            ..scoreHistory.addAll([6, 10, 12, 0, 7]);

      final live = LivePlayer.fromPlayer(p);

      expect(live.name, 'Alice');
      expect(live.currentScore, 35);
      expect(live.setsWon, 1);
      expect(live.recentThrows, [12, 0, 7]);
      expect(live.isDisqualified, false);
    });

    test('scoreHistory が3投未満ならすべて返る', () {
      final p = Player(id: 'p1', name: 'Bob', initialOrder: 0)
        ..scoreHistory.addAll([5, 3]);

      final live = LivePlayer.fromPlayer(p);

      expect(live.recentThrows, [5, 3]);
    });

    test('scoreHistory が空ならrecentThrowsも空', () {
      final p = Player(id: 'p1', name: 'Carol', initialOrder: 0);
      final live = LivePlayer.fromPlayer(p);
      expect(live.recentThrows, isEmpty);
    });

    test('isDisqualified が正しく反映される', () {
      final p = Player(id: 'p1', name: 'Dan', initialOrder: 0)
        ..isDisqualified = true;
      final live = LivePlayer.fromPlayer(p);
      expect(live.isDisqualified, true);
    });
  });

  group('LivePlayer.toMap / fromMap', () {
    test('toMap → fromMap でデータが復元される', () {
      const original = LivePlayer(
        name: 'Eve',
        currentScore: 42,
        setsWon: 2,
        recentThrows: [10, 11, 12],
        isDisqualified: false,
      );

      final restored = LivePlayer.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.currentScore, original.currentScore);
      expect(restored.setsWon, original.setsWon);
      expect(restored.recentThrows, original.recentThrows);
      expect(restored.isDisqualified, original.isDisqualified);
    });

    test('fromMap は欠損フィールドにデフォルト値を適用', () {
      final live = LivePlayer.fromMap({});
      expect(live.name, '');
      expect(live.currentScore, 0);
      expect(live.setsWon, 0);
      expect(live.recentThrows, isEmpty);
      expect(live.isDisqualified, false);
    });
  });

  group('LiveMatch', () {
    test('matchTypeIndex から MatchType を復元できる', () {
      for (final type in MatchType.values) {
        final live = LiveMatch(
          liveId: 'x',
          matchId: 'm',
          players: const [],
          currentPlayerIndex: 0,
          currentTurnInSet: 1,
          currentSetIndex: 1,
          matchTypeIndex: MatchType.values.indexOf(type),
          isEnded: false,
          createdAt: DateTime(2026, 1, 1),
          expiresAt: DateTime(2026, 1, 2),
        );
        expect(live.matchType, type);
      }
    });

    test('範囲外の matchTypeIndex は fixedSets にフォールバック', () {
      final live = LiveMatch(
        liveId: 'x',
        matchId: 'm',
        players: const [],
        currentPlayerIndex: 0,
        currentTurnInSet: 1,
        currentSetIndex: 1,
        matchTypeIndex: 999,
        isEnded: false,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 2),
      );
      expect(live.matchType, MatchType.fixedSets);
    });

    test('matchTypeLabel が各 MatchType に対応した文字列を返す', () {
      final expectations = {
        MatchType.raceTo: 'Race to',
        MatchType.fixedSets: 'Fixed Sets',
        MatchType.hyakin: 'Hyakin',
        MatchType.self5Turn: 'Self 5-Turn',
        MatchType.self6Turn: 'Self 6-Turn',
        MatchType.threeGame: '3-Game',
      };
      for (final entry in expectations.entries) {
        final live = LiveMatch(
          liveId: 'x',
          matchId: 'm',
          players: const [],
          currentPlayerIndex: 0,
          currentTurnInSet: 1,
          currentSetIndex: 1,
          matchTypeIndex: MatchType.values.indexOf(entry.key),
          isEnded: false,
          createdAt: DateTime(2026, 1, 1),
          expiresAt: DateTime(2026, 1, 2),
        );
        expect(live.matchTypeLabel, entry.value);
      }
    });
  });
}
