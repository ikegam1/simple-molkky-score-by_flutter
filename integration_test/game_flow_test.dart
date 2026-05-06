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
  patrolTest('Basic Game Flow Test with Patrol', ($) async {
    setupFirebaseMocks();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});

    await $.pumpWidgetAndSettle(const EasyMolkkyApp());

    // 1. プレイヤー登録の検証
    final playerNameInput = $(TextField);
    await playerNameInput.enterText('Patrol User');
    await $.pump();

    await $(Icons.add).tap();
    await $.pumpAndSettle();

    expect($(Text).containing('1. Patrol User'), findsOneWidget);

    // 2. ゲーム開始
    await _eitherText($, 'ゲーム開始', 'Start Game').tap();
    await $.pumpAndSettle();

    // 3. ゲーム画面の検証
    expect(_eitherText($, '第 1 セット', 'Set 1'), findsOneWidget);
    expect(
      _eitherText($, 'Patrol User の番', "Patrol User's turn"),
      findsOneWidget,
    );

    // 4. スコア入力 (10点)
    await $(Text).containing('10').at(0).tap();
    await _eitherText($, '決定', 'Confirm').tap();
    await $.pumpAndSettle();

    // 5. ターンが進んだことを確認
    expect(_eitherText($, 'ターン 2', 'Turn 2'), findsOneWidget);
  });
}
