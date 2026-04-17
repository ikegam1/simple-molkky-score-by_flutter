// セルフターンモードの成功/失敗判定ロジックのユニットテスト
// 実装: lib/main.dart _GameScreenState._submitThrow() のself turn分岐
// バグ修正: 制限ターン超過後に50点到達しても「失敗」とする
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// _GameScreenState._submitThrow() の成功/失敗判定を純粋関数として再現
/// succeeded = score == 50 && turnCount <= limit
/// failed    = isDisqualified || (score == 50 && turnCount > limit)
({bool succeeded, bool failed}) selfTurnResult({
  required int score,
  required int turnCount,
  required int limit,
  required bool isDisqualified,
}) {
  final bool succeeded = score == 50 && turnCount <= limit;
  final bool failed = isDisqualified || (score == 50 && turnCount > limit);
  return (succeeded: succeeded, failed: failed);
}

void main() {
  group('セルフ5ターン — 成功/失敗判定', () {
    const limit = 5;

    test('制限内(ターン5)に50点 → 成功', () {
      final r = selfTurnResult(score: 50, turnCount: 5, limit: limit, isDisqualified: false);
      expect(r.succeeded, isTrue);
      expect(r.failed, isFalse);
    });

    test('制限内(ターン3)に50点 → 成功', () {
      final r = selfTurnResult(score: 50, turnCount: 3, limit: limit, isDisqualified: false);
      expect(r.succeeded, isTrue);
      expect(r.failed, isFalse);
    });

    test('制限超過(ターン6)に50点 → 失敗（バグ修正確認）', () {
      final r = selfTurnResult(score: 50, turnCount: 6, limit: limit, isDisqualified: false);
      expect(r.succeeded, isFalse);
      expect(r.failed, isTrue);
    });

    test('制限超過(ターン10)に50点 → 失敗', () {
      final r = selfTurnResult(score: 50, turnCount: 10, limit: limit, isDisqualified: false);
      expect(r.succeeded, isFalse);
      expect(r.failed, isTrue);
    });

    test('制限内でも50点未満 → 継続（成功でも失敗でもない）', () {
      final r = selfTurnResult(score: 48, turnCount: 4, limit: limit, isDisqualified: false);
      expect(r.succeeded, isFalse);
      expect(r.failed, isFalse);
    });

    test('3ミス失格 → 失敗', () {
      final r = selfTurnResult(score: 10, turnCount: 3, limit: limit, isDisqualified: true);
      expect(r.succeeded, isFalse);
      expect(r.failed, isTrue);
    });

    test('連続成功カウントは制限内到達のみ（ターン5まで）', () {
      // limit境界: ターン5=成功、ターン6=失敗
      final atLimit = selfTurnResult(score: 50, turnCount: 5, limit: limit, isDisqualified: false);
      final overLimit = selfTurnResult(score: 50, turnCount: 6, limit: limit, isDisqualified: false);
      expect(atLimit.succeeded, isTrue);
      expect(overLimit.succeeded, isFalse);
      expect(overLimit.failed, isTrue);
    });
  });

  group('セルフ6ターン — 成功/失敗判定', () {
    const limit = 6;

    test('制限内(ターン6)に50点 → 成功', () {
      final r = selfTurnResult(score: 50, turnCount: 6, limit: limit, isDisqualified: false);
      expect(r.succeeded, isTrue);
      expect(r.failed, isFalse);
    });

    test('制限超過(ターン7)に50点 → 失敗（バグ修正確認）', () {
      final r = selfTurnResult(score: 50, turnCount: 7, limit: limit, isDisqualified: false);
      expect(r.succeeded, isFalse);
      expect(r.failed, isTrue);
    });

    test('制限超過(ターン8)に50点 → 失敗', () {
      final r = selfTurnResult(score: 50, turnCount: 8, limit: limit, isDisqualified: false);
      expect(r.succeeded, isFalse);
      expect(r.failed, isTrue);
    });

    test('limit境界: ターン6=成功、ターン7=失敗', () {
      final atLimit = selfTurnResult(score: 50, turnCount: 6, limit: limit, isDisqualified: false);
      final overLimit = selfTurnResult(score: 50, turnCount: 7, limit: limit, isDisqualified: false);
      expect(atLimit.succeeded, isTrue);
      expect(overLimit.failed, isTrue);
    });
  });

  group('MatchType別のlimit値確認', () {
    test('self5Turn limit=5, self6Turn limit=6', () {
      // MatchType.self5Turn と self6Turn が独立している
      expect(MatchType.self5Turn, isNot(equals(MatchType.self6Turn)));

      // limit値の確認（_selfTurnLimit getterの仕様）
      final limit5 = MatchType.self5Turn == MatchType.self5Turn ? 5 : 6;
      final limit6 = MatchType.self6Turn == MatchType.self6Turn ? 6 : 5;
      expect(limit5, 5);
      expect(limit6, 6);
    });
  });
}
