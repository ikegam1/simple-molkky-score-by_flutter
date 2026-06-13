import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/main.dart';

void main() {
  group('kKeyboardScoreMap', () {
    test('numpad0 と digit0 はミス (0)', () {
      expect(kKeyboardScoreMap[LogicalKeyboardKey.numpad0], 0);
      expect(kKeyboardScoreMap[LogicalKeyboardKey.digit0], 0);
    });

    test('1〜9 は numpad/digit 両方で同じスコア', () {
      for (var i = 1; i <= 9; i++) {
        final numpad = LogicalKeyboardKey(LogicalKeyboardKey.numpad0.keyId + i);
        final digit = LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + i);
        expect(kKeyboardScoreMap[numpad], i, reason: 'numpad$i');
        expect(kKeyboardScoreMap[digit], i, reason: 'digit$i');
      }
    });

    test('numpadMultiply → 10、numpadSubtract → 11、numpadAdd → 12', () {
      expect(kKeyboardScoreMap[LogicalKeyboardKey.numpadMultiply], 10);
      expect(kKeyboardScoreMap[LogicalKeyboardKey.numpadSubtract], 11);
      expect(kKeyboardScoreMap[LogicalKeyboardKey.numpadAdd], 12);
    });

    test('Backspaceはスコアマップに含まれない（別途処理）', () {
      expect(
        kKeyboardScoreMap.containsKey(LogicalKeyboardKey.backspace),
        isFalse,
      );
    });

    test('Enterは含まれない（autofocusで対応）', () {
      expect(kKeyboardScoreMap.containsKey(LogicalKeyboardKey.enter), isFalse);
      expect(
        kKeyboardScoreMap.containsKey(LogicalKeyboardKey.numpadEnter),
        isFalse,
      );
    });

    test('全エントリのスコアは 0〜12 の範囲', () {
      for (final score in kKeyboardScoreMap.values) {
        expect(score, inInclusiveRange(0, 12));
      }
    });
  });
}
