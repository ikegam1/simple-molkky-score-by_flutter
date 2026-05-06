import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:simple_molkky_score/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/mock_firebase.dart';

// patrol 4.x では | 演算子が廃止されたため、.which() で OR 条件を表現する。
PatrolFinder _eitherText(PatrolIntegrationTester $, String ja, String en) =>
    $(Text).which(
      (w) =>
          (w as Text).data?.contains(ja) == true ||
          (w as Text).data?.contains(en) == true,
    );

void main() {
  patrolTest('Fixed 2 Sets Match Completion Test', ($) async {
    setupFirebaseMocks();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});

    await $.pumpWidgetAndSettle(const EasyMolkkyApp());

    // 1. 2人登録
    await $(TextField).enterText('A');
    await $(Icons.add).tap();
    await $(TextField).enterText('B');
    await $(Icons.add).tap();

    // 2. ゲーム開始
    await $.tap(_eitherText($, 'ゲーム開始', 'Start Game'));
    await $.pumpAndSettle();

    // --- 第1セット: Aが50点取る ---
    for (int i = 0; i < 5; i++) {
      await $(Text).containing('10').at(0).tap();
      await $.tap(_eitherText($, '決定', 'Confirm'));
      await $.pumpAndSettle();
      await $.tap(_eitherText($, '決定', 'Confirm')); // Bミス
      await $.pumpAndSettle();
    }

    // 第1セット勝利ダイアログ
    expect($(Text).containing('Set 1'), findsOneWidget);
    await $.tap(_eitherText($, '次のセットへ', 'Next Set'));
    await $.pumpAndSettle();

    // --- 第2セット: B先行 ---
    await $.tap(_eitherText($, '決定', 'Confirm')); // Bミス
    await $.pumpAndSettle();

    // Aが50点取る
    for (int i = 0; i < 5; i++) {
      await $(Text).containing('10').at(0).tap();
      await $.tap(_eitherText($, '決定', 'Confirm'));
      await $.pumpAndSettle();
      if (i < 4) {
        await $.tap(_eitherText($, '決定', 'Confirm'));
        await $.pumpAndSettle();
      }
    }

    // マッチ終了ダイアログ確認
    expect(_eitherText($, 'マッチ終了', 'Match Over'), findsOneWidget);
    expect(_eitherText($, '優勝: A', 'Winner: A'), findsOneWidget);
  });
}
