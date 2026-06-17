import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/utils/landscape_detector.dart';

void main() {
  group('LandscapeDetector', () {
    late LandscapeDetector detector;

    setUp(() {
      detector = LandscapeDetector();
    });

    test('縦長スマホは横レイアウト判定にならない', () {
      // iPhone 16 Pro 程度（390 x 844）
      expect(detector.resolve(390, 844), isFalse);
    });

    test('縦長スマホでキーボード表示しても横レイアウト判定にならない', () {
      // 初期: 縦長
      expect(detector.resolve(390, 844), isFalse);
      // キーボードが出て縦が大幅に縮む（390 x 300）
      // 従来ロジックなら 390 >= 300*1.25=375 && 300<500 で true になってしまうケース
      expect(detector.resolve(390, 300), isFalse);
      // さらに縮んでも維持
      expect(detector.resolve(390, 250), isFalse);
    });

    test('横向きスマホはキーボード表示しても横レイアウト判定を維持', () {
      // 初期: 横長（844 x 390）
      expect(detector.resolve(844, 390), isTrue);
      // キーボード表示で縦が縮む
      expect(detector.resolve(844, 250), isTrue);
    });

    test('画面回転で横幅が変わった場合は再判定', () {
      // 初期: 縦
      expect(detector.resolve(390, 844), isFalse);
      // 画面回転（横向き）
      expect(detector.resolve(844, 390), isTrue);
      // もう一度回転（縦向き）
      expect(detector.resolve(390, 844), isFalse);
    });

    test('縦幅が広がった場合は再判定する', () {
      // 初期: 縦長スマホ
      expect(detector.resolve(390, 844), isFalse);
      // キーボード表示で縮む
      expect(detector.resolve(390, 300), isFalse);
      // キーボードが閉じて縦が広がる → 再判定（縦のまま）
      expect(detector.resolve(390, 844), isFalse);
    });

    test('iPhone 17 想定: 393 x 852 → キーボード表示で 393 x 470 でも縦を維持', () {
      // 縦向き iPhone 17 (393x852)
      expect(detector.resolve(393, 852), isFalse);
      // キーボード表示で 470 まで縮む（393 >= 470*1.25=587.5 はfalseだが、
      // 393 >= 300*1.25=375 になるケースを考慮）
      expect(detector.resolve(393, 470), isFalse);
      // さらに縮んで横判定条件を満たすケース（393 >= 300*1.25=375 && 300<500）
      expect(detector.resolve(393, 300), isFalse);
    });

    test('reset で初期状態に戻る', () {
      expect(detector.resolve(390, 844), isFalse);
      detector.reset();
      // resetすると次の resolve で再判定が走る
      expect(detector.resolve(844, 390), isTrue);
    });

    test('ぴったり横レイアウト境界値の判定', () {
      // 横幅が縦幅の正確に1.25倍、高さ499（< 500）
      // 400 / 320 = 1.25 → true
      expect(detector.resolve(400, 320), isTrue);
      // 高さがちょうど500 → false（< 500 を満たさない）
      detector.reset();
      expect(detector.resolve(700, 500), isFalse);
    });
  });
}
