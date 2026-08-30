import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';
import 'package:simple_molkky_score/models/game_models.dart';

/// GameLogic.processThrow の `hillu37: true` 経路を検証する。
/// - currentScore を 25 に戻す
/// - consecutiveMisses は 1 加算 (3 発で失格ルールは通常のフォルトと同じ)
/// - scoreHistory / scoreSnapshot / missSnapshot が undo 可能な状態になる
void main() {
  MolkkyMatch makeMatch() {
    final p = Player(id: 'p1', name: 'A', initialOrder: 0);
    return MolkkyMatch(players: [p], limit: 99, type: MatchType.raceTo);
  }

  Player only(MolkkyMatch m) => m.players.first;

  test('37 点以上で hillu37 = true → 25 に戻る + 1 miss 加算', () {
    final m = makeMatch();
    final p = only(m);
    p.currentScore = 42;
    GameLogic.processThrow(p, [], m, hillu37: true);
    expect(p.currentScore, 25);
    expect(p.consecutiveMisses, 1);
    expect(p.isDisqualified, false);
    expect(p.scoreHistory, <int>[0]);
    // snapshot に投擲前値が積まれている (undo 可能)
    expect(p.scoreSnapshot, <int>[42]);
    expect(p.missSnapshot, <int>[0]);
  });

  test('hillu37 は knockedDownSkitels の値を無視 (常に 25 リセット)', () {
    final m = makeMatch();
    final p = only(m);
    p.currentScore = 45;
    GameLogic.processThrow(p, [12], m, hillu37: true);
    expect(p.currentScore, 25);
    expect(p.scoreHistory, <int>[0]);
  });

  test('hillu37 で 3 回連続なら isDisqualified = true', () {
    final m = makeMatch();
    final p = only(m);
    p.currentScore = 40;
    GameLogic.processThrow(p, [], m, hillu37: true); // miss=1
    p.currentScore = 40; // 演算上リセット後を再セット (テスト用)
    GameLogic.processThrow(p, [], m, hillu37: true); // miss=2
    p.currentScore = 40;
    GameLogic.processThrow(p, [], m, hillu37: true); // miss=3 → disqualified
    expect(p.consecutiveMisses, 3);
    expect(p.isDisqualified, true);
  });

  test('通常 processThrow (hillu37 なし) の挙動は変わらない', () {
    final m = makeMatch();
    final p = only(m);
    p.currentScore = 45;
    GameLogic.processThrow(p, [], m); // regular miss
    expect(p.currentScore, 45);
    expect(p.consecutiveMisses, 1);
    expect(p.scoreHistory, <int>[0]);
    GameLogic.processThrow(p, [3], m); // regular hit
    expect(p.currentScore, 48);
    expect(p.consecutiveMisses, 0);
    expect(p.scoreHistory, <int>[0, 3]);
  });
}
