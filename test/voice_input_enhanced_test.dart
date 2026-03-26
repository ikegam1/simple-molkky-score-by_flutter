import 'package:flutter_test/flutter_test.dart';

// _wakeWordEnd をテスト用に抽出
int wakeWordEnd(String text) {
  final normalized = text.replaceAll(RegExp(r'[、。,.\s　]'), '');
  for (final w in ['投擲終了', '投てき終了', 'とうてき終了', '投テキ終了', '投擲しゅうりょう', '投擲修了', '投擲週了']) {
    final idx = normalized.indexOf(w);
    if (idx >= 0) return idx + w.length;
  }
  for (final w in ['てきしゅ', '敵襲', 'てき終', 'てき修', 'テキ終', 'テキ修', '圧倒的', 'スコア', '入力', '終了']) {
    final idx = normalized.indexOf(w);
    if (idx >= 0) return idx + w.length;
  }
  return -1;
}

// _parseVoiceScore のロジックをテスト用に抽出した関数 (最新版)
int? parseVoiceScore(String text) {
  final normalized = text.replaceAll(RegExp(r'[、。,.\s　]'), '');
  final wakeEnd = wakeWordEnd(text);

  String afterWake;
  if (wakeEnd >= 0) {
    afterWake = normalized
        .substring(wakeEnd)
        .replaceAll('ポイント', '点')
        .replaceAll('ポイン', '点');
  } else {
    return null;
  }

  if (afterWake.isEmpty) return null;
  if (afterWake.contains('ミス') || afterWake.contains('みす')) return -1;

  final digitMatch = RegExp(r'(\d+)').firstMatch(afterWake);
  if (digitMatch != null) {
    final n = int.tryParse(digitMatch.group(1)!);
    if (n != null && n >= 1 && n <= 12) return n;
  }

  const jpMap = <String, int>{
    'じゅうに': 12, '十二': 12,
    'じゅういち': 11, '十一': 11,
    'じゅう': 10, '十': 10,
    'きゅう': 9, '九': 9,
    'はち': 8, '八': 8,
    'ななてん': 7, 'しちてん': 7, 'なな': 7, 'しち': 7, '七': 7,
    'ろくてん': 6, 'ろく': 6, '六': 6,
    'ごてん': 5, 'ご': 5, '五': 5,
    'よんてん': 4, 'してん': 4, 'よん': 4, '四': 4,
    'さんてん': 3, 'さん': 3, '三': 3,
    'にてん': 2, '二': 2,
    'いってん': 1, 'いちてん': 1, 'いち': 1, '一': 1,
  };

  for (final entry in jpMap.entries) {
    if (afterWake.contains(entry.key)) return entry.value;
  }
  return null;
}

void main() {
  group('_parseVoiceScore: ウェイクワード追加「スコア」', () {
    test('「スコア、12点」→ 12', () => expect(parseVoiceScore('スコア、12点'), 12));
    test('「スコア8点」→ 8', () => expect(parseVoiceScore('スコア8点'), 8));
  });

  group('_parseVoiceScore: 単位追加「ポイント」', () {
    test('「投擲終了、10ポイント」→ 10', () => expect(parseVoiceScore('投擲終了、10ポイント'), 10));
    test('「投擲終了10ポイン」→ 10', () => expect(parseVoiceScore('投擲終了10ポイン'), 10));
    test('「スコア、12ポイント」→ 12', () => expect(parseVoiceScore('スコア、12ポイント'), 12));
    test('「スコア12ポイン」→ 12', () => expect(parseVoiceScore('スコア12ポイン'), 12));
  });

  group('_parseVoiceScore: 既存パターンの維持', () {
    test('「投擲終了、ミス」', () => expect(parseVoiceScore('投擲終了、ミス'), -1));
    test('「入力、5点」→ 5', () => expect(parseVoiceScore('入力、5点'), 5));
  });
}
