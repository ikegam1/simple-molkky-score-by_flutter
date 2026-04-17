// 早期終了ボタン表示条件のユニットテスト
// _shouldShowEarlyEnd() の純粋ロジックを関数として抽出して検証する
// 実装: lib/main.dart _GameScreenState._shouldShowEarlyEnd()
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// _GameScreenState._shouldShowEarlyEnd() と同一ロジックを純粋関数として再現
bool shouldShowEarlyEnd({
  required MatchType type,
  required int currentTurnInSet,
  required int score,
  bool isSetFinished = false,
}) {
  if (isSetFinished) return false;
  final int limit;
  if (type == MatchType.self5Turn) {
    limit = 5;
  } else if (type == MatchType.self6Turn) {
    limit = 6;
  } else {
    return false;
  }
  if (currentTurnInSet > limit) return true; // ターン制限を超えた
  // 残り3ターン: 最大36点しか取れないので14点未満は不可能
  if (currentTurnInSet == limit - 2 && score < 14) return true;
  // 残り2ターン: 最大24点しか取れないので25点未満は不可能
  if (currentTurnInSet == limit - 1 && score < 25) return true;
  return false;
}

void main() {
  group('早期終了ボタン — セルフ5ターン (limit=5)', () {
    test('通常モードでは表示しない', () {
      for (final type in [MatchType.raceTo, MatchType.fixedSets, MatchType.hyakin]) {
        expect(shouldShowEarlyEnd(type: type, currentTurnInSet: 1, score: 0), isFalse,
            reason: '$type では表示しない');
      }
    });

    test('ターン1〜2では条件を満たさない限り表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 1, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 2, score: 0), isFalse);
    });

    test('ターン3で14点未満なら表示（残り3ターン・最大36点）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 13), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 0), isTrue);
    });

    test('ターン3で14点以上なら表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 14), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 30), isFalse);
    });

    test('ターン4で25点未満なら表示（残り2ターン・最大24点）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 24), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 0), isTrue);
    });

    test('ターン4で25点以上なら表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 25), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 38), isFalse);
    });

    test('ターン5（最終ターン）はlimit内のため自動表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 5, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 5, score: 38), isFalse);
    });

    test('ターン6以降（制限超過）は常に表示', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 6, score: 0), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 6, score: 49), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 10, score: 30), isTrue);
    });

    test('isSetFinished=true の場合は常に表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 6, score: 0, isSetFinished: true), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 0, isSetFinished: true), isFalse);
    });
  });

  group('早期終了ボタン — セルフ6ターン (limit=6)', () {
    test('ターン1〜3では条件を満たさない限り表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 1, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 2, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 3, score: 0), isFalse);
    });

    test('ターン4で14点未満なら表示（残り3ターン・最大36点）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 4, score: 13), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 4, score: 0), isTrue);
    });

    test('ターン4で14点以上なら表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 4, score: 14), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 4, score: 30), isFalse);
    });

    test('ターン5で25点未満なら表示（残り2ターン・最大24点）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 5, score: 24), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 5, score: 0), isTrue);
    });

    test('ターン5で25点以上なら表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 5, score: 25), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 5, score: 38), isFalse);
    });

    test('ターン6（最終ターン）はlimit内のため自動表示しない', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 6, score: 0), isFalse);
    });

    test('ターン7以降（制限超過）は常に表示', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 7, score: 0), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 7, score: 49), isTrue);
    });

    test('セルフ5ターンとセルフ6ターンで閾値ターンが1つずれている', () {
      // 同じスコア0でも、self5=ターン3から、self6=ターン4から
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 0), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 3, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 4, score: 0), isTrue);
    });
  });

  group('早期終了ボタン — 境界値テスト', () {
    test('score=13 と 14 の境界（3ターン残り・self5Turn=ターン3）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 13), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 3, score: 14), isFalse);
    });

    test('score=24 と 25 の境界（2ターン残り・self5Turn=ターン4）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 24), isTrue);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 4, score: 25), isFalse);
    });

    test('制限超過の境界（self5=ターン5と6）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 5, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self5Turn, currentTurnInSet: 6, score: 0), isTrue);
    });

    test('制限超過の境界（self6=ターン6と7）', () {
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 6, score: 0), isFalse);
      expect(shouldShowEarlyEnd(type: MatchType.self6Turn, currentTurnInSet: 7, score: 0), isTrue);
    });
  });
}
