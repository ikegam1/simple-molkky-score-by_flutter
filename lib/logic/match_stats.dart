import 'dart:math' as math;

import '../models/game_models.dart';

/// 試合結果の画像に出す「プレイヤーごとの成績」。
///
/// **結果画像に入れるために切り出してある** (ユーザ要望 2026-11-04)。
/// 画面を組み立てずに数字だけ試せるよう、Widget から独立させている。
///
/// 数えられなかったものは **0 ではなく null** を返す。0 だと「0% だった」
/// のように読めてしまうが、実際は「まだ 1 回も無い」なので意味が違う。
class PlayerMatchStats {
  const PlayerMatchStats({
    required this.playerId,
    required this.throws,
    required this.misses,
    required this.points,
    required this.setsPlayed,
    required this.setsWon,
    required this.firstBreaks,
    required this.finishTurns,
  });

  final String playerId;

  /// 投げた回数。
  final int throws;

  /// 0 本だった投擲の数 (ミス)。
  final int misses;

  /// 得点の合計 (1 投ごとの点の和)。
  ///
  /// **セットの最終スコアの合計ではない。** 50 を超えて 25 に戻された分も
  /// 「倒した本数」としては投げた結果なので、こちらで数える。
  final int points;

  /// 参加したセットの数。
  final int setsPlayed;

  /// 取ったセットの数。
  final int setsWon;

  /// **先に投げたセットでの 1 投目の点。**
  ///
  /// ファーストブレイクは「ピンが全部立っている状態への 1 投目」なので、
  /// そのセットで先に投げた人にしか起きない。後攻の 1 投目は崩れた並びへの
  /// 投擲なので数えない。
  final List<int> firstBreaks;

  /// 上がったセットで、上がるまでにかかったターン数。
  ///
  /// **下限は [kMinFinishTurns] ターン。** 相手の失格で繰り上がって
  /// 上がった分を、そのままの短いターン数で混ぜない。
  final List<int> finishTurns;

  /// ミス率 (0〜1)。1 回も投げていなければ null。
  double? get missRate => throws == 0 ? null : misses / throws;

  /// ファーストブレイクの平均本数。先に投げたセットが無ければ null。
  double? get firstBreakAvg =>
      firstBreaks.isEmpty
          ? null
          : firstBreaks.reduce((a, b) => a + b) / firstBreaks.length;

  /// 勝率 (0〜1)。参加したセットが無ければ null。
  double? get winRate =>
      setsPlayed == 0 ? null : (setsWon / setsPlayed).clamp(0.0, 1.0);

  /// 平均の上がりターン数。1 度も上がっていなければ null。
  double? get finishTurnAvg =>
      finishTurns.isEmpty
          ? null
          : finishTurns.reduce((a, b) => a + b) / finishTurns.length;

  /// 1 投あたりの平均得点。1 回も投げていなければ null。
  double? get pointsPerThrow => throws == 0 ? null : points / throws;

  // ── 画面に出す文字 ─────────────────────────────────────────
  //
  // **母数も一緒に出す** (ユーザ要望 2026-11-04: `25%(2/8)` のように)。
  // 率や平均だけだと、1 回ぶんの結果なのか 20 回ぶんなのか分からない。

  /// 例: `25%(2/8)`。数えられていなければ "-"。
  String get missRateText => formatRate(misses, throws);

  /// 例: `8.0(16/2)` (2 セットで合計 16 本)。
  String get firstBreakText => formatMean(
    firstBreaks.isEmpty ? 0 : firstBreaks.reduce((a, b) => a + b),
    firstBreaks.length,
  );

  /// 例: `67%(2/3)`。
  ///
  /// **100% を超えないようにする。** 保存の都合で勝ち数が参加セット数を
  /// 上回ることがあり、そのまま出すと `500%(5/1)` のような数字になる
  /// (codex 指摘 2026-11-04)。[winRate] 側では clamp しているので、
  /// 表示だけ素通りしないよう揃える。
  String get winRateText =>
      formatRate(math.min(setsWon, setsPlayed), setsPlayed);

  /// 例: `5.0(10/2)` (2 セットで合計 10 ターン)。
  String get finishTurnText => formatMean(
    finishTurns.isEmpty ? 0 : finishTurns.reduce((a, b) => a + b),
    finishTurns.length,
  );

  /// 例: `4.2(63/15)` (15 投で合計 63 点)。
  String get pointsPerThrowText => formatMean(points, throws);
}

/// 通常の上がり点。
const int _kTargetScore = 50;

/// 百均モードの通し点。2 セット目の上がりは `100 - 1 セット目の点`。
const int _kHyakinTotal = 100;

/// 上がりターン数の下限。
///
/// **相手の失格で繰り上がって上がったセットを、そのままの短いターン数で
/// 数えない** (ユーザ要望 2026-11-04)。1 投は最大 12 点なので、自分で
/// 投げて 50 点に届くには最低 5 投かかる。相手が 3 ミスで失格になって
/// 2 ターンで「上がった」ものを 2 として平均に混ぜると、上がりの速さを
/// 実際より良く見せてしまう。
///
/// 自力で上がった場合は必ず 5 以上なので、一律に下限を当てても影響しない。
const int kMinFinishTurns = 5;

/// プレイヤーごとの成績を数える。
///
/// [sets] は結果画像に出すセットの一覧。[players] はその試合の選手。
/// [isHyakin] は百均モードかどうか (2 セット目の上がり点が人によって違う)。
/// 返すのは `playerId` を鍵にした対応表。
Map<String, PlayerMatchStats> playerMatchStats({
  required List<Player> players,
  required List<SetRecord> sets,
  bool isHyakin = false,
}) {
  final throwsOf = <String, int>{};
  final missesOf = <String, int>{};
  final pointsOf = <String, int>{};
  final setsPlayedOf = <String, int>{};
  final firstBreaksOf = <String, List<int>>{};
  final finishTurnsOf = <String, List<int>>{};

  for (final p in players) {
    throwsOf[p.id] = 0;
    missesOf[p.id] = 0;
    pointsOf[p.id] = 0;
    setsPlayedOf[p.id] = 0;
    firstBreaksOf[p.id] = <int>[];
    finishTurnsOf[p.id] = <int>[];
  }

  // 百均の 2 セット目の上がり点を出すのに、1 セット目の点が要る。
  final set1Final = <String, int>{};
  if (isHyakin) {
    for (final set in sets) {
      if (set.setNumber != 1) continue;
      set1Final.addAll(set.finalCumulativeScores);
    }
  }

  for (final set in sets) {
    // **中身の無いセットは数えない。** 始まる前の器が混ざると、
    // 参加セット数だけ増えて勝率が下がる。
    if (set.turns.isEmpty) continue;

    // ターン番号の小さい順に見る。保存の都合で並びが崩れていても
    // 「1 投目」を取り違えないように。
    final turns = List<TurnRecord>.from(set.turns)
      ..sort((a, b) => a.turnNumber.compareTo(b.turnNumber));

    // この人がこのセットで最後に点が入ったターン番号。
    final lastTurnOf = <String, int>{};

    for (final turn in turns) {
      for (final entry in turn.scores.entries) {
        final id = entry.key;
        if (!throwsOf.containsKey(id)) continue;
        final score = entry.value;
        // **アプリが自動で入れた点は投擲として数えない。**
        // 他の全員が失格になったとき、残った人の不足点をアプリが
        // 書き込む。これは実際に投げた結果ではないので、ミス率も
        // 1 投あたりの得点も歪める (codex 指摘 2026-11-04)。
        //
        // **既知の抜け**: 残った人がそのターンで既に投げていた場合、
        // 書き込み側 (`_submitThrow`) が同じターンの点を不足点で
        // 上書きするため、その 1 投は記録に残っていない。ここでは
        // 取り戻せないので、その 1 投だけ投擲数から漏れる。
        // 不足点 (最大 50) を実投擲として数える方が害が大きいので、
        // 落とす側に倒している。
        // 起きるのは「2 人以上の試合で自分以外が全員失格」のときだけ。
        final isAuto = turn.systemCalculatedPlayerIds.contains(id);
        if (!isAuto) {
          throwsOf[id] = (throwsOf[id] ?? 0) + 1;
          pointsOf[id] = (pointsOf[id] ?? 0) + score;
          if (score == 0) missesOf[id] = (missesOf[id] ?? 0) + 1;
        }
        final prev = lastTurnOf[id];
        if (prev == null || turn.turnNumber > prev) {
          lastTurnOf[id] = turn.turnNumber;
        }
      }
    }

    for (final id in lastTurnOf.keys) {
      setsPlayedOf[id] = (setsPlayedOf[id] ?? 0) + 1;
    }

    // ファーストブレイクは、このセットで先に投げた人の 1 投目だけ。
    final starter = set.starterPlayerId;
    if (firstBreaksOf.containsKey(starter)) {
      for (final turn in turns) {
        final v = turn.scores[starter];
        if (v == null) continue;
        // 自動入力は投擲ではないので、ファーストブレイクにもしない。
        if (!turn.systemCalculatedPlayerIds.contains(starter)) {
          firstBreaksOf[starter]?.add(v);
        }
        break;
      }
    }

    // 上がったセットは、その人がそのセットで最後に投げたターンが
    // 上がりのターン (上がった瞬間にセットが終わる)。
    for (final entry in set.finalCumulativeScores.entries) {
      final id = entry.key;
      if (!finishTurnsOf.containsKey(id)) continue;
      final target = _targetScoreOf(
        isHyakin: isHyakin,
        setNumber: set.setNumber,
        set1Score: set1Final[id],
      );
      if (target == null || entry.value != target) continue;
      final turn = lastTurnOf[id];
      if (turn == null) continue;
      // **下限 5 ターン。** 相手の失格で繰り上がって上がった分を、
      // そのままの短いターン数で平均に混ぜない ([kMinFinishTurns])。
      finishTurnsOf[id]?.add(math.max(turn, kMinFinishTurns));
    }
  }

  final out = <String, PlayerMatchStats>{};
  for (final p in players) {
    out[p.id] = PlayerMatchStats(
      playerId: p.id,
      throws: throwsOf[p.id] ?? 0,
      misses: missesOf[p.id] ?? 0,
      points: pointsOf[p.id] ?? 0,
      setsPlayed: setsPlayedOf[p.id] ?? 0,
      setsWon: p.setsWon,
      firstBreaks: firstBreaksOf[p.id] ?? const <int>[],
      finishTurns: finishTurnsOf[p.id] ?? const <int>[],
    );
  }
  return out;
}

/// そのセットで「上がり」とみなす点。分からなければ null。
///
/// **百均の 2 セット目は人によって違う。** 1 セット目で取った点のぶん
/// だけ低くなる (`100 - 1 セット目の点`)。50 で見ると、実際に上がった人を
/// 数えなかったり、上がっていない人を数えたりする (codex 指摘 2026-11-04)。
int? _targetScoreOf({
  required bool isHyakin,
  required int setNumber,
  required int? set1Score,
}) {
  if (!isHyakin || setNumber != 2) return _kTargetScore;
  if (set1Score == null) return null;
  return _kHyakinTotal - set1Score;
}

/// 割合を「12%」の形にする。数えられていなければ "-"。
String formatPercent(double? v) => v == null ? '-' : '${(v * 100).round()}%';

/// 平均を小数 1 桁にする。数えられていなければ "-"。
String formatAverage(double? v) => v == null ? '-' : v.toStringAsFixed(1);

/// 割合を「25%(2/8)」の形にする。母数が 0 なら "-"。
String formatRate(int numerator, int denominator) {
  if (denominator <= 0) return '-';
  final pct = (numerator / denominator * 100).round();
  return '$pct%($numerator/$denominator)';
}

/// 平均を「8.0(16/2)」の形にする。母数が 0 なら "-"。
String formatMean(int total, int count) {
  if (count <= 0) return '-';
  return '${(total / count).toStringAsFixed(1)}($total/$count)';
}
