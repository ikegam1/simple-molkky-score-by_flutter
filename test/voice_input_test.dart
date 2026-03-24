import 'package:flutter_test/flutter_test.dart';

// _parseVoiceScore のロジックをテスト用に抽出した関数
int? parseVoiceScore(String text) {
  final wakeIdx = text.indexOf('投擲終了');
  if (wakeIdx < 0) return null;

  final afterWake = text
      .substring(wakeIdx + 4)
      .replaceAll(RegExp(r'[、。,.\s　]'), '');

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
  group('_parseVoiceScore: ウェイクワードなしは無視', () {
    test('ウェイクワードなし → null', () => expect(parseVoiceScore('12点'), isNull));
    test('空文字 → null', () => expect(parseVoiceScore(''), isNull));
  });

  group('_parseVoiceScore: ミス認識', () {
    test('「投擲終了、ミス」', () => expect(parseVoiceScore('投擲終了、ミス'), -1));
    test('「投擲終了みす」', () => expect(parseVoiceScore('投擲終了みす'), -1));
  });

  group('_parseVoiceScore: アラビア数字', () {
    test('「投擲終了、12点」→ 12', () => expect(parseVoiceScore('投擲終了、12点'), 12));
    test('「投擲終了、1点」→ 1', () => expect(parseVoiceScore('投擲終了、1点'), 1));
    test('「投擲終了、6点」→ 6', () => expect(parseVoiceScore('投擲終了、6点'), 6));
    test('13点は範囲外 → null', () => expect(parseVoiceScore('投擲終了、13点'), isNull));
    test('0点は範囲外 → null', () => expect(parseVoiceScore('投擲終了、0点'), isNull));
  });

  group('_parseVoiceScore: 日本語数字', () {
    test('「投擲終了、いってん」→ 1', () => expect(parseVoiceScore('投擲終了、いってん'), 1));
    test('「投擲終了、いちてん」→ 1', () => expect(parseVoiceScore('投擲終了、いちてん'), 1));
    test('「投擲終了、にてん」→ 2', () => expect(parseVoiceScore('投擲終了、にてん'), 2));
    test('「投擲終了、さん」→ 3', () => expect(parseVoiceScore('投擲終了、さん'), 3));
    test('「投擲終了、ご」→ 5', () => expect(parseVoiceScore('投擲終了、ご'), 5));
    test('「投擲終了、じゅう」→ 10', () => expect(parseVoiceScore('投擲終了、じゅう'), 10));
    test('「投擲終了、じゅういち」→ 11', () => expect(parseVoiceScore('投擲終了、じゅういち'), 11));
    test('「投擲終了、じゅうに」→ 12', () => expect(parseVoiceScore('投擲終了、じゅうに'), 12));
    test('漢字「十二」→ 12', () => expect(parseVoiceScore('投擲終了、十二'), 12));
  });

  group('_parseVoiceScore: 区切り文字の揺れ', () {
    test('読点なし「投擲終了12点」', () => expect(parseVoiceScore('投擲終了12点'), 12));
    test('スペース区切り「投擲終了 12点」', () => expect(parseVoiceScore('投擲終了 12点'), 12));
    test('ウェイクワード前後に余分なテキスト', () => expect(parseVoiceScore('えー 投擲終了、7点 です'), 7));
  });
}
