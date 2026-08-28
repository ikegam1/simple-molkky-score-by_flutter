import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// consecutiveMisses が undo で正しく復元されることを検証する。
///
/// 修正前は「非ミス投擲 (points > 0) を undo」した際、processThrow で
/// miss=0 にリセットされた値が復元されず、続けてミスを入れても 3-miss
/// 失格が発火しないバグがあった。missSnapshot 導入でこれを解消する。
void main() {
  MolkkyMatch makeMatch() {
    final p = Player(id: 'p1', name: 'A', initialOrder: 0);
    return MolkkyMatch(players: [p], limit: 99, type: MatchType.raceTo);
  }

  Player only(MolkkyMatch m) => m.players.first;

  group('processThrow は投擲前 consecutiveMisses を missSnapshot に積む', () {
    test('連続ミス → missSnapshot に投擲前値が順に入る', () {
      final m = makeMatch();
      final p = only(m);
      // 3 回連続でミスを投擲: 投擲前 miss はそれぞれ 0, 1, 2
      GameLogic.processThrow(p, [], m);
      GameLogic.processThrow(p, [], m);
      // 3 回目投擲前は disqualified になっているので processThrow は no-op。
      // ここでは 2 投目までを検証。
      expect(p.missSnapshot, <int>[0, 1]);
    });

    test('非ミス投擲でも missSnapshot に投擲前値が積まれる', () {
      final m = makeMatch();
      final p = only(m);
      GameLogic.processThrow(p, [], m); // miss (before=0)
      GameLogic.processThrow(p, [3], m); // 3 (before=1)
      expect(p.missSnapshot, <int>[0, 1]);
      // 非ミス投擲後、live の miss は 0 にリセット済み
      expect(p.consecutiveMisses, 0);
    });
  });

  group('missSnapshot からの undo 復元 (main.dart の _undo と同じロジック)', () {
    // _undo() は private のためロジックを inline で再現。
    // production コード側と挙動が乖離しないよう、main.dart のスニペットと
    // 完全に同じ判定 (`consecutiveMisses >= maxMisses`) にしている。
    void undoLike(MolkkyMatch m, Player p) {
      if (p.scoreHistory.isEmpty) return;
      p.scoreHistory.removeLast();
      if (p.scoreSnapshot.isNotEmpty) {
        p.currentScore = p.scoreSnapshot.removeLast();
      }
      if (p.missSnapshot.isNotEmpty) {
        p.consecutiveMisses = p.missSnapshot.removeLast();
        p.isDisqualified = p.consecutiveMisses >= m.maxMisses;
      }
    }

    test('2 ミス → 非ミス投擲 → undo → ミス投擲で 3 ミス失格', () {
      final m = makeMatch();
      final p = only(m);
      GameLogic.processThrow(p, [], m); // 1 miss
      GameLogic.processThrow(p, [], m); // 2 miss
      expect(p.consecutiveMisses, 2);

      GameLogic.processThrow(p, [5], m); // wrong 5-point
      expect(p.consecutiveMisses, 0, reason: '得点でリセット');
      expect(p.currentScore, 5);

      undoLike(m, p);
      expect(
        p.consecutiveMisses,
        2,
        reason: '非ミス投擲を undo したら投擲前の 2 に戻る (旧実装は 0 のままだった)',
      );
      expect(p.currentScore, 0);
      expect(p.isDisqualified, false);

      // 続けて miss → 3 ミス失格が発火する
      GameLogic.processThrow(p, [], m);
      expect(p.consecutiveMisses, 3);
      expect(p.isDisqualified, true);
    });

    test('ミス投擲を undo → miss と disqualified が投擲前に戻る', () {
      final m = makeMatch();
      final p = only(m);
      GameLogic.processThrow(p, [], m);
      GameLogic.processThrow(p, [], m);
      GameLogic.processThrow(p, [], m); // 3 miss → disqualified
      expect(p.isDisqualified, true);

      undoLike(m, p);
      expect(p.consecutiveMisses, 2);
      expect(p.isDisqualified, false);
    });
  });

  test('resetForNewSet は missSnapshot もクリア', () {
    final p = Player(id: 'p1', name: 'A', initialOrder: 0);
    p.missSnapshot = [0, 1, 2];
    p.consecutiveMisses = 3;
    p.isDisqualified = true;
    p.resetForNewSet();
    expect(p.missSnapshot, isEmpty);
    expect(p.consecutiveMisses, 0);
    expect(p.isDisqualified, false);
  });
}
