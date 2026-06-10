import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_models.dart';
import '../models/live_match.dart';

class LiveMatchService {
  LiveMatchService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'liveMatches';
  static const _idChars =
      'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _idLength = 8;
  static const _liveDurationHours = 24;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  String _generateId() {
    final rand = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < _idLength; i++) {
      sb.write(_idChars[rand.nextInt(_idChars.length)]);
    }
    return sb.toString();
  }

  /// 試合に対するライブ表示用IDを発行する。
  /// 既に発行済みの場合は同じIDを返す。
  Future<String> issueOrGetLiveId({
    required String matchId,
    required MolkkyMatch match,
    required int currentPlayerIndex,
    required int currentTurnInSet,
  }) async {
    final existing =
        await _col.where('matchId', isEqualTo: matchId).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    var liveId = _generateId();
    // 衝突回避（極稀だが念のため最大5回リトライ）
    for (var i = 0; i < 5; i++) {
      final doc = await _col.doc(liveId).get();
      if (!doc.exists) break;
      liveId = _generateId();
    }
    final live = _buildLiveMatch(
      liveId: liveId,
      matchId: matchId,
      match: match,
      currentPlayerIndex: currentPlayerIndex,
      currentTurnInSet: currentTurnInSet,
      isEnded: false,
      now: DateTime.now(),
    );
    await _col.doc(liveId).set(live.toMap());
    return liveId;
  }

  /// 既存のライブデータを更新する。
  Future<void> updateLiveMatch({
    required String liveId,
    required String matchId,
    required MolkkyMatch match,
    required int currentPlayerIndex,
    required int currentTurnInSet,
    required bool isEnded,
  }) async {
    final now = DateTime.now();
    final live = _buildLiveMatch(
      liveId: liveId,
      matchId: matchId,
      match: match,
      currentPlayerIndex: currentPlayerIndex,
      currentTurnInSet: currentTurnInSet,
      isEnded: isEnded,
      now: now,
    );
    final data = live.toMap();
    if (isEnded) {
      // 試合終了時に expiresAt をリセット（終了から24時間後）
      data['expiresAt'] = Timestamp.fromDate(
        now.add(const Duration(hours: _liveDurationHours)),
      );
    } else {
      // 試合中は createdAt を更新しない
      data.remove('createdAt');
      data.remove('expiresAt');
    }
    await _col.doc(liveId).set(data, SetOptions(merge: true));
  }

  Stream<LiveMatch?> watchLiveMatch(String liveId) {
    return _col.doc(liveId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return LiveMatch.fromMap(data);
    });
  }

  Future<LiveMatch?> fetchLiveMatch(String liveId) async {
    final snap = await _col.doc(liveId).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return LiveMatch.fromMap(data);
  }

  static LiveMatch _buildLiveMatch({
    required String liveId,
    required String matchId,
    required MolkkyMatch match,
    required int currentPlayerIndex,
    required int currentTurnInSet,
    required bool isEnded,
    required DateTime now,
  }) {
    return LiveMatch(
      liveId: liveId,
      matchId: matchId,
      players: match.players.map(LivePlayer.fromPlayer).toList(),
      currentPlayerIndex: currentPlayerIndex,
      currentTurnInSet: currentTurnInSet,
      currentSetIndex: match.currentSetIndex,
      matchTypeIndex: MatchType.values.indexOf(match.type),
      isEnded: isEnded,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: _liveDurationHours)),
    );
  }
}
