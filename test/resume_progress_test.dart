import 'package:flutter_test/flutter_test.dart';
import 'package:simple_molkky_score/logic/resume_progress.dart';

/// 中断再開時の進行状態の補正。
///
/// ユーザ報告 2026-09-19: セットが終わって次のセットが始まった直後に
/// トップへ戻り、中断試合を再開すると「スコアが空の枠が 5 行表示され、
/// 現在スコアが NaN」になる。
///
/// スナップショットが「試合データは次セットの開始状態 (スコア空) /
/// 画面の状態は前セットの最終ターン」という食い違った組み合わせで
/// 保存されていたのが原因。保存側は直したが、**食い違ったデータが端末に
/// 残っている**ので、読み出す側でも必ず突き合わせる。
void main() {
  group('sanitizeResumedProgress', () {
    test('記録が無ければ、入力途中のデータは捨てる', () {
      // セットが始まっていないのに前セットの状態が残っていると、前セットの
      // 勝者から投げ始めて、他の人の古い得点が混ざったターンが記録される。
      final r = sanitizeResumedProgress(
        savedTurn: 5,
        savedSetFinished: true,
        savedPlayerIndex: 2,
        recordedTurns: 0,
        minRecordedTurns: 0,
        playerCount: 3,
      );
      expect(r.discardPartialTurn, isTrue);
      expect(r.currentPlayerIndex, 0, reason: '前セットの勝者から始めてはいけない');
    });

    test('記録があれば入力途中のデータは残す', () {
      final r = sanitizeResumedProgress(
        savedTurn: 3,
        savedSetFinished: false,
        savedPlayerIndex: 1,
        recordedTurns: 3,
        minRecordedTurns: 2,
        playerCount: 3,
      );
      expect(r.discardPartialTurn, isFalse);
      expect(r.currentPlayerIndex, 1);
    });

    test('記録が無いのに 5 ターン目から再開しようとしたら 1 に戻す', () {
      // これが報告された状況そのもの。
      final r = sanitizeResumedProgress(
        savedTurn: 5,
        savedSetFinished: true,
        savedPlayerIndex: 0,
        recordedTurns: 0,
        playerCount: 3,
      );
      expect(r.currentTurnInSet, 1);
      expect(r.isSetFinished, isFalse, reason: '一投も無いのにセット終了扱いは詰む');
    });

    test('記録があるぶんは尊重する', () {
      final r = sanitizeResumedProgress(
        savedTurn: 3,
        savedSetFinished: false,
        savedPlayerIndex: 1,
        recordedTurns: 2,
        minRecordedTurns: 2,
        playerCount: 3,
      );
      expect(r.currentTurnInSet, 3, reason: '2 ターン記録済みなら 3 ターン目は妥当');
      expect(r.currentPlayerIndex, 1);
    });

    test('記録より先のターンは記録数 +1 で頭打ち', () {
      final r = sanitizeResumedProgress(
        savedTurn: 9,
        savedSetFinished: false,
        savedPlayerIndex: 0,
        recordedTurns: 4,
        playerCount: 2,
      );
      expect(r.currentTurnInSet, 5);
    });

    test('セット終了は記録があるときだけ通す', () {
      final r = sanitizeResumedProgress(
        savedTurn: 4,
        savedSetFinished: true,
        savedPlayerIndex: 0,
        recordedTurns: 4,
        playerCount: 2,
      );
      expect(r.isSetFinished, isTrue);
    });

    test('プレイヤー番号が人数を超えていたら先頭に戻す', () {
      // プレイヤーが減った状態で復元されると範囲外参照になる。
      final r = sanitizeResumedProgress(
        savedTurn: 1,
        savedSetFinished: false,
        savedPlayerIndex: 5,
        recordedTurns: 0,
        playerCount: 3,
      );
      expect(r.currentPlayerIndex, 0);
    });

    test('値が無い (旧スナップショット) なら初期値', () {
      final r = sanitizeResumedProgress(recordedTurns: 0, playerCount: 2);
      expect(r.currentTurnInSet, 1);
      expect(r.isSetFinished, isFalse);
      expect(r.currentPlayerIndex, 0);
    });

    test('不正な値でも記録から妥当なターンを割り出す', () {
      // 0 や負の値は信用せず、記録 (3 ターンぶん) から次は 4 ターン目と判断する。
      final r = sanitizeResumedProgress(
        savedTurn: 0,
        savedSetFinished: false,
        savedPlayerIndex: -1,
        recordedTurns: 3,
        minRecordedTurns: 3,
        playerCount: 2,
      );
      expect(r.currentTurnInSet, 4);
      expect(r.currentPlayerIndex, 0);
    });

    test('記録より遅れたターンは進める', () {
      // 進みすぎだけでなく遅れすぎも直す。そのままだと、次の入力は
      // 6 ターン目として積まれるのに画面は 1 ターン目と表示してしまう。
      final r = sanitizeResumedProgress(
        savedTurn: 1,
        savedSetFinished: false,
        savedPlayerIndex: 0,
        recordedTurns: 5,
        minRecordedTurns: 5,
        playerCount: 2,
      );
      expect(r.currentTurnInSet, 6);
    });

    test('ターンの途中 (一部だけ投げ終わり) なら、そのターンのまま', () {
      // 2 人中 1 人だけ 3 ターン目を投げた状態。いまは 3 ターン目。
      final r = sanitizeResumedProgress(
        savedTurn: 3,
        savedSetFinished: false,
        savedPlayerIndex: 1,
        recordedTurns: 3,
        minRecordedTurns: 2,
        playerCount: 2,
      );
      expect(r.currentTurnInSet, 3);
      expect(r.currentPlayerIndex, 1);
    });

    test('ターンの途中で保存値が無いなら、そのターンを続ける', () {
      final r = sanitizeResumedProgress(
        recordedTurns: 3,
        minRecordedTurns: 2,
        playerCount: 3,
      );
      expect(r.currentTurnInSet, 3);
    });

    test('プレイヤーが 0 人でも落ちない', () {
      final r = sanitizeResumedProgress(
        savedTurn: 2,
        savedSetFinished: true,
        savedPlayerIndex: 3,
        recordedTurns: 1,
        playerCount: 0,
      );
      expect(r.currentPlayerIndex, 0);
    });
  });
}
