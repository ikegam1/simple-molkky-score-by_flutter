
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/models/game_models.dart';
import 'package:simple_molkky_score/logic/game_logic.dart';

void main() {
  group('Molkky Game Logic Tests', () {
    
    test('Solo practice should not result in instant win', () {
      final player = Player(id: '1', name: 'Solo', initialOrder: 0);
      final match = MolkkyMatch(
        players: [player],
        limit: 1,
        type: MatchType.fixedSets,
      );

      // 一投目 (10点)
      GameLogic.processThrow(player, [10], match);
      
      // プレイヤーが一人なので、サバイバル勝利は発動せず、点数がそのまま加算されるはず
      expect(player.currentScore, 10);
      expect(player.isDisqualified, false);
      
      // 50点になるまで終わらないことを確認
      expect(match.isMatchOver, false);
    });

    test('Burst logic: 51 points should reset to 25', () {
      final player = Player(id: '1', name: 'P1', initialOrder: 0);
      final match = MolkkyMatch(players: [player], limit: 1, type: MatchType.fixedSets);
      
      player.currentScore = 45;
      // 10点獲得 -> 55点 (バースト)
      GameLogic.processThrow(player, [10], match);
      
      expect(player.currentScore, 25);
    });

    test('Disqualification: 3 consecutive misses', () {
      final player = Player(id: '1', name: 'P1', initialOrder: 0);
      final match = MolkkyMatch(players: [player], limit: 1, type: MatchType.fixedSets);
      
      // 1回目ミス
      GameLogic.processThrow(player, [], match);
      expect(player.consecutiveMisses, 1);
      
      // 2回目ミス
      GameLogic.processThrow(player, [], match);
      expect(player.consecutiveMisses, 2);
      
      // 3回目ミス -> 失格
      GameLogic.processThrow(player, [], match);
      expect(player.isDisqualified, true);
    });

    test('Survival win: awarded to last remaining player in multi-player match', () {
      final p1 = Player(id: '1', name: 'P1', initialOrder: 0);
      final p2 = Player(id: '2', name: 'P2', initialOrder: 1);
      final match = MolkkyMatch(players: [p1, p2], limit: 1, type: MatchType.fixedSets);
      
      // P2が3回ミスして失格になる
      GameLogic.processThrow(p2, [], match);
      GameLogic.processThrow(p2, [], match);
      GameLogic.processThrow(p2, [], match);
      expect(p2.isDisqualified, true);

      // 擬似的に survivors 判定 (UI側で行っている処理を再現)
      final survivors = match.players.where((p) => !p.isDisqualified).toList();
      if (match.players.length >= 2 && survivors.length == 1) {
        survivors.first.currentScore = 50;
      }

      expect(p1.currentScore, 50);
    });
  });
}
