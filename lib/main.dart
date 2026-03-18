
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/game_models.dart';
import 'logic/game_logic.dart';

// --- Localization Support ---
class L10n {
  final Locale locale;
  L10n(this.locale);

  static L10n of(BuildContext context) {
    try {
      return Localizations.of<L10n>(context, L10n) ?? L10n(const Locale('ja'));
    } catch (_) {
      return L10n(const Locale('ja'));
    }
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app_title': 'Easy Molkky Score',
      'player_name': 'Player Name',
      'start_game': 'Start Game',
      'match_history': 'History',
      'game_mode': 'Game Mode',
      'sets_count': 'Sets: {n}',
      'race_to': 'First to {n} sets',
      'set_n': 'Set {n}',
      'turn_n': 'Turn {n}',
      'turn_label': 'T',
      'points': 'Pts',
      'total': 'Total',
      'confirm': 'Confirm',
      'undo': 'Undo',
      'miss': 'Miss',
      'history_title': 'Match History',
      'winner_is': '{name} Wins!',
      'next_set': 'Next Set',
      'final_result': 'Final Result',
      'match_over': 'Match Over',
      'winner_crown': 'Winner: {name}',
      'finish': 'Finish',
      'anonymous_id': 'Firebase ID: {id}',
      'loading_history': 'Loading history...',
      'no_history': 'No match history yet.',
      'error': 'Error: {msg}',
      'max_players_reached': 'Max 8 players allowed',
      'duplicate_name': 'Name already exists',
      'name_too_long': 'Max 20 characters',
      'reorder_hint': 'Adjust throw order for next set',
      'switch_lang': 'Language: English',
      'reach_msg': '{name}, {n} to win! 🎯',
    },
    'ja': {
      'app_title': 'Easy Molkky Score',
      'player_name': 'プレイヤー名',
      'start_game': 'ゲーム開始',
      'match_history': '戦績確認',
      'game_mode': '試合形式',
      'sets_count': '{n}番 ({n}セット)',
      'race_to': '{n}先 ({n}本先取)',
      'set_n': '第 {n} セット',
      'turn_n': 'ターン {n}',
      'turn_label': 'ターン',
      'points': '得点',
      'total': '合計',
      'confirm': '決定',
      'undo': '戻る',
      'miss': 'ミス',
      'history_title': '全セット履歴',
      'winner_is': '{name} さんが勝利！',
      'next_set': '次のセットへ',
      'final_result': '最終結果へ',
      'match_over': '🎊 マッチ終了 🎊',
      'winner_crown': '優勝: {name} さん',
      'finish': '終了',
      'anonymous_id': 'Firebase ID: {id}',
      'loading_history': '戦績データを準備中です...',
      'no_history': 'まだ戦績がありません',
      'error': 'エラー: {msg}',
      'max_players_reached': '最大8人まで登録可能です',
      'duplicate_name': 'その名前は既に登録されています',
      'name_too_long': '名前は20文字以内で入力してください',
      'reorder_hint': '次セットの投げ順を調整できます',
      'switch_lang': '言語: 日本語',
      'reach_msg': '{name} さん、{n}でアガリです🎯',
    }
  };

  String get(String key, {Map<String, String>? args}) {
    String lang = locale.languageCode.startsWith('ja') ? 'ja' : 'en';
    String value = _values[lang]?[key] ?? _values['en']![key] ?? key;
    if (args != null) {
      args.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }
}

class L10nDelegate extends LocalizationsDelegate<L10n> {
  const L10nDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<L10n> load(Locale locale) async => L10n(locale);
  @override
  bool shouldReload(L10nDelegate old) => false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); } catch (e) { debugPrint("Firebase init error: $e"); }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent));
  runApp(const EasyMolkkyApp());
}

class EasyMolkkyApp extends StatefulWidget {
  const EasyMolkkyApp({super.key});
  
  static _EasyMolkkyAppState of(BuildContext context) => context.findAncestorStateOfType<_EasyMolkkyAppState>()!;

  @override
  State<EasyMolkkyApp> createState() => _EasyMolkkyAppState();
}

class _EasyMolkkyAppState extends State<EasyMolkkyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('user_lang');
    if (langCode != null) {
      setState(() { _locale = Locale(langCode); });
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_lang', locale.languageCode);
    setState(() { _locale = locale; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Molkky Score',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      locale: _locale,
      localizationsDelegates: const [L10nDelegate(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('ja'), Locale('en')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale;
        if (locale != null && locale.languageCode.startsWith('ja')) return const Locale('ja');
        return const Locale('en');
      },
      home: const SetupScreen(),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<Player> _registeredPlayers = [];
  final TextEditingController _nameController = TextEditingController();
  int _selectedModeKey = 3;
  String _firebaseUid = "";
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      setState(() { _firebaseUid = userCredential.user!.uid; });
    } catch (e) { debugPrint("Auth Error: $e"); }
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedJsonList = prefs.getStringList('saved_players_v2');
    if (savedJsonList != null) {
      final List<Player> loadedPlayers = savedJsonList.map((jsonStr) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return Player(id: data['id'], name: data['name'], initialOrder: 0);
      }).toList();
      setState(() { _registeredPlayers.addAll(loadedPlayers); });
    }
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _registeredPlayers.map((p) => jsonEncode({'id': p.id, 'name': p.name})).toList();
    await prefs.setStringList('saved_players_v2', jsonList);
  }

  void _add() {
    final t = L10n.of(context);
    String name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_registeredPlayers.length >= 8) { _showError(t.get('max_players_reached')); return; }
    if (name.length > 20) { _showError(t.get('name_too_long')); return; }
    if (_registeredPlayers.any((p) => p.name.toLowerCase() == name.toLowerCase())) { _showError(t.get('duplicate_name')); return; }

    setState(() { 
      _registeredPlayers.add(Player(id: _uuid.v4(), name: name, initialOrder: _registeredPlayers.length)); 
      _nameController.clear(); 
    });
    _savePlayers();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final Map<int, String> options = {
      1: t.get('sets_count', args: {'n': '1'}),
      2: t.get('sets_count', args: {'n': '2'}),
      3: t.get('race_to', args: {'n': '2'}),
      5: t.get('race_to', args: {'n': '3'}),
      10: t.get('sets_count', args: {'n': '10'}),
      11: t.get('race_to', args: {'n': '11'})
    };

    return Scaffold(
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.transparent,
        leading: TextButton(
          onPressed: () {
            final current = Localizations.localeOf(context).languageCode;
            EasyMolkkyApp.of(context).setLocale(current == 'ja' ? const Locale('en') : const Locale('ja'));
          },
          child: Text(Localizations.localeOf(context).languageCode == 'ja' ? 'EN' : 'JA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        actions: [IconButton(icon: const Icon(Icons.history), onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))), tooltip: t.get('match_history'))],
      ),
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(t.get('app_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: t.get('player_name'), suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add(), maxLength: 20, buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null),
            Expanded(child: ReorderableListView(
              onReorder: (o, n) { setState(() { if (o < n) n -= 1; _registeredPlayers.insert(n, _registeredPlayers.removeAt(o)); }); _savePlayers(); }, 
              children: [ for (int i = 0; i < _registeredPlayers.length; i++) ListTile(key: Key(_registeredPlayers[i].id), leading: const Icon(Icons.drag_handle), title: Text('${i + 1}. ${_registeredPlayers[i].name}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() => _registeredPlayers.removeAt(i)); _savePlayers(); })) ]
            )),
            DropdownButtonFormField<int>(value: _selectedModeKey, items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => _selectedModeKey = v!), decoration: InputDecoration(labelText: t.get('game_mode'))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registeredPlayers.isEmpty ? null : () {
                final playersForMatch = _registeredPlayers.asMap().entries.map((e) => Player(id: e.value.id, name: e.value.name, initialOrder: e.key)).toList();
                MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                int limit = _selectedModeKey; if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(appUserId: _firebaseUid, match: MolkkyMatch(players: playersForMatch, limit: limit, type: type))));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: Text(t.get('start_game'), style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))), icon: const Icon(Icons.cloud_done), label: Text(t.get('match_history')), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45))),
            const SizedBox(height: 10),
            if (_firebaseUid.isNotEmpty) Text(t.get('anonymous_id', args: {'id': _firebaseUid.substring(0, 8)}), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('v1.6.2', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final MolkkyMatch match;
  final String appUserId;
  const GameScreen({super.key, required this.match, required this.appUserId});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentPlayerIndex = 0;
  List<int> selectedSkitels = [];
  int currentTurnInSet = 1;
  bool isSetFinished = false;
  Map<String, int> turnInProgressScores = {};
  Set<String> systemCalculatedIds = {};

  void _onSkitelTap(int num) { if (isSetFinished) return; setState(() { if (selectedSkitels.contains(num)) selectedSkitels.remove(num); else selectedSkitels.add(num); }); }

  void _submitThrow() {
    if (isSetFinished) return;
    final player = widget.match.players[currentPlayerIndex];
    setState(() {
      GameLogic.processThrow(player, selectedSkitels, widget.match);
      int lastPoints = player.scoreHistory.last;
      player.matchScoreHistory.add(lastPoints);
      turnInProgressScores[player.id] = lastPoints;
      final survivors = widget.match.players.where((p) => !p.isDisqualified).toList();
      
      if (widget.match.players.length >= 2 && survivors.length == 1) {
        final s = survivors.first;
        int needed = widget.match.targetScore - s.currentScore;
        s.currentScore = widget.match.targetScore;
        s.matchScoreHistory.add(needed);
        turnInProgressScores[s.id] = needed;
        systemCalculatedIds.add(s.id); 
        for (var p in widget.match.players) if (p.isDisqualified) p.currentScore = 0;
      }

      Player? winner;
      for (var p in widget.match.players) if (p.currentScore == widget.match.targetScore) { winner = p; break; }
      
      if (winner != null) {
        isSetFinished = true; winner.setsWon++;
        widget.match.currentSetRecord.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
        
        // 重要：マッチ終了判定を正確に行うために一時的にcompletedSetsに含めてチェック
        final tempCompleted = List<SetRecord>.from(widget.match.completedSets)..add(widget.match.currentSetRecord);
        bool matchTrulyOver = false;
        if (widget.match.type == MatchType.fixedSets) {
          matchTrulyOver = tempCompleted.length >= widget.match.limit;
        } else {
          matchTrulyOver = widget.match.isMatchOver;
        }

        if (matchTrulyOver) {
           widget.match.finalizeCurrentSetIfNeeded();
           final finalWinner = widget.match.matchWinner ?? winner;
           _uploadMatchData(finalWinner);
           _showMatchWinnerDialog(finalWinner);
        } else {
           _showSetWinnerDialog(winner);
        }
      } else {
        if (currentPlayerIndex == widget.match.players.length - 1) {
          widget.match.currentSetRecord.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
          turnInProgressScores.clear(); systemCalculatedIds.clear();
        }
        selectedSkitels.clear(); _nextPlayer();
      }
    });
  }

  void _nextPlayer() {
    int start = currentPlayerIndex;
    do { currentPlayerIndex = (currentPlayerIndex + 1) % widget.match.players.length; } while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex != start);
    if (currentPlayerIndex == 0) currentTurnInSet++;
  }

  void _undo() {
    if (isSetFinished || (currentTurnInSet == 1 && currentPlayerIndex == 0)) return;
    setState(() {
      if (currentPlayerIndex == 0) { currentTurnInSet--; currentPlayerIndex = widget.match.players.length - 1; } else { currentPlayerIndex--; }
      while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex > 0) { currentPlayerIndex--; }
      final p = widget.match.players[currentPlayerIndex];
      if (p.scoreHistory.isNotEmpty) {
        int last = p.scoreHistory.removeLast(); p.matchScoreHistory.removeLast(); p.currentScore -= last;
        turnInProgressScores.remove(p.id); systemCalculatedIds.remove(p.id);
        if (last == 0 && p.consecutiveMisses > 0) { p.consecutiveMisses--; p.isDisqualified = false; }
      }
      selectedSkitels.clear();
    });
  }

  Future<void> _uploadMatchData(Player finalWinner) async {
    try {
      final match = widget.match;
      List<SetRecord> setsToUpload = List.from(match.completedSets);
      if (!setsToUpload.any((s) => s.setNumber == match.currentSetRecord.setNumber)) {
         for (var p in match.players) match.currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
         setsToUpload.add(match.currentSetRecord);
      }

      final data = {
        'appUserId': widget.appUserId,
        'startTime': match.startTime,
        'endTime': FieldValue.serverTimestamp(),
        'matchType': match.type.toString(),
        'limit': match.limit,
        'winner': finalWinner.name,
        'players': match.players.map((p) => {'id': p.id, 'name': p.name, 'setsWon': p.setsWon, 'totalScore': p.totalMatchScore}).toList(),
        'history': setsToUpload.map((s) => {
          'setNumber': s.setNumber, 'starterId': s.starterPlayerId, 'playerOrder': s.playerOrder, 'finalScores': s.finalCumulativeScores,
          'turns': s.turns.map((t) => {'turnNumber': t.turnNumber, 'scores': t.scores, 'systemCalculated': t.systemCalculatedPlayerIds.toList()}).toList(),
        }).toList(),
      };
      await FirebaseFirestore.instance.collection('scores').add(data);
    } catch (e) { debugPrint("Upload Error: $e"); }
  }

  void _goToHistory() {
    List<SetRecord> allSets = List.from(widget.match.completedSets);
    if (!isSetFinished) {
      SetRecord ongoing = SetRecord(widget.match.currentSetRecord.setNumber, widget.match.currentSetRecord.starterPlayerId, widget.match.players.map((p)=>p.id).toList());
      ongoing.turns.addAll(widget.match.currentSetRecord.turns);
      if (turnInProgressScores.isNotEmpty) ongoing.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
      allSets.add(ongoing);
    } else {
      if (!allSets.any((s) => s.setNumber == widget.match.currentSetRecord.setNumber)) {
        allSets.add(widget.match.currentSetRecord);
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(match: widget.match, sets: allSets)));
  }

  void _showSetWinnerDialog(Player winner) {
    final t = L10n.of(context);
    final int finishedSetNum = widget.match.currentSetIndex; // 現在のセット番号を保持
    widget.match.prepareNextSet(manualOrder: false);
    List<Player> reorderList = List.from(widget.match.players); 

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
      return AlertDialog(
        title: Text(t.get('set_n', args: {'n': '$finishedSetNum'})), // 修正：終わったセットの番号を表示
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.get('winner_is', args: {'name': winner.name})),
            const SizedBox(height: 16),
            const Divider(),
            Text(t.get('reorder_hint'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              height: 200,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (o, n) { setDialogState(() { if (o < n) n -= 1; reorderList.insert(n, reorderList.removeAt(o)); }); },
                children: [ for (var p in reorderList) ListTile(key: Key(p.id), dense: true, leading: const Icon(Icons.drag_handle, size: 20), title: Text(p.name)) ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: _goToHistory, child: Text(t.get('match_history'))),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            setState(() {
              widget.match.applyManualOrder(reorderList);
              currentPlayerIndex = 0; currentTurnInSet = 1; isSetFinished = false; turnInProgressScores.clear(); systemCalculatedIds.clear(); selectedSkitels.clear();
            });
          }, child: Text(t.get('next_set'))),
        ],
      );
    }));
  }

  void _showMatchWinnerDialog(Player winner) {
    final t = L10n.of(context);
    final int finishedSetNum = widget.match.currentSetIndex;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text('${t.get('set_n', args: {'n': '$finishedSetNum'})} - ${t.get('match_over')}'),
      content: Text(t.get('winner_crown', args: {'name': winner.name})),
      actions: [TextButton(onPressed: _goToHistory, child: Text(t.get('match_history'))), TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: Text(t.get('finish')))]));
  }

  TextStyle _setCountStyle(Player player) {
    final maxSets = widget.match.players.fold<int>(0, (m, p) => p.setsWon > m ? p.setsWon : m);
    final isLeader = player.setsWon == maxSets && maxSets > 0;
    return TextStyle(
      fontSize: 16,
      fontWeight: isLeader ? FontWeight.w800 : FontWeight.w500,
      color: isLeader ? Colors.indigo : Colors.black87,
    );
  }

  int _runningTotal(Player p) {
    final finalizedIncludesCurrent =
        widget.match.completedSets.any((s) => s.setNumber == widget.match.currentSetRecord.setNumber);
    final finalizedTotal = p.setFinalScores.fold(0, (a, b) => a + b);
    return finalizedIncludesCurrent ? finalizedTotal : finalizedTotal + p.currentScore;
  }

  String _stars(int setsWon) => setsWon <= 0 ? '' : '⭐' * setsWon;

  Widget _buildScoreSummaryRow() {
    final players = widget.match.players;
    if (players.length == 2) {
      final a = players[0];
      final b = players[1];
      return Text(
        '${a.currentScore}(${_runningTotal(a)})${_stars(a.setsWon)} - ${b.currentScore}(${_runningTotal(b)})${_stars(b.setsWon)}',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      );
    }

    final text = players
        .map((p) => '${p.name} ${p.currentScore}(${_runningTotal(p)})${_stars(p.setsWon)}')
        .join('  -  ');
    return Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    if (widget.match.players.isEmpty) return Scaffold(body: Center(child: Text(t.get('error', args: {'msg': 'No players'}))));
    final currentPlayer = widget.match.players[currentPlayerIndex];
    
    // ミスを☠で表現する文字列作成
    String missIcons = '';
    if (currentPlayer.consecutiveMisses == 1) missIcons = ' ☠';
    if (currentPlayer.consecutiveMisses == 2) missIcons = ' ☠☠';
    Color nameColor = currentPlayer.consecutiveMisses >= 2 ? Colors.red : Colors.black;

    // アガリガイドメッセージ
    String? reachMsg;
    if (currentPlayer.currentScore >= 38 && !isSetFinished) {
      reachMsg = t.get('reach_msg', args: {'name': currentPlayer.name, 'n': '${50 - currentPlayer.currentScore}'});
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.get('set_n', args: {'n': '${widget.match.currentSetIndex}'})), actions: [TextButton.icon(onPressed: _goToHistory, icon: const Icon(Icons.list_alt, size: 18), label: Text(t.get('match_history')))]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildScoreSummaryRow(),
                const SizedBox(height: 6),
                RichText(text: TextSpan(style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: nameColor), children: [
                  TextSpan(text: '${currentPlayer.name} '),
                  TextSpan(text: '(${t.get('turn_n', args: {'n': '$currentTurnInSet'})})'),
                  TextSpan(text: missIcons, style: const TextStyle(color: Colors.red)),
                ])),
                if (reachMsg != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(reachMsg, style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            )),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
            child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                columns: [DataColumn(label: SizedBox(width: 40, child: Text(t.get('turn_label')))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text(t.get('points'), style: const TextStyle(fontSize: 9)), Text(t.get('total'), style: const TextStyle(fontSize: 9))])])))])],
                rows: List.generate(currentTurnInSet, (i) {
                  int turn = currentTurnInSet - i;
                  return DataRow(cells: [DataCell(Center(child: Text('$turn'))), ...widget.match.players.expand((p) {
                    int score = 0, total = 0;
                    bool hasScore = p.scoreHistory.length >= turn;
                    if (hasScore) { score = p.scoreHistory[turn - 1]; int tmp = 0; for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > 50) tmp = 25; } total = tmp; }
                    return [DataCell(Row(children: [
                      Container(width: 40, alignment: Alignment.center, child: Text(hasScore ? '$score' : '', style: const TextStyle(fontSize: 15))), // 修正：空白化 & 1ptアップ
                      Container(width: 40, alignment: Alignment.center, color: const Color(0xFFE3F2FD), child: Text(hasScore ? '$total' : '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))]))]; // 修正：1ptアップ
                  })]);
                }),
              ),
            ))),
          ),
          Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 32), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(children: [
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0), itemCount: 12, itemBuilder: (c, i) {
                final num = i + 1; final isSelected = selectedSkitels.contains(num);
                return GestureDetector(
                  onDoubleTap: () {
                    if (isSetFinished) return;
                    setState(() => selectedSkitels = [num]);
                    _submitThrow();
                  },
                  child: ElevatedButton(onPressed: () => _onSkitelTap(num), style: ElevatedButton.styleFrom(backgroundColor: isSelected ? const Color(0xFFFFF3E0) : Colors.white, foregroundColor: Colors.black, side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                );
              }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _undo, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: Colors.red), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.undo, size: 18), Text(' ${t.get('undo')}')]))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: _submitThrow, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline), Text(selectedSkitels.isEmpty ? ' 0 ${t.get('pts')} (${t.get('miss')})' : ' ${t.get('confirm')} (${selectedSkitels.length == 1 ? selectedSkitels.first : selectedSkitels.length} ${t.get('pts')})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))),
              ]),
              const SizedBox(height: 12),
              Text(t.get('app_title'), style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w300)),
              const SizedBox(height: 12),
            ]),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final MolkkyMatch? match;
  final List<SetRecord> sets;
  final DateTime? startTime;
  final List<Player>? players;
  const HistoryPage({super.key, this.match, required this.sets, this.startTime, this.players});

  Map<String, int> _finalSetWins(List<Player> allPlayers) {
    final wins = <String, int>{for (var p in allPlayers) p.id: 0};

    for (final set in sets) {
      String? winnerId;
      int best = -1;
      for (final p in allPlayers) {
        final score = set.finalCumulativeScores[p.id] ?? 0;
        if (score > best) {
          best = score;
          winnerId = p.id;
        }
      }
      if (winnerId != null) wins[winnerId] = (wins[winnerId] ?? 0) + 1;
    }
    return wins;
  }

  Map<String, int> _finalTotals(List<Player> allPlayers) {
    final totals = <String, int>{for (var p in allPlayers) p.id: 0};

    for (final set in sets) {
      for (final p in allPlayers) {
        totals[p.id] = (totals[p.id] ?? 0) + (set.finalCumulativeScores[p.id] ?? 0);
      }
    }
    return totals;
  }

  Widget _buildHistorySetCount(List<Player> allPlayers, Map<String, int> wins) {
    int maxWins = 0;
    for (final p in allPlayers) {
      maxWins = (wins[p.id] ?? 0) > maxWins ? (wins[p.id] ?? 0) : maxWins;
    }

    if (allPlayers.length == 2) {
      final a = allPlayers[0];
      final b = allPlayers[1];
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '${wins[a.id] ?? 0}', style: TextStyle(fontSize: 16, fontWeight: (wins[a.id] ?? 0) == maxWins && maxWins > 0 ? FontWeight.w800 : FontWeight.w500, color: Colors.indigo)),
            const TextSpan(text: ' - ', style: TextStyle(fontSize: 16, color: Colors.black87)),
            TextSpan(text: '${wins[b.id] ?? 0}', style: TextStyle(fontSize: 16, fontWeight: (wins[b.id] ?? 0) == maxWins && maxWins > 0 ? FontWeight.w800 : FontWeight.w500, color: Colors.indigo)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      children: allPlayers
          .map((p) => Text('${p.name}:${wins[p.id] ?? 0}', style: TextStyle(fontSize: 14, fontWeight: (wins[p.id] ?? 0) == maxWins && maxWins > 0 ? FontWeight.w800 : FontWeight.w500)))
          .toList(),
    );
  }

  Widget _buildHistoryTotalScore(List<Player> allPlayers, Map<String, int> totals, Map<String, int> wins) {
    if (allPlayers.length == 2) {
      final a = allPlayers[0];
      final b = allPlayers[1];
      final aStars = (wins[a.id] ?? 0) > 0 ? '⭐' * (wins[a.id] ?? 0) : '';
      final bStars = (wins[b.id] ?? 0) > 0 ? '⭐' * (wins[b.id] ?? 0) : '';
      return Text(
        '${totals[a.id] ?? 0}$aStars - ${totals[b.id] ?? 0}$bStars',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      );
    }

    return Text(
      allPlayers.map((p) => '${p.name} ${totals[p.id] ?? 0}${(wins[p.id] ?? 0) > 0 ? ('⭐' * (wins[p.id] ?? 0)) : ''}').join('  -  '),
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final allPlayers = players ?? match?.players ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(t.get('history_title'))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${t.get('app_title')} Result', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        Text('Started: ${dateFormat.format(match?.startTime ?? startTime ?? DateTime.now())}', style: const TextStyle(color: Colors.grey)),
        const Divider(height: 30),
        Builder(builder: (context) {
          final wins = _finalSetWins(allPlayers);
          final totals = _finalTotals(allPlayers);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFE3F2FD),
            child: _buildHistoryTotalScore(allPlayers, totals, wins),
          );
        }),
        const SizedBox(height: 12),
        for (var set in sets) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFE3F2FD),
            child: Text(t.get('set_n', args: {'n': '${set.setNumber}'}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          _buildSetTable(context, set, allPlayers),
          const SizedBox(height: 20),
        ],
      ])),
    );
  }

  Widget _buildSetTable(BuildContext context, SetRecord set, List<Player> allPlayers) {
    final t = L10n.of(context);
    List<Player> displayOrder = [];
    for (var id in set.playerOrder) {
      final p = allPlayers.firstWhere((player) => player.id == id, orElse: () => Player(id: id, name: "???", initialOrder: 0));
      displayOrder.add(p);
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 20, headingRowHeight: 40,
      columns: [DataColumn(label: Text(t.get('turn_label'))), ...displayOrder.map((p) => DataColumn(label: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))))],
      rows: [
        ...set.turns.map((turn) => DataRow(cells: [DataCell(Text('${turn.turnNumber}')), ...displayOrder.map((p) {
          bool isStarter = p.id == set.starterPlayerId;
          bool isSys = turn.systemCalculatedPlayerIds.contains(p.id);
          String txt = turn.scores.containsKey(p.id) ? (isSys ? "-" : "${turn.scores[p.id]}") : ""; // 修正：空白化
          return DataCell(Text(txt, style: TextStyle(fontWeight: isStarter ? FontWeight.bold : FontWeight.normal, fontSize: 16)));
        })])),
        DataRow(color: WidgetStateProperty.all(const Color(0xFFFFF8E1)), cells: [DataCell(Text(t.get('total'), style: const TextStyle(fontWeight: FontWeight.bold))), ...displayOrder.map((p) => DataCell(Text('${set.finalCumulativeScores[p.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))))]),
      ],
    ));
  }
}

class GlobalHistoryPage extends StatelessWidget {
  final String uid;
  const GlobalHistoryPage({super.key, required this.uid});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.get('match_history'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scores').where('appUserId', isEqualTo: uid).orderBy('startTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains("FAILED_PRECONDITION") || error.contains("index")) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(t.get('loading_history'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
            return Center(child: Text(t.get('error', args: {'msg': error})));
          }
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text(t.get('no_history')));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final start = (data['startTime'] as Timestamp).toDate();
            final winner = data['winner'] ?? "???";
            final playerNames = (data['players'] as List).map((p) => p['name']).join(", ");
            return ListTile(leading: const Icon(Icons.cloud_done, color: Colors.blue), title: Text("${DateFormat('MM/dd HH:mm').format(start)} Win: $winner"), subtitle: Text("Players: $playerNames"), onTap: () => _viewDetail(context, data, start));
          });
        },
      ),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> data, DateTime start) {
    final t = L10n.of(context);
    try {
      final List<Player> players = (data['players'] as List).map((p) => Player(id: p['id'], name: p['name'], initialOrder: 0)).toList();
      final List<SetRecord> sets = (data['history'] as List).map((s) {
        final set = SetRecord(s['setNumber'], s['starterId'], List<String>.from(s['playerOrder'] ?? []));
        (s['turns'] as List).forEach((t) => set.turns.add(TurnRecord(t['turnNumber'], Map<String, int>.from(t['scores']), systemCalculated: Set<String>.from(t['systemCalculated'] ?? []))));
        s['finalScores'].forEach((k, v) => set.finalCumulativeScores[k] = v);
        return set;
      }).toList();
      Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(sets: sets, startTime: start, players: players)));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('error', args: {'msg': '$e'})))); }
  }
}
