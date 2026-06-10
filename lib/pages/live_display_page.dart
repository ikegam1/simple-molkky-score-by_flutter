import 'package:flutter/material.dart';

import '../models/live_match.dart';
import '../services/live_match_service.dart';

/// OBS等の配信ソフトに埋め込むためのライブ表示ページ。
/// 背景は透明、文字は大きく、横長レイアウト想定。
class LiveDisplayPage extends StatefulWidget {
  const LiveDisplayPage({super.key, required this.liveId});

  final String liveId;

  @override
  State<LiveDisplayPage> createState() => _LiveDisplayPageState();
}

class _LiveDisplayPageState extends State<LiveDisplayPage> {
  late final LiveMatchService _service;

  @override
  void initState() {
    super.initState();
    _service = LiveMatchService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<LiveMatch?>(
        stream: _service.watchLiveMatch(widget.liveId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CenterMessage(text: '読み込み中...');
          }
          if (snapshot.hasError) {
            return _CenterMessage(text: 'エラー: ${snapshot.error}');
          }
          final live = snapshot.data;
          if (live == null) {
            return const _CenterMessage(text: 'ライブ表示は見つかりませんでした。');
          }
          return _LiveDisplayBody(live: live);
        },
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
        ),
      ),
    );
  }
}

class _LiveDisplayBody extends StatelessWidget {
  const _LiveDisplayBody({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(live: live),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < live.players.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _PlayerCard(
                        player: live.players[i],
                        isCurrent:
                            i == live.currentPlayerIndex && !live.isEnded,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_score, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            live.isEnded
                ? '試合終了'
                : 'Set ${live.currentSetIndex} / Turn ${live.currentTurnInSet}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            live.matchTypeLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.isCurrent});
  final LivePlayer player;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final accent = isCurrent ? Colors.amber : Colors.white;
    final bgAlpha = isCurrent ? 0.85 : 0.7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.amber : Colors.white24,
          width: isCurrent ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    decoration:
                        player.isDisqualified
                            ? TextDecoration.lineThrough
                            : null,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _SetBadge(setsWon: player.setsWon),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${player.currentScore}',
              style: TextStyle(
                color: accent,
                fontSize: 96,
                fontWeight: FontWeight.w900,
                height: 1.0,
                fontFeatures: const [],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _RecentThrows(throws: player.recentThrows),
        ],
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({required this.setsWon});
  final int setsWon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 14, color: Colors.amberAccent),
          const SizedBox(width: 4),
          Text(
            '$setsWon',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentThrows extends StatelessWidget {
  const _RecentThrows({required this.throws});
  final List<int> throws;

  @override
  Widget build(BuildContext context) {
    if (throws.isEmpty) {
      return const Text(
        '直近: -',
        style: TextStyle(color: Colors.white60, fontSize: 13),
      );
    }
    return Row(
      children: [
        const Text(
          '直近:',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < throws.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${throws[i]}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
