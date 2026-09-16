import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/two_digit_key_input.dart';

void main() {
  group('combineAfterOne', () {
    test('1 → 0 は 10 になる', () {
      expect(combineAfterOne(0), 10);
    });

    test('1 → 1 は 11 になる', () {
      expect(combineAfterOne(1), 11);
    });

    test('1 → 2 は 12 になる', () {
      expect(combineAfterOne(2), 12);
    });

    test('3 以上は合成しない (13 以上のピンは存在しない)', () {
      for (var n = 3; n <= 12; n++) {
        expect(combineAfterOne(n), isNull, reason: '1 → $n');
      }
    });
  });

  group('kTwoDigitKeyWindow', () {
    test('続けて押したとみなす窓は 500ms', () {
      // 短すぎると素早く打っても拾えず、長すぎると 1 を打っただけの入力が
      // もたつく。実機で試して決めた値なので、変えるときは体感も確認する。
      expect(kTwoDigitKeyWindow, const Duration(milliseconds: 500));
    });
  });
}
