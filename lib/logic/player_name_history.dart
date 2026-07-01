import 'dart:convert';

/// プレイヤー名の使用履歴 1 件分。
class PlayerNameHistoryEntry {
  final String name;

  /// IME 変換前のキータイプ（例: "たろう" → "太郎" の "たろう"）等の別名。
  /// サジェスト時の一致判定に使う。
  final List<String> aliases;
  final int count;
  final DateTime lastUsedAt;

  const PlayerNameHistoryEntry({
    required this.name,
    required this.aliases,
    required this.count,
    required this.lastUsedAt,
  });

  factory PlayerNameHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    return PlayerNameHistoryEntry(
      name: (json['name'] as String?) ?? '',
      aliases:
          rawAliases is List
              ? rawAliases
                  .whereType<String>()
                  .where((a) => a.isNotEmpty)
                  .toList()
              : const <String>[],
      count: (json['count'] as num?)?.toInt() ?? 1,
      lastUsedAt:
          DateTime.tryParse((json['lastUsedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'aliases': aliases,
    'count': count,
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  PlayerNameHistoryEntry copyWith({
    String? name,
    List<String>? aliases,
    int? count,
    DateTime? lastUsedAt,
  }) => PlayerNameHistoryEntry(
    name: name ?? this.name,
    aliases: aliases ?? this.aliases,
    count: count ?? this.count,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}

/// SharedPreferences に保存するキー。値は entry を jsonEncode した文字列リスト。
const String kPlayerNameHistoryPrefsKey = 'player_name_history_v1';

/// 既存プレイヤーリストから履歴を初期シードするための旧キー。
const String kLegacyRegisteredPlayersPrefsKey = 'saved_players_v2';

/// 名前の比較用正規化。大文字小文字を無視し、前後空白を除去する。
String normalizePlayerName(String name) => name.trim().toLowerCase();

/// サジェスト時のマッチング用に、ひらがなをカタカナに揃えたうえで
/// 小文字化した文字列を返す（前後空白は削除）。
///
/// 例: 「ます」→ 「マス」、「Alice」→「alice」
///
/// これにより「ます」で「マスラオ」がヒットするようになる。
String canonicalizeForNameMatch(String s) {
  final buf = StringBuffer();
  for (final rune in s.trim().toLowerCase().runes) {
    // ひらがな (U+3041..U+3096) を カタカナ (U+30A1..U+30F6) に変換。
    if (rune >= 0x3041 && rune <= 0x3096) {
      buf.writeCharCode(rune + 0x60);
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

/// 履歴 JSON 文字列リストを [PlayerNameHistoryEntry] に復元する。
List<PlayerNameHistoryEntry> decodePlayerNameHistory(List<String>? raw) {
  if (raw == null) return const <PlayerNameHistoryEntry>[];
  final result = <PlayerNameHistoryEntry>[];
  for (final s in raw) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        final entry = PlayerNameHistoryEntry.fromJson(decoded);
        if (entry.name.trim().isNotEmpty) {
          result.add(entry);
        }
      }
    } catch (_) {
      // 壊れたエントリは黙って捨てる。
    }
  }
  return result;
}

/// [PlayerNameHistoryEntry] を SharedPreferences 保存用の文字列リストにする。
List<String> encodePlayerNameHistory(List<PlayerNameHistoryEntry> entries) =>
    entries.map((e) => jsonEncode(e.toJson())).toList();

/// 旧キー `saved_players_v2` の JSON 文字列リストから初期履歴を作る。
/// 各名前を count=1, aliases 空でシード。
List<PlayerNameHistoryEntry> seedHistoryFromLegacyPlayers(
  List<String>? legacyJsonList, {
  DateTime? now,
}) {
  if (legacyJsonList == null) return const <PlayerNameHistoryEntry>[];
  final base = now ?? DateTime.now();
  final seen = <String>{};
  final entries = <PlayerNameHistoryEntry>[];
  for (final s in legacyJsonList) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        final name = (decoded['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        final key = normalizePlayerName(name);
        if (seen.contains(key)) continue;
        seen.add(key);
        entries.add(
          PlayerNameHistoryEntry(
            name: name,
            aliases: const <String>[],
            count: 1,
            lastUsedAt: base,
          ),
        );
      }
    } catch (_) {
      // 無視。
    }
  }
  return entries;
}

/// 履歴に [name] の使用を記録する。既存エントリがあれば count を +1 し
/// [alias] を非破壊的にマージ、なければ新規追加する。
List<PlayerNameHistoryEntry> recordPlayerNameUsage(
  List<PlayerNameHistoryEntry> entries,
  String name, {
  String? alias,
  DateTime? now,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return entries;
  final key = normalizePlayerName(trimmed);
  final normalizedAlias = alias?.trim() ?? '';
  final timestamp = now ?? DateTime.now();

  final updated = <PlayerNameHistoryEntry>[];
  var matched = false;
  for (final e in entries) {
    if (!matched && normalizePlayerName(e.name) == key) {
      matched = true;
      final mergedAliases = List<String>.of(e.aliases);
      if (normalizedAlias.isNotEmpty &&
          normalizePlayerName(normalizedAlias) != key &&
          !mergedAliases.any(
            (a) =>
                normalizePlayerName(a) == normalizePlayerName(normalizedAlias),
          )) {
        mergedAliases.add(normalizedAlias);
      }
      updated.add(
        e.copyWith(
          name: trimmed,
          aliases: mergedAliases,
          count: e.count + 1,
          lastUsedAt: timestamp,
        ),
      );
    } else {
      updated.add(e);
    }
  }
  if (!matched) {
    updated.add(
      PlayerNameHistoryEntry(
        name: trimmed,
        aliases:
            normalizedAlias.isNotEmpty &&
                    normalizePlayerName(normalizedAlias) != key
                ? <String>[normalizedAlias]
                : const <String>[],
        count: 1,
        lastUsedAt: timestamp,
      ),
    );
  }
  return updated;
}

/// 名前で 1 件の履歴を削除する。
List<PlayerNameHistoryEntry> removePlayerNameHistoryEntry(
  List<PlayerNameHistoryEntry> entries,
  String name,
) {
  final key = normalizePlayerName(name);
  return entries.where((e) => normalizePlayerName(e.name) != key).toList();
}

/// サジェスト対象を絞り込む。
///
/// - [input] が空なら「よく使う順」で上位 [limit] 件を返す。
/// - [input] が空でなければ name または alias に部分一致（大文字小文字無視）
///   したエントリを絞り込み、count 降順 → lastUsedAt 降順で並べる。
/// - [excludeNames] に含まれる名前（正規化一致）は候補から除外する。
List<PlayerNameHistoryEntry> suggestPlayerNames(
  List<PlayerNameHistoryEntry> entries, {
  required String input,
  required Set<String> excludeNames,
  int limit = 8,
}) {
  final normalizedExclude = excludeNames.map(normalizePlayerName).toSet();
  final trimmedInput = input.trim();
  final needle = canonicalizeForNameMatch(trimmedInput);

  final filtered =
      entries.where((e) {
        if (normalizedExclude.contains(normalizePlayerName(e.name))) {
          return false;
        }
        if (needle.isEmpty) return true;
        if (canonicalizeForNameMatch(e.name).contains(needle)) return true;
        return e.aliases.any(
          (a) => canonicalizeForNameMatch(a).contains(needle),
        );
      }).toList();

  filtered.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return b.lastUsedAt.compareTo(a.lastUsedAt);
  });

  if (filtered.length > limit) {
    return filtered.sublist(0, limit);
  }
  return filtered;
}
