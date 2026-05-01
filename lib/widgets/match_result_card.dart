import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../utils/image_downloader.dart';

class MatchResultCard extends StatelessWidget {
  const MatchResultCard({
    super.key,
    required this.match,
    required this.isMatchDraw,
    required this.winnerName,
    required this.matchTypeName,
  });

  final MolkkyMatch match;
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          const Text(
            'Easy Molkky Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          Text(
            matchTypeName,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 16),
          // 勝者 / 引き分け
          Text(
            isMatchDraw ? '🤝 引き分け' : '🏆 $winnerName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // プレイヤー結果テーブル
          _ResultTable(players: sorted),
        ],
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.players});
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(28),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(56),
      },
      children: [
        // ヘッダー行
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE3F2FD)),
          children: [
            _cell('', header: true),
            _cell('名前', header: true),
            _cell('セット', header: true),
            _cell('合計', header: true),
          ],
        ),
        for (int i = 0; i < players.length; i++) ...[
          TableRow(
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFFFF9C4) : Colors.white,
            ),
            children: [
              _cell('${i + 1}'),
              _cell(players[i].name),
              _cell(_starsText(players[i].setsWon)),
              _cell('${players[i].totalMatchScore}'),
            ],
          ),
        ],
      ],
    );
  }

  String _starsText(int n) {
    if (n <= 0) return '0';
    final groups = n ~/ 5;
    final rem = n % 5;
    return ('⭐×5 ' * groups) + ('⭐' * rem);
  }

  Widget _cell(String text, {bool header = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: header ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}

/// ダウンロードボタン付きのラッパー
class DownloadableMatchResult extends StatefulWidget {
  const DownloadableMatchResult({
    super.key,
    required this.match,
    required this.isMatchDraw,
    required this.winnerName,
    required this.matchTypeName,
  });

  final MolkkyMatch match;
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
      final bytes = Uint8List.view(data.buffer);
      await downloadPng(bytes, 'easy_molkky_result.png');
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
