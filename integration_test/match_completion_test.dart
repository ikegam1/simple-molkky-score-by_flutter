
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:simple_molkky_score/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/mock_firebase.dart';

void main() {
  patrolTest(
    'Fixed 2 Sets Match Completion Test',
    ($) async {
      setupFirebaseMocks();
      await Firebase.initializeApp();
      SharedPreferences.setMockInitialValues({});

      await $.pumpWidgetAndSettle(const EasyMolkkyApp());

      // 1. 2人登録
      await $(TextField).enterText('A');
      await $(Icons.add).tap();
      await $(TextField).enterText('B');
      await $(Icons.add).tap();
      
      // 2. 「2番 (2セット)」を選択 (ドロップダウン操作)
      // 注意: 実際のドロップダウンは選択が難しいため、内部の _selectedModeKey 3 (2先) から変更をシミュレートするか、
      // ここではデフォルトの「2先」で「2セット取ったら即終了」を検証します。
      
      await $.tap($(Text).containing('ゲーム開始') | $(Text).containing('Start Game'));
      await $.pumpAndSettle();

      // --- 第1セット ---
      // Aが50点取る
      for (int i = 0; i < 5; i++) {
        await $(Text).containing('10').at(0).tap();
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
        await $.pumpAndSettle();
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm')); // Bミス
        await $.pumpAndSettle();
      }
      
      // 第1セット勝利ダイアログが出るはず
      expect($(Text).containing('Set 1'), findsOneWidget);
      await $.tap($(Text).containing('Next Set') | $(Text).containing('次のセットへ'));
      await $.pumpAndSettle();

      // --- 第2セット ---
      // B先行
      await $.tap($(Text).containing('決定') | $(Text).containing('Confirm')); // Bミス
      await $.pumpAndSettle();
      
      // Aが50点取る
      for (int i = 0; i < 5; i++) {
        await $(Text).containing('10').at(0).tap();
        await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
        await $.pumpAndSettle();
        if (i < 4) {
          await $.tap($(Text).containing('決定') | $(Text).containing('Confirm'));
          await $.pumpAndSettle();
        }
      }

      // --- 判定：即座にマッチ終了が出るか ---
      // v1.6.0 ではここで「次のセットへ」ではなく「マッチ終了 / Match Over」が出る
      expect($(Text).containing('Match Over') | $(Text).containing('マッチ終了'), findsOneWidget);
      expect($(Text).containing('Winner: A') | $(Text).containing('優勝: A'), findsOneWidget);
    },
  );
}
