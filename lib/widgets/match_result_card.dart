import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../utils/image_downloader.dart';

const _kAppUrl = 'easy-molkky-score.ikegam1.com';

// ── 結果サマリーカード ────────────────────────────────────────────
class MatchResultCard extends StatelessWidget {
  const MatchResultCard({
    super.key,
    required this.match,
    required this.sets,
    required this.isMatchDraw,
    required this.winnerName,
    required this.matchTypeName,
  });

  final MolkkyMatch match;
  final List<SetRecord> sets;
  final bool isMatchDraw;
  final String winnerName;
  final String matchTypeName;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Player>.from(match.players)..sort((a, b) {
      final sc = b.setsWon.compareTo(a.setsWon);
      if (sc != 0) return sc;
      return b.totalMatchScore.compareTo(a.totalMatchScore);
    });

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ヘッダー ──
          const Text(
            'Easy Molkky Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}　$matchTypeName',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 14),

          // ── 勝者 / 引き分け ──
          Text(
            isMatchDraw ? '🤝 引き分け' : '🏆 $winnerName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // ── サマリーテーブル ──
          _SummaryTable(players: sorted),
          const SizedBox(height: 16),

          // ── セット詳細 ──
          for (final set in sets) ...[
            _SetDetailSection(set: set, players: match.players),
            const SizedBox(height: 12),
          ],

          // ── フッター ──
          const Divider(height: 14),
          Text(
            'Easy Molkky Score  $_kAppUrl',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── サマリーテーブル（順位・名前・セット・合計）────────────────────
class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.players});
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(24),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(52),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE3F2FD)),
          children: [_hdr(''), _hdr('名前'), _hdr('セット'), _hdr('合計')],
        ),
        for (int i = 0; i < players.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFFFF9C4) : Colors.white,
            ),
            children: [
              _cell('${i + 1}'),
              _cell(players[i].name, align: TextAlign.left),
              _cell('${players[i].setsWon}'),
              _cell('${players[i].totalMatchScore}'),
            ],
          ),
      ],
    );
  }

  static Widget _hdr(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  static Widget _cell(String t, {TextAlign align = TextAlign.center}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(t, textAlign: align, style: const TextStyle(fontSize: 11)),
      );
}

// ── セット詳細（ターン別スコア）────────────────────────────────────
class _SetDetailSection extends StatelessWidget {
  const _SetDetailSection({required this.set, required this.players});

  final SetRecord set;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    // 投擲順に並べたプレイヤーリスト
    final ordered = <Player>[];
    for (final id in set.playerOrder) {
      final p = players.firstWhere(
        (p) => p.id == id,
        orElse: () => Player(id: id, name: '???', initialOrder: 0),
      );
      ordered.add(p);
    }

    final colWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(28), // ターン番号
    };
    for (int i = 0; i < ordered.length; i++) {
      colWidths[i + 1] = const FlexColumnWidth();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // セットヘッダー
        Container(
          color: const Color(0xFFE3F2FD),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Set ${set.setNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Table(
          columnWidths: colWidths,
          border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 0.5),
          children: [
            // 列ヘッダー
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              children: [
                _cell('T', bold: true),
                ...ordered.map(
                  (p) => _cell(
                    p.name.length > 6 ? '${p.name.substring(0, 6)}…' : p.name,
                    bold: true,
                  ),
                ),
              ],
            ),
            // ターン行
            for (final turn in set.turns)
              TableRow(
                children: [
                  _cell('${turn.turnNumber}'),
                  ...ordered.map((p) {
                    final isSys = turn.systemCalculatedPlayerIds.contains(p.id);
                    final score = turn.scores[p.id];
                    if (isSys) return _cell('-');
                    if (score == null) return _cell('');
                    final ann = turn.scoreAnnotations[p.id] ?? 0;
                    return _annotatedCell(score, ann);
                  }),
                ],
              ),
            // 累計行
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFFF8E1)),
              children: [
                _cell('計', bold: true),
                ...ordered.map(
                  (p) => _cell(
                    '${set.finalCumulativeScores[p.id] ?? 0}',
                    bold: true,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Widget _cell(String t, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
    ),
  );

  static Widget _annotatedCell(int score, int annotation) {
    const style = TextStyle(fontSize: 10);
    if (annotation == 0 || score == 0) return _cell('$score');
    const pad = EdgeInsets.symmetric(horizontal: 3, vertical: 3);
    switch (annotation) {
      case 1: // ◯囲み
      case 2: // □囲み
        const sz = 14.0;
        return Padding(
          padding: pad,
          child: Center(
            child: Container(
              width: sz,
              height: sz,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: annotation == 1 ? BoxShape.circle : BoxShape.rectangle,
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: annotation == 2 ? BorderRadius.circular(2) : null,
              ),
              child: Text(
                '$score',
                textAlign: TextAlign.center,
                style: style.copyWith(fontSize: 8),
              ),
            ),
          ),
        );
      case 3: // 寄せ成功: ← を数字の下（重ならない）に青色で表示（センター）
        return Padding(
          padding: pad,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$score', style: style),
                const Text(
                  '←',
                  style: TextStyle(fontSize: 5.5, color: Color(0xFF1E88E5), height: 0.85),
                ),
              ],
            ),
          ),
        );
      case 4: // 飛ばし成功: ↑ を数字の右（重ならない）に青色で表示（センター）
        return Padding(
          padding: pad,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$score', style: style),
                const Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Text(
                    '↑',
                    style: TextStyle(fontSize: 5.5, color: Color(0xFF1E88E5)),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return _cell('$score');
    }
  }
}

// ── ダウンロードボタン付きラッパー ────────────────────────────────
class DownloadableMatchResult extends StatefulWidget {
  const DownloadableMatchResult({
    super.key,
    required this.match,
    required this.sets,
    required this.isMatchDraw,
    required this.winnerName,
    required this.matchTypeName,
  });

  final MolkkyMatch match;
  final List<SetRecord> sets;
  final bool isMatchDraw;
  final String winnerName;
  final String matchTypeName;

  @override
  State<DownloadableMatchResult> createState() =>
      _DownloadableMatchResultState();
}

class _DownloadableMatchResultState extends State<DownloadableMatchResult> {
  final _key = GlobalKey();
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await downloadPng(
        Uint8List.view(data.buffer),
        'easy_molkky_result_$ts.png',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _key,
          child: MatchResultCard(
            match: widget.match,
            sets: widget.sets,
            isMatchDraw: widget.isMatchDraw,
            winnerName: widget.winnerName,
            matchTypeName: widget.matchTypeName,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloading ? null : _download,
            icon:
                _downloading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.download, size: 18),
            label: Text(_downloading ? '生成中...' : '結果を画像でダウンロード'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
