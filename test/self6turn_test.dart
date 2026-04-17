// セルフ6ターンモードのユニットテスト
// self5turn_test.dart と同様の構造で、6ターン制を検証する
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// Helper: 1名プレイヤーでセルフ6ターンのMolkkyMatchを生成
MolkkyMatch makeSelf6TurnMatch() {
  final player = Player(id: 'p1', name: 'Solo', initialOrder: 0);
  return MolkkyMatch(players: [player], limit: 99, type: MatchType.self6Turn);
}

/// Helper: プレイヤーに指定点数を積み上げる（バースト考慮）
void applyScores(Player p, MolkkyMatch match, List<int> scores) {
  for (final score in scores) {
    GameLogic.processThrow(p, score == 0 ? [] : [score], match);
  }
}

void main() {
  group('MatchType.self6Turn — MolkkyMatch基本動作', () {
    test('isMatchOver は常に false を返す', () {
      final match = makeSelf6TurnMatch();
      expect(match.isMatchOver, isFalse);

      // completedSets が増えても false
      match.completedSets.add(SetRecord(1, 'p1', ['p1']));
      expect(match.isMatchOver, isFalse);
    });

    test('consecutiveSuccesses フィールドが 0 で初期化される', () {
      final match = makeSelf6TurnMatch();
      expect(match.consecutiveSuccesses, 0);
    });

    test('prepareNextSet でセット番号が進みプレイヤーがリセットされる', () {
      final match = makeSelf6TurnMatch();
      final player = match.players.first;
      player.currentScore = 30;
      player.consecutiveMisses = 1;

      match.finalizeCurrentSetIfNeeded();
      match.prepareNextSet();

      expect(match.currentSetIndex, 2);
      expect(player.currentScore, 0);
      expect(player.consecutiveMisses, 0);
    });

    test('self6Turn と self5Turn は独立したMatchTypeである', () {
      expect(MatchType.self6Turn, isNot(equals(MatchType.self5Turn)));
    });
  });

  group('セルフ6ターン — 成功条件', () {
    test('6投以内に50点到達で成功判定できる', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      // 4投で50点
      applyScores(p, match, [12, 12, 12, 14]);
      expect(p.currentScore, 50);
      expect(p.scoreHistory.length, 4);
    });

    test('1投で50点（ジャストアガリ）', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;
      p.currentScore = 38; // 残り12

      GameLogic.processThrow(p, [12], match);
      expect(p.currentScore, 50);
    });

    test('6投目で50点に到達', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      // 5投で38点、6投目に12点で50
      applyScores(p, match, [8, 8, 8, 7, 7, 12]);
      expect(p.currentScore, 50);
      expect(p.scoreHistory.length, 6);
    });
  });

  group('セルフ6ターン — 失敗条件', () {
    test('6投後に50点未満はUIレベルで失敗（モデルは継続可能）', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      // 6投打って48点止まり（モデル層は継続可能）
      applyScores(p, match, [8, 8, 8, 8, 8, 8]);
      expect(p.currentScore, 48);
      expect(p.scoreHistory.length, 6);
      // モデル層では自動失敗しない（UIで制御）
      expect(p.isDisqualified, isFalse);
    });

    test('3ミスで失格は失敗', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match);
      GameLogic.processThrow(p, [], match); // 3回目で失格
      expect(p.isDisqualified, isTrue);
    });

    test('7投目以降も継続投擲可能（モデル層の拡張プレイ確認）', () {
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      // 6投で48点（ターン制限超過後も継続）
      applyScores(p, match, [8, 8, 8, 8, 8, 8]);
      expect(p.scoreHistory.length, 6);

      // 7投目も投擲可能（モデルは止まらない）
      GameLogic.processThrow(p, [2], match);
      expect(p.currentScore, 50);
      expect(p.scoreHistory.length, 7);
    });
  });

  group('セルフ6ターン — 連続成功カウント', () {
    test('consecutiveSuccesses のインクリメント', () {
      final match = makeSelf6TurnMatch();
      expect(match.consecutiveSuccesses, 0);

      match.consecutiveSuccesses++;
      expect(match.consecutiveSuccesses, 1);
    });

    test('成功後 prepareNextSet で次チャレンジに進める', () {
      final match = makeSelf6TurnMatch();
      match.consecutiveSuccesses = 2;

      match.finalizeCurrentSetIfNeeded();
      match.prepareNextSet();

      expect(match.currentSetIndex, 2);
      expect(match.consecutiveSuccesses, 2); // 連続成功数は引き継がれる
      expect(match.players.first.currentScore, 0); // プレイヤーはリセット
    });
  });

  group('セルフ6ターン — GameLogicとの統合', () {
    test('バースト後も正常に続行できる', () {
      final match = makeSelf6TurnMatch();
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
      final match = makeSelf6TurnMatch();
      final p = match.players.first;

      GameLogic.processThrow(p, [10], match);
      GameLogic.processThrow(p, [], match); // miss
      expect(p.currentScore, 10);
      expect(p.consecutiveMisses, 1);
    });
  });
}
