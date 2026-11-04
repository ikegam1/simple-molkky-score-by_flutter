import 'package:simple_molkky_score/logic/match_stats.dart';
import 'package:simple_molkky_score/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// 結果画像に出す成績の数え方のテスト。
///
/// **ここを間違えると、画像に嘘の数字が載る。** 画像は人に見せるものなので、
/// 「数えられていない」のを 0 と出すのも嘘になる。null で返して "-" と
/// 出すところまで確かめる。
void main() {
  Player player(String id, {int setsWon = 0}) =>
      Player(id: id, name: id, initialOrder: 0)..setsWon = setsWon;

  /// ターンを作る。`scores` は playerId → その投擲の点。
  TurnRecord turn(int n, Map<String, int> scores) => TurnRecord(n, scores);

  /// セットを作る。
  SetRecord set(
    int number,
    String starter,
    List<String> order,
    List<TurnRecord> turns, {
    Map<String, int> finals = const {},
  }) {
    final rec = SetRecord(number, starter, order);
    rec.turns.addAll(turns);
    rec.finalCumulativeScores.addAll(finals);
    return rec;
  }

  group('ミス率', () {
    test('0 本だった投擲の割合', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
              turn(2, {'a': 0}),
              turn(3, {'a': 0}),
              turn(4, {'a': 4}),
            ],
          ),
        ],
      );
      expect(stats['a']!.throws, 4);
      expect(stats['a']!.misses, 2);
      expect(stats['a']!.missRate, 0.5);
      expect(formatPercent(stats['a']!.missRate), '50%');
    });

    test('1 回も投げていなければ null (0% ではない)', () {
      final stats = playerMatchStats(players: [player('a')], sets: const []);
      expect(stats['a']!.missRate, isNull);
      expect(formatPercent(stats['a']!.missRate), '-');
    });

    test('ミスが無ければ 0%', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
            ],
          ),
        ],
      );
      expect(stats['a']!.missRate, 0.0);
      expect(formatPercent(stats['a']!.missRate), '0%');
    });
  });

  group('ファーストブレイク', () {
    test('**先に投げたセットの 1 投目だけ数える**', () {
      // ファーストブレイクはピンが全部立っている状態への 1 投目。
      // 後攻の 1 投目は崩れた並びへの投擲なので数えない。
      final stats = playerMatchStats(
        players: [player('a'), player('b')],
        sets: [
          // 1 セット目は a が先攻
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 8, 'b': 3}),
              turn(2, {'a': 2, 'b': 5}),
            ],
          ),
          // 2 セット目は b が先攻
          set(
            2,
            'b',
            ['b', 'a'],
            [
              turn(1, {'b': 10, 'a': 1}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, [8]);
      expect(stats['b']!.firstBreaks, [10]);
      expect(stats['a']!.firstBreakAvg, 8.0);
      expect(stats['b']!.firstBreakAvg, 10.0);
    });

    test('複数セットで先攻したら平均になる', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 8}),
            ],
          ),
          set(
            2,
            'a',
            ['a'],
            [
              turn(1, {'a': 3}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, [8, 3]);
      expect(stats['a']!.firstBreakAvg, 5.5);
      expect(formatAverage(stats['a']!.firstBreakAvg), '5.5');
    });

    test('一度も先攻していなければ null', () {
      final stats = playerMatchStats(
        players: [player('a'), player('b')],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 8, 'b': 3}),
            ],
          ),
        ],
      );
      expect(stats['b']!.firstBreakAvg, isNull);
      expect(formatAverage(stats['b']!.firstBreakAvg), '-');
    });

    test('ファーストブレイクがミスでも 0 として数える', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 0}),
              turn(2, {'a': 6}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, [0]);
      expect(stats['a']!.firstBreakAvg, 0.0);
    });

    test('ターン番号が並んでいなくても 1 投目を取り違えない', () {
      // 保存の都合で順が崩れていても、番号の小さい方を 1 投目とする。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(2, {'a': 5}),
              turn(1, {'a': 9}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, [9]);
    });

    test('先攻の人がそのセットで投げていなければ数えない', () {
      // 失格などで 1 投も記録が無いことがある。
      final stats = playerMatchStats(
        players: [player('a'), player('b')],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'b': 4}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, isEmpty);
      expect(stats['a']!.firstBreakAvg, isNull);
    });
  });

  group('勝率', () {
    test('取ったセット / 参加したセット', () {
      final stats = playerMatchStats(
        players: [player('a', setsWon: 2), player('b', setsWon: 1)],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 1, 'b': 1}),
            ],
          ),
          set(
            2,
            'b',
            ['b', 'a'],
            [
              turn(1, {'b': 1, 'a': 1}),
            ],
          ),
          set(
            3,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 1, 'b': 1}),
            ],
          ),
        ],
      );
      expect(stats['a']!.setsPlayed, 3);
      expect(stats['a']!.winRate, closeTo(2 / 3, 1e-9));
      expect(formatPercent(stats['a']!.winRate), '67%');
      expect(stats['b']!.winRate, closeTo(1 / 3, 1e-9));
    });

    test('参加したセットが無ければ null', () {
      final stats = playerMatchStats(
        players: [player('a', setsWon: 0)],
        sets: const [],
      );
      expect(stats['a']!.winRate, isNull);
      expect(formatPercent(stats['a']!.winRate), '-');
    });

    test('**中身の無いセットは参加に数えない**', () {
      // 始まる前の器が混ざると、参加セット数だけ増えて勝率が下がる。
      final stats = playerMatchStats(
        players: [player('a', setsWon: 1)],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 5}),
            ],
          ),
          set(2, 'a', ['a'], const []),
        ],
      );
      expect(stats['a']!.setsPlayed, 1);
      expect(stats['a']!.winRate, 1.0);
      expect(formatPercent(stats['a']!.winRate), '100%');
    });

    test('そのセットで投げていない人は参加に数えない', () {
      final stats = playerMatchStats(
        players: [player('a', setsWon: 1), player('b')],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 5}),
            ],
          ),
        ],
      );
      expect(stats['a']!.setsPlayed, 1);
      expect(stats['b']!.setsPlayed, 0);
      expect(stats['b']!.winRate, isNull);
    });

    test('数が食い違っても 100% を超えない', () {
      // 保存の都合で setsWon が参加数より多くなっても、おかしな率を出さない。
      final stats = playerMatchStats(
        players: [player('a', setsWon: 5)],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 5}),
            ],
          ),
        ],
      );
      expect(stats['a']!.winRate, 1.0);
      // **画面に出す文字でも超えないこと。** 率の計算だけ clamp しても、
      // 表示が素通りだと `500%(5/1)` と出る (codex 指摘 2026-11-04)。
      expect(stats['a']!.winRateText, '100%(1/1)');
    });
  });

  group('上がりターン数', () {
    test('50 に届いたセットの、最後に投げたターン', () {
      final stats = playerMatchStats(
        players: [player('a'), player('b')],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              turn(1, {'a': 12, 'b': 3}),
              turn(2, {'a': 12, 'b': 3}),
              turn(3, {'a': 12, 'b': 3}),
              turn(4, {'a': 12, 'b': 3}),
              turn(5, {'a': 2}),
            ],
            finals: {'a': 50, 'b': 12},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [5]);
      expect(stats['a']!.finishTurnAvg, 5.0);
      // 上がっていない方は数えない。
      expect(stats['b']!.finishTurns, isEmpty);
      expect(stats['b']!.finishTurnAvg, isNull);
    });

    test('複数セット上がったら平均になる', () {
      // 1 投は最大 12 点なので、自力の上がりは最短でも 5 ターン。
      // 下限 (kMinFinishTurns) に当たらない現実的な値で確かめる。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 5; i += 1) turn(i, {'a': 10}),
            ],
            finals: {'a': 50},
          ),
          set(
            2,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 7; i += 1) turn(i, {'a': 7}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [5, 7]);
      expect(stats['a']!.finishTurnAvg, 6.0);
      expect(formatAverage(stats['a']!.finishTurnAvg), '6.0');
    });

    test('**50 でなければ上がりに数えない**', () {
      // 時間切れや失格で終わったセットは「上がった」ではない。
      final stats = playerMatchStats(
        players: [player('a', setsWon: 1)],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 5}),
            ],
            finals: {'a': 37},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, isEmpty);
      expect(stats['a']!.finishTurnAvg, isNull);
      // セットは取っているので勝率には出る。
      expect(stats['a']!.winRate, 1.0);
    });
  });

  group('1 投あたりの平均得点', () {
    test('得点の合計 / 投擲数', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
              turn(2, {'a': 0}),
              turn(3, {'a': 3}),
            ],
          ),
        ],
      );
      expect(stats['a']!.points, 15);
      expect(stats['a']!.throws, 3);
      expect(stats['a']!.pointsPerThrow, 5.0);
      expect(formatAverage(stats['a']!.pointsPerThrow), '5.0');
    });

    test('1 回も投げていなければ null', () {
      final stats = playerMatchStats(players: [player('a')], sets: const []);
      expect(stats['a']!.pointsPerThrow, isNull);
    });

    test('**50 を超えて 25 に戻された分も得点として数える**', () {
      // セットの最終スコアは 25 に戻るが、投げて倒した本数は変わらない。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
              turn(2, {'a': 12}),
              turn(3, {'a': 12}),
              turn(4, {'a': 12}),
              turn(5, {'a': 12}),
            ],
            finals: {'a': 25},
          ),
        ],
      );
      expect(stats['a']!.points, 60);
      expect(stats['a']!.pointsPerThrow, 12.0);
    });
  });

  group('全体', () {
    test('試合に出ていない id の記録は無視する', () {
      // 保存に別の試合の id が混ざっても落ちない。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a', 'x'],
            [
              turn(1, {'a': 5, 'x': 9}),
            ],
          ),
        ],
      );
      expect(stats.keys, ['a']);
      expect(stats['a']!.throws, 1);
    });

    test('セットも選手も空でも落ちない', () {
      expect(playerMatchStats(players: const [], sets: const []), isEmpty);
    });

    test('1 人用モード (セルフ 5 ターン) でも数えられる', () {
      // 上がりは無いので null、他は出る。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
              turn(2, {'a': 0}),
              turn(3, {'a': 4}),
              turn(4, {'a': 2}),
              turn(5, {'a': 8}),
            ],
            finals: {'a': 20},
          ),
        ],
      );
      expect(stats['a']!.missRate, 0.2);
      expect(stats['a']!.pointsPerThrow, 4.0);
      expect(stats['a']!.firstBreakAvg, 6.0);
      expect(stats['a']!.finishTurnAvg, isNull);
    });
  });

  group('アプリの自動入力 (codex 指摘 2026-11-04)', () {
    /// 自動入力つきのターン。
    TurnRecord autoTurn(int n, Map<String, int> scores, Set<String> auto) =>
        TurnRecord(n, scores, systemCalculated: auto);

    test('**自動入力は投擲として数えない**', () {
      // 他の全員が失格になると、残った人の不足点をアプリが書き込む。
      // 実際に投げた結果ではないので、ミス率も 1 投あたりの得点も歪める。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 0}),
              turn(2, {'a': 0}),
              autoTurn(3, {'a': 50}, {'a'}),
            ],
          ),
        ],
      );
      expect(stats['a']!.throws, 2, reason: '自動入力を投擲に数えている');
      expect(stats['a']!.points, 0, reason: '自動入力を得点に数えている');
      expect(stats['a']!.missRate, 1.0);
      expect(stats['a']!.pointsPerThrow, 0.0);
    });

    test('**相手の失格で繰り上がった上がりは 5 ターン扱い**', () {
      // ユーザ要望 2026-11-04。1 投は最大 12 点なので、自力で 50 点に
      // 届くには最低 5 投かかる。2 ターンで「上がった」ものをそのまま
      // 混ぜると、上がりの速さを実際より良く見せてしまう。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 0}),
              autoTurn(2, {'a': 50}, {'a'}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [kMinFinishTurns]);
      expect(stats['a']!.finishTurnAvg, 5.0);
      expect(stats['a']!.finishTurnText, '5.0(5/1)');
    });

    test('5 ターン以上かかっていればそのまま数える', () {
      // 「5 ターン以上の場合の不足点は未考慮のままで良い」(ユーザ判断)。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
              turn(2, {'a': 6}),
              turn(3, {'a': 6}),
              turn(4, {'a': 6}),
              turn(5, {'a': 6}),
              turn(6, {'a': 6}),
              autoTurn(7, {'a': 14}, {'a'}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [7]);
    });

    test('自力で上がったセットは下限の影響を受けない', () {
      // 1 投 12 点でも 50 点には 5 投かかるので、自力の上がりは必ず 5 以上。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
              turn(2, {'a': 12}),
              turn(3, {'a': 12}),
              turn(4, {'a': 12}),
              turn(5, {'a': 2}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [5]);
    });

    test('自動入力はファーストブレイクにもしない', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              autoTurn(1, {'a': 12}, {'a'}),
              turn(2, {'a': 3}),
            ],
          ),
        ],
      );
      expect(stats['a']!.firstBreaks, isEmpty);
      expect(stats['a']!.firstBreakAvg, isNull);
    });

    test('自動入力だけのセットでも参加セットには数える', () {
      // 投げていなくても、そのセットに居たことは変わらない。
      final stats = playerMatchStats(
        players: [player('a', setsWon: 1)],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              autoTurn(1, {'a': 50}, {'a'}),
            ],
          ),
        ],
      );
      expect(stats['a']!.setsPlayed, 1);
      expect(stats['a']!.winRate, 1.0);
      expect(stats['a']!.missRate, isNull, reason: '投げていないのに率が出た');
    });

    test('既知の抜け: 上書きされた実投擲は取り戻せない', () {
      // 残った人がそのターンで既に投げていると、書き込み側が同じターンの
      // 点を不足点で上書きする。記録に残っていないので、ここでは
      // 取り戻せない。**不足点を実投擲として数える方が害が大きい**ので、
      // その 1 投を落とす側に倒している。
      //
      // この振る舞いを固定しておく。書き込み側を直したら、このテストを
      // 「3 投・1 ミスになること」に書き換える。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
              turn(2, {'a': 6}),
              // 本当は a はこのターンで 0 を投げたが、不足点 38 で
              // 上書きされている。
              autoTurn(3, {'a': 38}, {'a'}),
            ],
          ),
        ],
      );
      expect(stats['a']!.throws, 2, reason: '上書きされた 1 投は数えられない');
      expect(stats['a']!.points, 12);
      expect(stats['a']!.pointsPerThrow, 6.0, reason: '不足点 38 を投擲に混ぜてはいけない');
    });

    test('同じターンで自動入力の人と実投擲の人が混ざっても取り違えない', () {
      final stats = playerMatchStats(
        players: [player('a'), player('b')],
        sets: [
          set(
            1,
            'a',
            ['a', 'b'],
            [
              autoTurn(1, {'a': 12, 'b': 0}, {'a'}),
            ],
          ),
        ],
      );
      expect(stats['a']!.throws, 0);
      expect(stats['b']!.throws, 1);
      expect(stats['b']!.misses, 1);
    });
  });

  group('百均モード (codex 指摘 2026-11-04)', () {
    test('**2 セット目の上がり点は 100 - 1 セット目の点**', () {
      // 1 セット目 40 点 → 2 セット目は 60 点で上がり。50 で見ると
      // 実際に上がった人を数えない。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 4; i += 1) turn(i, {'a': 10}),
            ],
            finals: {'a': 40},
          ),
          set(
            2,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 6; i += 1) turn(i, {'a': 10}),
            ],
            finals: {'a': 60},
          ),
        ],
        isHyakin: true,
      );
      expect(stats['a']!.finishTurns, [6], reason: '60 点の上がりを数えていない');
    });

    test('**2 セット目に 50 で止まったら上がっていない**', () {
      // 目標が 60 点なのに 50 点で終わったのは負け。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
            ],
            finals: {'a': 40},
          ),
          set(
            2,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
            ],
            finals: {'a': 50},
          ),
        ],
        isHyakin: true,
      );
      expect(stats['a']!.finishTurns, isEmpty, reason: '50 点を上がり扱いした');
    });

    test('百均の 1 セット目は 50 点で上がり', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 7; i += 1) turn(i, {'a': 7}),
            ],
            finals: {'a': 50},
          ),
        ],
        isHyakin: true,
      );
      expect(stats['a']!.finishTurns, [7]);
    });

    test('1 セット目の点が分からなければ 2 セット目は数えない', () {
      // 迷ったら数えない側に倒す (嘘の数字を出さない)。
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            2,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
            ],
            finals: {'a': 50},
          ),
        ],
        isHyakin: true,
      );
      expect(stats['a']!.finishTurns, isEmpty);
    });

    test('百均でなければ 2 セット目も 50 点で上がり', () {
      final stats = playerMatchStats(
        players: [player('a')],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 12}),
            ],
            finals: {'a': 40},
          ),
          set(
            2,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 7; i += 1) turn(i, {'a': 7}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      expect(stats['a']!.finishTurns, [7]);
    });
  });

  group('表示の形', () {
    test('割合は四捨五入して % にする', () {
      expect(formatPercent(0), '0%');
      expect(formatPercent(1), '100%');
      expect(formatPercent(0.333), '33%');
      expect(formatPercent(0.335), '34%');
      expect(formatPercent(null), '-');
    });

    test('平均は小数 1 桁', () {
      expect(formatAverage(0), '0.0');
      expect(formatAverage(5.25), '5.3');
      expect(formatAverage(12), '12.0');
      expect(formatAverage(null), '-');
    });

    // ユーザ要望 2026-11-04: 率や平均だけだと、1 回ぶんの結果なのか
    // 20 回ぶんなのか分からない。母数も一緒に出す。
    test('**割合は母数も出す**', () {
      expect(formatRate(2, 8), '25%(2/8)');
      expect(formatRate(0, 5), '0%(0/5)');
      expect(formatRate(3, 3), '100%(3/3)');
      expect(formatRate(2, 3), '67%(2/3)');
    });

    test('母数が 0 の割合は "-"', () {
      expect(formatRate(0, 0), '-');
      expect(formatRate(1, 0), '-');
      expect(formatRate(0, -1), '-');
    });

    test('**平均は 合計/回数 も出す**', () {
      expect(formatMean(16, 2), '8.0(16/2)');
      expect(formatMean(63, 15), '4.2(63/15)');
      expect(formatMean(0, 3), '0.0(0/3)');
    });

    test('母数が 0 の平均は "-"', () {
      expect(formatMean(0, 0), '-');
      expect(formatMean(10, 0), '-');
      expect(formatMean(10, -1), '-');
    });
  });

  group('画面に出す文字', () {
    test('5 つの数字がそれぞれ母数つきで出る', () {
      final stats = playerMatchStats(
        players: [player('a', setsWon: 1)],
        sets: [
          set(
            1,
            'a',
            ['a'],
            [
              turn(1, {'a': 8}),
              turn(2, {'a': 0}),
              turn(3, {'a': 12}),
              turn(4, {'a': 12}),
              turn(5, {'a': 12}),
              turn(6, {'a': 6}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      final st = stats['a']!;
      // 6 投のうち 1 ミス
      expect(st.missRateText, '17%(1/6)');
      // 先攻 1 セットで 1 投目は 8 本
      expect(st.firstBreakText, '8.0(8/1)');
      // 1 セット参加して 1 セット取った
      expect(st.winRateText, '100%(1/1)');
      // 6 ターンで上がった (1 セットぶん)
      expect(st.finishTurnText, '6.0(6/1)');
      // 50 点を 6 投で
      expect(st.pointsPerThrowText, '8.3(50/6)');
    });

    test('数えられていないものは "-"', () {
      final stats = playerMatchStats(players: [player('a')], sets: const []);
      final st = stats['a']!;
      expect(st.missRateText, '-');
      expect(st.firstBreakText, '-');
      expect(st.winRateText, '-');
      expect(st.finishTurnText, '-');
      expect(st.pointsPerThrowText, '-');
    });

    test('複数セットなら回数がその数になる', () {
      final stats = playerMatchStats(
        players: [player('a', setsWon: 2)],
        sets: [
          // 1 投目 10 本、5 ターンで上がる
          set(
            1,
            'a',
            ['a'],
            [
              for (var i = 1; i <= 5; i += 1) turn(i, {'a': 10}),
            ],
            finals: {'a': 50},
          ),
          // 1 投目 6 本、7 ターンで上がる
          set(
            2,
            'a',
            ['a'],
            [
              turn(1, {'a': 6}),
              for (var i = 2; i <= 7; i += 1) turn(i, {'a': 8}),
            ],
            finals: {'a': 50},
          ),
        ],
      );
      final st = stats['a']!;
      // 先攻 2 セットで 10 本と 6 本
      expect(st.firstBreakText, '8.0(16/2)');
      // 5 ターンと 7 ターンで上がった
      expect(st.finishTurnText, '6.0(12/2)');
      expect(st.winRateText, '100%(2/2)');
    });
  });
}
