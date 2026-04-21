import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

Player _player(String id, String name) => Player(id: id, name: name, initialOrder: 0);

void main() {
  group('ターン制限によるセット判定', () {
    test('最高得点が1人ならそのプレイヤーが勝者', () {
      final a = _player('a', 'Alice')..currentScore = 41;
      final b = _player('b', 'Bob')..currentScore = 38;
      final decision = GameLogic.decideSetByCurrentScores([a, b]);

      expect(decision.isDraw, isFalse);
      expect(decision.winner?.name, 'Alice');
    });

    test('最高得点が同点なら引き分け', () {
      final a = _player('a', 'Alice')..currentScore = 40;
      final b = _player('b', 'Bob')..currentScore = 40;
      final c = _player('c', 'Carol')..currentScore = 35;
      final decision = GameLogic.decideSetByCurrentScores([a, b, c]);

      expect(decision.isDraw, isTrue);
      expect(decision.winner, isNull);
      expect(decision.leaders.map((p) => p.name), containsAll(['Alice', 'Bob']));
    });
  });

  group('時間切れによる試合判定', () {
    test('セット数優先、次に合計点で勝者を決める', () {
      final a = _player('a', 'Alice')
        ..setsWon = 2
        ..setFinalScores.addAll([50, 32, 18]);
      final b = _player('b', 'Bob')
        ..setsWon = 1
        ..setFinalScores.addAll([41, 50, 20]);

      final decision = GameLogic.decideMatchByStandings([a, b]);
      expect(decision.isDraw, isFalse);
      expect(decision.winner?.name, 'Alice');
    });

    test('セット数も合計点も同じなら引き分け', () {
      final a = _player('a', 'Alice')
        ..setsWon = 1
        ..setFinalScores.addAll([50, 20]);
      final b = _player('b', 'Bob')
        ..setsWon = 1
        ..setFinalScores.addAll([45, 25]);

      final decision = GameLogic.decideMatchByStandings([a, b]);
      expect(decision.isDraw, isTrue);
      expect(decision.winner, isNull);
      expect(decision.leaders.length, 2);
    });
  });

  group('MolkkyMatch に制限設定を保持できる', () {
    test('ターン制限と試合時間制限が保持される', () {
      final match = MolkkyMatch(
        players: [_player('a', 'Alice'), _player('b', 'Bob')],
        limit: 3,
        type: MatchType.raceTo,
        turnLimitPerSet: 10,
        matchTimeLimitSeconds: 15 * 60,
      );

      expect(match.turnLimitPerSet, 10);
      expect(match.matchTimeLimitSeconds, 900);
    });

    test('空の次セットは履歴表示対象にしない判定ができる', () {
      final set1 = SetRecord(1, 'a', ['a', 'b']);
      set1.turns.add(TurnRecord(1, {'a': 8, 'b': 6}));
      set1.finalCumulativeScores.addAll({'a': 50, 'b': 32});

      final set2 = SetRecord(2, 'b', ['b', 'a']);

      expect(set1.hasContent, isTrue);
      expect(set2.hasContent, isFalse);
    });

    test('セルフ5/6ターンは追加制限を使わない前提で生成できる', () {
      final self5 = MolkkyMatch(
        players: [_player('a', 'Alice')],
        limit: 99,
        type: MatchType.self5Turn,
      );
      final self6 = MolkkyMatch(
        players: [_player('a', 'Alice')],
        limit: 99,
        type: MatchType.self6Turn,
      );

      expect(self5.turnLimitPerSet, isNull);
      expect(self5.matchTimeLimitSeconds, isNull);
      expect(self6.turnLimitPerSet, isNull);
      expect(self6.matchTimeLimitSeconds, isNull);
    });
  });
}
