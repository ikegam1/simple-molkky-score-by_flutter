
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:simple_molkky_score/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/mock_firebase.dart';

void main() {
  patrolTest(
    'RaceTo 2 Match Completion Test',
    ($) async {
      setupFirebaseMocks();
      await Firebase.initializeApp();
      SharedPreferences.setMockInitialValues({});

      await $.pumpWidgetAndSettle(const EasyMolkkyApp());

      // 1. 2人登録 (A, B)
      await $(TextField).enterText('Player A');
      await $(Icons.add).tap();
      await $(TextField).enterText('Player B');
      await $(Icons.add).tap();
      await $.pumpAndSettle();

      // 2. 「2先」モードを選択 (デフォルトが3=2先なのでそのまま)
      await $.tap($(Text).containing('ゲーム開始') | $(Text).containing('Start Game'));
      await $.pumpAndSettle();

      // --- 第1セット ---
      // Aが50点取る (10点 x 5回)
      for (int i = 0; i < 5; i++) {
        await $(Text).containing('10').at(0).tap();
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
        await $.pumpAndSettle();
        // Bの番はミス(決定のみ)
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
        await $.pumpAndSettle();
      }
      // Aが勝利
      expect($(Text).containing('Wins') | $(Text).containing('勝利'), findsOneWidget);
      // 次のセットへ (並び替えは無視して「次のセットへ」)
      await $.tap($(Text).containing('Next Set') | $(Text).containing('次のセットへ'));
      await $.pumpAndSettle();

      // --- 第2セット ---
      // 今度はBが先行のはずだが、Aがまた50点取ってマッチ終了させる
      // (Bが先行の場合は Aの番まで進める)
      if ($(Text).containing('Player B の番').exists) {
         await $.tap($(Text).containing('決定') | $(Text).containing('Confirm')); // Bミス
         await $.pumpAndSettle();
      }

      for (int i = 0; i < 5; i++) {
        await $(Text).containing('10').at(0).tap();
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
        await $.pumpAndSettle();
        if (i < 4) { // 最後の投擲以外はBを回す
          await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
          await $.pumpAndSettle();
        }
      }

      // --- ここがバグの発生地点 ---
      // Aが2セット取ったので、即座に「マッチ終了」ダイアログが出るべき
      expect($(Text).containing('マッチ終了') | $(Text).containing('Match Over'), findsOneWidget);
      expect($(Text).containing('優勝: Player A') | $(Text).containing('Winner: Player A'), findsOneWidget);
    },
  );
}
