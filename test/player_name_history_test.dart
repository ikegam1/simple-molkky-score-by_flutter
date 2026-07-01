import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/player_name_history.dart';

void main() {
  group('PlayerNameHistoryEntry serialization', () {
    test('toJson / fromJson round-trip preserves fields', () {
      final entry = PlayerNameHistoryEntry(
        name: '太郎',
        aliases: const ['たろう', 'taro'],
        count: 3,
        lastUsedAt: DateTime.utc(2026, 7, 1, 12, 34, 56),
      );
      final decoded = PlayerNameHistoryEntry.fromJson(entry.toJson());
      expect(decoded.name, '太郎');
      expect(decoded.aliases, ['たろう', 'taro']);
      expect(decoded.count, 3);
      expect(decoded.lastUsedAt, DateTime.utc(2026, 7, 1, 12, 34, 56));
    });

    test('fromJson tolerates missing / broken fields', () {
      final decoded = PlayerNameHistoryEntry.fromJson(<String, dynamic>{
        'name': '花子',
      });
      expect(decoded.name, '花子');
      expect(decoded.aliases, isEmpty);
      expect(decoded.count, 1);
      expect(decoded.lastUsedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('encodePlayerNameHistory / decodePlayerNameHistory', () {
    test('round-trips a list of entries', () {
      final now = DateTime.utc(2026, 7, 1);
      final entries = [
        PlayerNameHistoryEntry(
          name: '太郎',
          aliases: const ['たろう'],
          count: 5,
          lastUsedAt: now,
        ),
        PlayerNameHistoryEntry(
          name: '花子',
          aliases: const [],
          count: 2,
          lastUsedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      final encoded = encodePlayerNameHistory(entries);
      final decoded = decodePlayerNameHistory(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].name, '太郎');
      expect(decoded[0].aliases, ['たろう']);
      expect(decoded[0].count, 5);
      expect(decoded[1].name, '花子');
    });

    test('drops broken JSON entries silently', () {
      final entries = decodePlayerNameHistory([
        '{"name":"良品","count":1,"lastUsedAt":"2026-07-01T00:00:00.000Z"}',
        'not-json-at-all',
        '{"name":"","count":1,"lastUsedAt":"2026-07-01T00:00:00.000Z"}',
      ]);
      expect(entries.length, 1);
      expect(entries.first.name, '良品');
    });
  });

  group('seedHistoryFromLegacyPlayers', () {
    test('creates count=1 entries from legacy saved_players_v2', () {
      final legacy = [
        jsonEncode({'id': 'a', 'name': '太郎'}),
        jsonEncode({'id': 'b', 'name': '花子'}),
      ];
      final now = DateTime.utc(2026, 7, 1);
      final seeded = seedHistoryFromLegacyPlayers(legacy, now: now);
      expect(seeded.length, 2);
      expect(seeded[0].name, '太郎');
      expect(seeded[0].count, 1);
      expect(seeded[0].lastUsedAt, now);
      expect(seeded[0].aliases, isEmpty);
    });

    test('deduplicates by normalized name', () {
      final legacy = [
        jsonEncode({'id': 'a', 'name': 'Alice'}),
        jsonEncode({'id': 'b', 'name': 'alice'}),
      ];
      final seeded = seedHistoryFromLegacyPlayers(legacy);
      expect(seeded.length, 1);
      expect(seeded.first.name, 'Alice');
    });

    test('returns empty list when input is null or malformed', () {
      expect(seedHistoryFromLegacyPlayers(null), isEmpty);
      expect(
        seedHistoryFromLegacyPlayers(['not-json', '{"name":""}']),
        isEmpty,
      );
    });
  });

  group('recordPlayerNameUsage', () {
    test('adds a new entry when name is unknown', () {
      final now = DateTime.utc(2026, 7, 1, 10);
      final result = recordPlayerNameUsage(
        const <PlayerNameHistoryEntry>[],
        '太郎',
        alias: 'たろう',
        now: now,
      );
      expect(result.length, 1);
      expect(result.first.name, '太郎');
      expect(result.first.aliases, ['たろう']);
      expect(result.first.count, 1);
      expect(result.first.lastUsedAt, now);
    });

    test('bumps count and merges alias for known name (case-insensitive)', () {
      final start = DateTime.utc(2026, 6, 30);
      final now = DateTime.utc(2026, 7, 1);
      final initial = [
        PlayerNameHistoryEntry(
          name: 'Taro',
          aliases: const ['たろう'],
          count: 2,
          lastUsedAt: start,
        ),
      ];
      final result = recordPlayerNameUsage(
        initial,
        'taro',
        alias: 'たろー',
        now: now,
      );
      expect(result.length, 1);
      expect(result.first.name, 'taro');
      expect(result.first.count, 3);
      expect(result.first.aliases, ['たろう', 'たろー']);
      expect(result.first.lastUsedAt, now);
    });

    test('does not duplicate alias equal to name', () {
      final result = recordPlayerNameUsage(
        const <PlayerNameHistoryEntry>[],
        'たろう',
        alias: 'たろう',
      );
      expect(result.first.aliases, isEmpty);
    });

    test('ignores blank name entirely', () {
      final result = recordPlayerNameUsage(
        const <PlayerNameHistoryEntry>[],
        '   ',
        alias: 'a',
      );
      expect(result, isEmpty);
    });
  });

  group('removePlayerNameHistoryEntry', () {
    test('removes matching entry by normalized name', () {
      final now = DateTime.utc(2026, 7, 1);
      final entries = [
        PlayerNameHistoryEntry(
          name: 'Alice',
          aliases: const [],
          count: 1,
          lastUsedAt: now,
        ),
        PlayerNameHistoryEntry(
          name: 'Bob',
          aliases: const [],
          count: 2,
          lastUsedAt: now,
        ),
      ];
      final result = removePlayerNameHistoryEntry(entries, 'alice');
      expect(result.length, 1);
      expect(result.first.name, 'Bob');
    });
  });

  group('suggestPlayerNames', () {
    late List<PlayerNameHistoryEntry> entries;
    final now = DateTime.utc(2026, 7, 1);

    setUp(() {
      entries = [
        PlayerNameHistoryEntry(
          name: '太郎',
          aliases: const ['たろう'],
          count: 5,
          lastUsedAt: now,
        ),
        PlayerNameHistoryEntry(
          name: '太一',
          aliases: const ['たいち'],
          count: 3,
          lastUsedAt: now,
        ),
        PlayerNameHistoryEntry(
          name: '花子',
          aliases: const ['はなこ'],
          count: 10,
          lastUsedAt: now.subtract(const Duration(days: 2)),
        ),
        PlayerNameHistoryEntry(
          name: 'Alice',
          aliases: const [],
          count: 1,
          lastUsedAt: now.subtract(const Duration(days: 5)),
        ),
      ];
    });

    test('empty input returns TopN sorted by count desc / lastUsedAt desc', () {
      final result = suggestPlayerNames(
        entries,
        input: '',
        excludeNames: <String>{},
        limit: 3,
      );
      expect(result.map((e) => e.name).toList(), ['花子', '太郎', '太一']);
    });

    test('partial match on name (case-insensitive)', () {
      final result = suggestPlayerNames(
        entries,
        input: 'ali',
        excludeNames: <String>{},
      );
      expect(result.map((e) => e.name).toList(), ['Alice']);
    });

    test('partial match on alias (kana pre-conversion)', () {
      final result = suggestPlayerNames(
        entries,
        input: 'たろ',
        excludeNames: <String>{},
      );
      expect(result.map((e) => e.name).toList(), ['太郎']);
    });

    test('multiple matches sort by count desc → lastUsedAt desc', () {
      final result = suggestPlayerNames(
        entries,
        input: '太',
        excludeNames: <String>{},
      );
      expect(result.map((e) => e.name).toList(), ['太郎', '太一']);
    });

    test('excludeNames removes already-registered players (normalized)', () {
      final result = suggestPlayerNames(
        entries,
        input: '',
        excludeNames: <String>{'太郎', 'alice'},
        limit: 5,
      );
      expect(result.map((e) => e.name).toList(), ['花子', '太一']);
    });

    test('limit caps the number of returned suggestions', () {
      final result = suggestPlayerNames(
        entries,
        input: '',
        excludeNames: <String>{},
        limit: 2,
      );
      expect(result.length, 2);
    });
  });
}
