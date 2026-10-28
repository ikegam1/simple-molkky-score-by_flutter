import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/match_record_status.dart';

/// 戦績レコードの判定のテスト。
///
/// 背景 (利用者からの要望 2026-10-28):
/// 3 先取で 2 対 1 の時点で中断すると、**どこにも結果が残らなかった**。
/// セットが終わるたびに保存し、戦績では既定で隠して、フィルタで
/// 「未完了の試合」を選んだときだけ出すようにした。
///
/// **ここを取り違えると、利用者の記録が見えなくなる。**
void main() {
  Map<String, dynamic> rec({String? type, bool? completed}) => {
    if (type != null) 'matchType': type,
    if (completed != null) 'completed': completed,
  };

  group('isCompletedRecord', () {
    test('完了の印があれば完了', () {
      expect(isCompletedRecord(rec(completed: true)), isTrue);
    });

    test('未完了の印があれば未完了', () {
      expect(isCompletedRecord(rec(completed: false)), isFalse);
    });

    test('印が無ければ完了扱い', () {
      // **ここが肝。** 途中経過を残すようにする前の戦績には印が無い。
      // 逆にすると、過去の記録が全部「未完了」に落ちて戦績から消える。
      expect(isCompletedRecord(rec()), isTrue);
      expect(isCompletedRecord(rec(type: 'MatchType.raceTo')), isTrue);
    });
  });

  group('matchesHistoryFilter', () {
    final done = rec(type: 'MatchType.raceTo', completed: true);
    final interrupted = rec(type: 'MatchType.raceTo', completed: false);
    final old = rec(type: 'MatchType.raceTo'); // 印の無い昔の記録
    final self5 = rec(type: 'MatchType.self5Turn', completed: true);
    final self5Interrupted = rec(type: 'MatchType.self5Turn', completed: false);

    test('すべて: 未完了は出さない', () {
      expect(matchesHistoryFilter(done, 'all'), isTrue);
      expect(matchesHistoryFilter(old, 'all'), isTrue);
      expect(matchesHistoryFilter(self5, 'all'), isTrue);
      expect(
        matchesHistoryFilter(interrupted, 'all'),
        isFalse,
        reason: '未完了が既定で出ると、普段見たい記録が探しにくくなる',
      );
    });

    test('未完了: 未完了だけ出す', () {
      expect(matchesHistoryFilter(interrupted, 'incomplete'), isTrue);
      expect(matchesHistoryFilter(self5Interrupted, 'incomplete'), isTrue);
      expect(matchesHistoryFilter(done, 'incomplete'), isFalse);
      expect(matchesHistoryFilter(old, 'incomplete'), isFalse);
    });

    test('通常試合: セルフ系と未完了を外す', () {
      expect(matchesHistoryFilter(done, 'normal'), isTrue);
      expect(matchesHistoryFilter(self5, 'normal'), isFalse);
      expect(matchesHistoryFilter(interrupted, 'normal'), isFalse);
    });

    test('セルフ5ターン: 種別が合うものだけ', () {
      expect(matchesHistoryFilter(self5, 'self5Turn'), isTrue);
      expect(matchesHistoryFilter(done, 'self5Turn'), isFalse);
      expect(
        matchesHistoryFilter(
          rec(type: 'MatchType.self6Turn', completed: true),
          'self5Turn',
        ),
        isFalse,
      );
    });

    test('種別で絞っても未完了は出さない', () {
      expect(matchesHistoryFilter(self5Interrupted, 'self5Turn'), isFalse);
    });
  });

  group('historyFilterOptions', () {
    test('種別が 1 つしかなければ種別は選ばせない', () {
      // 「すべて」と同じ意味になるので出す意味が無い。
      expect(
        historyFilterOptions(
          hasNormal: true,
          hasSelf5Turn: false,
          hasSelf6Turn: false,
          hasIncomplete: false,
        ),
        {'all'},
      );
    });

    test('種別が 2 つ以上あれば選ばせる', () {
      expect(
        historyFilterOptions(
          hasNormal: true,
          hasSelf5Turn: true,
          hasSelf6Turn: false,
          hasIncomplete: false,
        ),
        {'all', 'normal', 'self5Turn'},
      );
    });

    test('未完了があれば、種別が 1 つでも選択肢に出す', () {
      // 通常試合しか使っていない人でも「未完了」を選べる必要がある。
      expect(
        historyFilterOptions(
          hasNormal: true,
          hasSelf5Turn: false,
          hasSelf6Turn: false,
          hasIncomplete: true,
        ),
        {'all', 'incomplete'},
      );
    });
  });

  group('effectiveHistoryFilter', () {
    test('選択肢にある値はそのまま', () {
      expect(
        effectiveHistoryFilter(
          filter: 'incomplete',
          available: {'all', 'incomplete'},
        ),
        'incomplete',
      );
    });

    test('選択肢から消えた値は「すべて」に戻す', () {
      // **選択肢に無い値を持ち続けると画面が落ちる。**
      expect(
        effectiveHistoryFilter(filter: 'incomplete', available: {'all'}),
        'all',
      );
    });

    test('種別が 1 つだけ消えた場合も戻す', () {
      // 他の種別が残っているので「選択肢の数」で見ると見逃す
      // (codex 指摘 2026-10-28)。
      expect(
        effectiveHistoryFilter(
          filter: 'self5Turn',
          available: {'all', 'normal', 'self6Turn'},
        ),
        'all',
      );
    });

    test('「すべて」はそのまま', () {
      expect(effectiveHistoryFilter(filter: 'all', available: {'all'}), 'all');
    });
  });

  group('matchTypeLabelOf', () {
    test('試合中の表記と揃っている', () {
      expect(
        matchTypeLabelOf({'matchType': 'MatchType.raceTo', 'limit': 3}),
        '3先取',
      );
      expect(
        matchTypeLabelOf({'matchType': 'MatchType.fixedSets', 'limit': 2}),
        '2セット',
      );
      expect(matchTypeLabelOf({'matchType': 'MatchType.hyakin'}), '百均モード');
      expect(matchTypeLabelOf({'matchType': 'MatchType.threeGame'}), '3番');
      expect(matchTypeLabelOf({'matchType': 'MatchType.self5Turn'}), 'セルフ5ターン');
      expect(matchTypeLabelOf({'matchType': 'MatchType.self6Turn'}), 'セルフ6ターン');
    });

    test('知らない種別では空にする', () {
      expect(matchTypeLabelOf({'matchType': 'MatchType.unknown'}), '');
      expect(matchTypeLabelOf({}), '');
    });
  });
}
