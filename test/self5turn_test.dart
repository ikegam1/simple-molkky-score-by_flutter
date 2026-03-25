import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// Helper: 1名プレイヤーでセルフ5ターンのMolkkyMatchを生成
MolkkyMatch makeSelf5TurnMatch() {
  final player = Player(id: 'p1', name: 'Solo', initialOrder: 0);
  return MolkkyMatch(players: [player], limit: 99, type: MatchType.self5Turn);
}

/// Helper: プレイヤーに指定点数を積み上げる（バースト考慮）
void applyScores(Player p, MolkkyMatch match, List<int> scores) {
  for (final score in scores) {
    GameLogic.processThrow(p, score == 0 ? [] : [score], match);
  }
}

void main() {
  group('MatchType.self5Turn — MolkkyMatch基本動作', () {
    test('isMatchOver は常に false を返す', () {
      final match = makeSelf5TurnMatch();
      expect(match.isMatchOver, isFalse);

      // completedSets が増えても false
      match.completedSets.add(SetRecord(1, 'p1', ['p1']));
      expect(match.isMatchOver, isFalse);
    });

    test('consecutiveSuccesses フィールドが 0 で初期化される', () {
      final match = makeSelf5TurnMatch();
      expect(match.consecutiveSuccesses, 0);
    });

    test('prepareNextSet でセット番号が進みプレイヤーがリセットされる', () {
      final match = makeSelf5TurnMatch();
      final player = match.players.first;
      player.currentScore = 30;
      player.consecutiveMisses = 1;

      match.finalizeCurrentSetIfNeeded();
      match.prepareNextSet();

      expect(match.currentSetIndex, 2);
      expect(player.currentScore, 0);
      expect(player.consecutiveMisses, 0);
    });
  });

  group('セルフ5ターン — 成功条件', () {
    test('5投以内に50点到達で成功判定できる', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      // 3投で50点に到達: 12+12+12+14=50 → 実際は12+12+12で36、4投目14で50
      applyScores(p, match, [12, 12, 12, 14]);
      expect(p.currentScore, 50);
    });

    test('1投で50点（ジャストアガリ）', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;
      p.currentScore = 38; // 残り12

      GameLogic.processThrow(p, [12], match);
      expect(p.currentScore, 50);
    });

    test('5投目で50点に到達', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      // 4投で38点、5投目に12点で50
      applyScores(p, match, [10, 10, 10, 8, 12]);
      expect(p.currentScore, 50);
      expect(p.scoreHistory.length, 5);
    });
  });

  group('セルフ5ターン — 失敗条件', () {
    test('5投後に50点未満は失敗（turnInSet >= 5 で点数不足）', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      // 5投打って49点止まり
      applyScores(p, match, [10, 10, 10, 10, 9]);
      expect(p.currentScore, 49);
      expect(p.scoreHistory.length, 5);
      // currentScore != 50 かつ scoreHistory.length >= 5 → 失敗
      expect(p.currentScore == 50, isFalse);
    });

    test('3ミスで失格は失敗', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match); // 3回目で失格
      expect(p.isDisqualified, isTrue);
    });

    test('バーストで25点に戻り5投内に50点到達できない', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      // 49点から2点で51点 → バースト(25点)
      applyScores(p, match, [12, 12, 12, 12, 2]); // 12+12+12+12=48, +2=50 → ちょうど50
      // これは成功になってしまうので別のケースに
      // 40点から12点で52 → バースト25、残り0投
      final match2 = makeSelf5TurnMatch();
      final p2 = match2.players.first;
      applyScores(p2, match2, [12, 12, 12, 5, 12]); // 12+12+12+5=41, +12=53 → burst 25
      expect(p2.currentScore, 25);
      expect(p2.scoreHistory.length, 5);
    });
  });

  group('セルフ5ターン — 連続成功カウント', () {
    test('consecutiveSuccesses のインクリメント', () {
      final match = makeSelf5TurnMatch();
      expect(match.consecutiveSuccesses, 0);

      match.consecutiveSuccesses++;
      expect(match.consecutiveSuccesses, 1);

      match.consecutiveSuccesses++;
      expect(match.consecutiveSuccesses, 2);
    });

    test('成功後 prepareNextSet で次チャレンジに進める', () {
      final match = makeSelf5TurnMatch();
      match.consecutiveSuccesses = 3;

      // チャレンジ終了処理を模倣
      match.finalizeCurrentSetIfNeeded();
      match.prepareNextSet();

      expect(match.currentSetIndex, 2);
      expect(match.consecutiveSuccesses, 3); // 連続成功数は引き継がれる
      expect(match.players.first.currentScore, 0); // プレイヤーはリセット
    });
  });

  group('セルフ5ターン — GameLogicとの統合', () {
    test('バースト後も正常に続行できる', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      p.currentScore = 49;
      GameLogic.processThrow(p, [2], match); // burst → 25
      expect(p.currentScore, 25);
      expect(p.isDisqualified, isFalse);

      // 続けて投擲可能
      GameLogic.processThrow(p, [10], match);
      expect(p.currentScore, 35);
    });

    test('ミス後もスコアは変わらない', () {
      final match = makeSelf5TurnMatch();
      final p = match.players.first;

      GameLogic.processThrow(p, [10], match);
      GameLogic.processThrow(p, [], match); // miss
      expect(p.currentScore, 10);
      expect(p.consecutiveMisses, 1);
    });
  });
}
