
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:simple_molkky_score/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/mock_firebase.dart'; // さきほど作成したモックを再利用

void main() {
  patrolTest(
    'Basic Game Flow Test with Patrol',
    ($) async {
      setupFirebaseMocks();
      await Firebase.initializeApp();
      SharedPreferences.setMockInitialValues({});

      await $.pumpWidgetAndSettle(const EasyMolkkyApp());

      // 1. プレイヤー登録の検証
      final playerNameInput = $(TextField);
      await playerNameInput.enterText('Patrol User');
      await $.pump();

      // 追加ボタン（Icons.add）をタップ
      await $(#add_button_icon).tap(); // main.dart で Key を追加する必要があります
      // もしくはアイコンで探す
      await $(Icons.add).tap();
      await $.pumpAndSettle();

      expect($(Text).containing('1. Patrol User'), findsOneWidget);

      // 2. ゲーム開始
      // 日本語環境なら「ゲーム開始」、英語なら「Start Game」
      final startButton = $(Text).containing('ゲーム開始') | $(Text).containing('Start Game');
      await startButton.tap();
      await $.pumpAndSettle();

      // 3. ゲーム画面の検証
      expect($(Text).containing('第 1 セット') | $(Text).containing('Set 1'), findsOneWidget);
      expect($(Text).containing('Patrol User の番') | $(Text).containing('Patrol User\'s turn'), findsOneWidget);

      // 4. スコア入力 (10点)
      await $(Text).containing('10').at(0).tap();
      await $(Text).containing('決定') | $(Text).containing('Confirm').tap();
      await $.pumpAndSettle();

      // 5. ターンが進んだことを確認
      expect($(Text).containing('ターン 2') | $(Text).containing('Turn 2'), findsOneWidget);
    },
  );
}
