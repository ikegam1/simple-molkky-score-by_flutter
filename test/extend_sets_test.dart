import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// セット数の途中延長 (「2 先 → 3 先」「10 番 → 12 番」) のテスト。
///
/// ユーザ要望 2026-09-19: セット間の並べ替えダイアログでセット数を増やしたい。
/// 増やすだけで、元の形式より短くはできない。
///
/// 投げ順は limit に依存する (raceTo は最終セットが近いと合計点順になる)
/// ため、**limit を変えたら順序を決め直す**必要がある。そこが壊れていないか
/// も固定する。

Player _p(String id, int order, {int score = 0}) =>
    Player(id: id, name: id, initialOrder: order);

MolkkyMatch _match({
  required MatchType type,
  required int limit,
  int playerCount = 2,
}) {
  final players = <Player>[
    for (int i = 0; i < playerCount; i++) _p(String.fromCharCode(97 + i), i),
  ];
  return MolkkyMatch(players: players, limit: limit, type: type);
}

void main() {
  group('extendLimit', () {
    test('raceTo は増やせる (2 先 → 3 先)', () {
      final m = _match(type: MatchType.raceTo, limit: 2);
      expect(m.extendLimit(3), isTrue);
      expect(m.limit, 3);
    });

    test('fixedSets は増やせる (10 番 → 12 番)', () {
      final m = _match(type: MatchType.fixedSets, limit: 10);
      expect(m.extendLimit(12), isTrue);
      expect(m.limit, 12);
    });

    test('同じ値や小さい値は受け付けない (減らせない)', () {
      final m = _match(type: MatchType.raceTo, limit: 3);
      expect(m.extendLimit(3), isFalse);
      expect(m.extendLimit(2), isFalse);
      expect(m.limit, 3, reason: '拒否したのに limit が変わっている');
    });

    test('百均・セルフ練習は対象外', () {
      for (final type in <MatchType>[
        MatchType.hyakin,
        MatchType.self5Turn,
        MatchType.self6Turn,
        MatchType.threeGame,
      ]) {
        final m = _match(type: type, limit: 2);
        expect(m.extendLimit(5), isFalse, reason: '$type が延長を受け付けている');
        expect(m.limit, 2);
      }
    });
  });

  group('延長で試合が続くこと', () {
    test('fixedSets: 2 番で 2 セット消化済みなら終了、3 番にすると続く', () {
      final m = _match(type: MatchType.fixedSets, limit: 2);
      m.completedSets.add(SetRecord(1, 'a', ['a', 'b']));
      m.completedSets.add(SetRecord(2, 'b', ['a', 'b']));
      expect(m.isMatchOver, isTrue);

      m.extendLimit(3);
      expect(m.isMatchOver, isFalse, reason: '延長したのに終了のまま');
    });

    test('raceTo: 2 先で 2 勝しているなら終了、3 先にすると続く', () {
      final m = _match(type: MatchType.raceTo, limit: 2);
      m.players[0].setsWon = 2;
      expect(m.isMatchOver, isTrue);

      m.extendLimit(3);
      expect(m.isMatchOver, isFalse, reason: '延長したのに終了のまま');
    });
  });

  group('nextSetOrder', () {
    test('players を書き換えない (プレビュー用)', () {
      final m = _match(type: MatchType.fixedSets, limit: 10, playerCount: 3);
      final before = m.players.map((p) => p.id).toList();
      m.nextSetOrder();
      expect(m.players.map((p) => p.id).toList(), before);
    });

    test('通常は先頭が最後尾に回る', () {
      final m = _match(type: MatchType.fixedSets, limit: 10, playerCount: 3);
      expect(m.nextSetOrder().map((p) => p.id).toList(), ['b', 'c', 'a']);
    });

    test('2 番の 2 セット目は逆順になる', () {
      final m = _match(type: MatchType.fixedSets, limit: 2, playerCount: 3);
      expect(m.nextSetOrder().map((p) => p.id).toList(), ['c', 'b', 'a']);
    });

    test('forLimit で順序が変わる: 2 番の逆順ルールは 3 番では効かない', () {
      final m = _match(type: MatchType.fixedSets, limit: 2, playerCount: 3);
      // 2 番のままなら逆順、3 番に延ばすなら通常の巡回。
      expect(m.nextSetOrder(forLimit: 2).map((p) => p.id).toList(), [
        'c',
        'b',
        'a',
      ]);
      expect(m.nextSetOrder(forLimit: 3).map((p) => p.id).toList(), [
        'b',
        'c',
        'a',
      ]);
    });

    test('raceTo: 最終セットが近いと合計点順、延長すると通常の巡回に戻る', () {
      // 3 人 2 先 → decidingSetThreshold = 3*(2-1)+1 = 4。
      // 4 セット目 (nextIndex=4) は合計点順になる。
      final m = _match(type: MatchType.raceTo, limit: 2, playerCount: 3);
      m.currentSetIndex = 3;
      m.players[0].setFinalScores.add(10); // a
      m.players[1].setFinalScores.add(40); // b
      m.players[2].setFinalScores.add(20); // c

      expect(
        m.nextSetOrder(forLimit: 2).map((p) => p.id).toList(),
        ['b', 'c', 'a'],
        reason: '2 先の最終セットは合計点の高い順になるはず',
      );
      // 3 先にすると threshold = 3*(3-1)+1 = 7 なので、4 セット目はまだ通常の巡回。
      // **ここが再計算されないと、延長しても合計点順のままになる。**
      expect(
        m.nextSetOrder(forLimit: 3).map((p) => p.id).toList(),
        ['b', 'c', 'a'],
        reason: '通常の巡回 (先頭が最後尾へ)',
      );
    });

    test('11 先は合計点順にしない', () {
      final m = _match(type: MatchType.raceTo, limit: 11, playerCount: 3);
      m.currentSetIndex = 30;
      m.players[0].setFinalScores.add(10);
      m.players[1].setFinalScores.add(40);
      m.players[2].setFinalScores.add(20);
      expect(m.nextSetOrder().map((p) => p.id).toList(), ['b', 'c', 'a']);
    });
  });
}
