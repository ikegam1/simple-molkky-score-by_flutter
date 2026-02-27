
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
    return Localizations.of<L10n>(context, L10n) ?? L10n(const Locale('ja'));
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
    }
  };

  String get(String key, {Map<String, String>? args}) {
    // 言語コードが ja または ja_JP 等であれば ja を使用、それ以外は en
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
  bool isSupported(Locale locale) => true; // すべての言語を受け入れ、内部で en/ja に振り分ける
  @override
  Future<L10n> load(Locale locale) async => L10n(locale);
  @override
  bool shouldReload(L10nDelegate old) => false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const EasyMolkkyApp());
}

class EasyMolkkyApp extends StatelessWidget {
  const EasyMolkkyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Molkky Score',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      localizationsDelegates: const [
        L10nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US'), Locale('ja'), Locale('en')],
      // 言語判定のカスタマイズ
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('ja');
        if (locale.languageCode.startsWith('ja')) return const Locale('ja');
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
    } catch (e) {
      debugPrint("Auth Error: $e");
    }
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
    if (_nameController.text.isNotEmpty) {
      setState(() { _registeredPlayers.add(Player(id: _uuid.v4(), name: _nameController.text, initialOrder: _registeredPlayers.length)); _nameController.clear(); });
      _savePlayers();
    }
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
        title: const Text(''), 
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))),
            tooltip: t.get('match_history'),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(t.get('app_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: t.get('player_name'), suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add()),
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
            OutlinedButton.icon(
              onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))),
              icon: const Icon(Icons.cloud_done),
              label: Text(t.get('match_history')),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
            ),
            const SizedBox(height: 10),
            if (_firebaseUid.isNotEmpty)
              Text(t.get('anonymous_id', args: {'id': _firebaseUid.substring(0, 8)}), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('v1.0.3', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      if (survivors.length == 1) {
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
        _showSetWinnerDialog(winner);
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

  Future<void> _uploadMatchData() async {
    try {
      final match = widget.match;
      for (var p in match.players) match.currentSetRecord.finalCumulativeScores[p.id] = p.currentScore;
      final setsToUpload = List<SetRecord>.from(match.completedSets)..add(match.currentSetRecord);
      final data = {
        'appUserId': widget.appUserId,
        'startTime': match.startTime,
        'endTime': FieldValue.serverTimestamp(),
        'matchType': match.type.toString(),
        'limit': match.limit,
        'winner': match.matchWinner?.name ?? "None",
        'players': match.players.map((p) => {'id': p.id, 'name': p.name, 'setsWon': p.setsWon, 'totalScore': p.totalMatchScore}).toList(),
        'history': setsToUpload.map((s) => {
          'setNumber': s.setNumber,
          'starterId': s.starterPlayerId,
          'playerOrder': s.playerOrder,
          'finalScores': s.finalCumulativeScores,
          'turns': s.turns.map((t) => {
            'turnNumber': t.turnNumber,
            'scores': t.scores,
            'systemCalculated': t.systemCalculatedPlayerIds.toList(),
          }).toList(),
        }).toList(),
      };
      await FirebaseFirestore.instance.collection('scores').add(data);
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  void _goToHistory() {
    List<SetRecord> allSets = List.from(widget.match.completedSets);
    if (!isSetFinished) {
      SetRecord ongoing = SetRecord(widget.match.currentSetRecord.setNumber, widget.match.currentSetRecord.starterPlayerId, widget.match.players.map((p)=>p.id).toList());
      ongoing.turns.addAll(widget.match.currentSetRecord.turns);
      if (turnInProgressScores.isNotEmpty) ongoing.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
      allSets.add(ongoing);
    } else allSets.add(widget.match.currentSetRecord);
    Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(match: widget.match, sets: allSets)));
  }

  void _showSetWinnerDialog(Player winner) {
    // Dialogを表示する際、builder内の context ではなく親の context または L10n.of(context) を事前に取得
    final t = L10n.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text(t.get('set_n', args: {'n': '${widget.match.currentSetIndex}'})), 
      content: Text(t.get('winner_is', args: {'name': winner.name})),
      actions: [
        TextButton(onPressed: _goToHistory, child: Text(t.get('match_history'))),
        TextButton(onPressed: () {
          Navigator.pop(ctx); if (widget.match.isMatchOver) { _uploadMatchData(); _showMatchWinnerDialog(winner); }
          else setState(() { widget.match.prepareNextSet(); currentPlayerIndex = 0; currentTurnInSet = 1; isSetFinished = false; turnInProgressScores.clear(); systemCalculatedIds.clear(); selectedSkitels.clear(); });
        }, child: Text(widget.match.isMatchOver ? t.get('final_result') : t.get('next_set')))]));
  }

  void _showMatchWinnerDialog(Player winner) {
    final t = L10n.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text(t.get('match_over')), 
      content: Text(t.get('winner_crown', args: {'name': winner.name})),
      actions: [
        TextButton(onPressed: _goToHistory, child: Text(t.get('match_history'))),
        TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: Text(t.get('finish')))
      ]));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final currentPlayer = widget.match.players[currentPlayerIndex];
    return Scaffold(
      appBar: AppBar(title: Text(t.get('set_n', args: {'n': '${widget.match.currentSetIndex}'})), actions: [TextButton.icon(onPressed: _goToHistory, icon: const Icon(Icons.list_alt, size: 18), label: Text(t.get('match_history')))]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Text('${currentPlayer.name} (${t.get('turn_n', args: {'n': '$currentTurnInSet'})})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
            child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                columns: [DataColumn(label: SizedBox(width: 40, child: Text(t.get('turn_label')))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text(t.get('points'), style: const TextStyle(fontSize: 9)), Text(t.get('total'), style: const TextStyle(fontSize: 9))])])))])],
                rows: List.generate(currentTurnInSet, (i) {
                  int turn = currentTurnInSet - i;
                  return DataRow(cells: [DataCell(Center(child: Text('$turn'))), ...widget.match.players.expand((p) {
                    int score = 0, total = 0;
                    if (p.scoreHistory.length >= turn) { score = p.scoreHistory[turn - 1]; int tmp = 0; for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > 50) tmp = 25; } total = tmp; }
                    return [DataCell(Row(children: [Container(width: 40, alignment: Alignment.center, child: Text(p.scoreHistory.length >= turn ? '$score' : '-')), Container(width: 40, alignment: Alignment.center, color: const Color(0xFFE3F2FD), child: Text(p.scoreHistory.length >= turn ? '$total' : '-', style: const TextStyle(fontWeight: FontWeight.bold)))]))];
                  })]);
                }),
              ),
            ))),
          ),
          Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 32), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(children: [
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0), itemCount: 12, itemBuilder: (c, i) {
                final num = i + 1; final isSelected = selectedSkitels.contains(num);
                return ElevatedButton(onPressed: () => _onSkitelTap(num), style: ElevatedButton.styleFrom(backgroundColor: isSelected ? const Color(0xFFFFF3E0) : Colors.white, foregroundColor: Colors.black, side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
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
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final allPlayers = players ?? match?.players ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(t.get('history_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.get('app_title')} Result', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Text('Started: ${dateFormat.format(match?.startTime ?? startTime ?? DateTime.now())}', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            for (var set in sets) ...[
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), color: const Color(0xFFE3F2FD), child: Text(t.get('set_n', args: {'n': '${set.setNumber}'}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              _buildSetTable(context, set, allPlayers),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetTable(BuildContext context, SetRecord set, List<Player> allPlayers) {
    final t = L10n.of(context);
    List<Player> displayOrder = [];
    for (var id in set.playerOrder) {
      final p = allPlayers.firstWhere((player) => player.id == id, orElse: () => Player(id: id, name: "???", initialOrder: 0));
      displayOrder.add(p);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 40,
        columns: [
          DataColumn(label: Text(t.get('turn_label'))),
          ...displayOrder.map((p) => DataColumn(label: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)))),
        ],
        rows: [
          ...set.turns.map((turn) => DataRow(cells: [
            DataCell(Text('${turn.turnNumber}')),
            ...displayOrder.map((p) {
              bool isStarter = p.id == set.starterPlayerId;
              bool isSys = turn.systemCalculatedPlayerIds.contains(p.id);
              String txt = turn.scores.containsKey(p.id) ? (isSys ? "-" : "${turn.scores[p.id]}") : "-";
              return DataCell(Text(txt, style: TextStyle(fontWeight: isStarter ? FontWeight.bold : FontWeight.normal, fontSize: 16)));
            }),
          ])),
          DataRow(
            color: WidgetStateProperty.all(const Color(0xFFFFF8E1)),
            cells: [
              DataCell(Text(t.get('total'), style: const TextStyle(fontWeight: FontWeight.bold))),
              ...displayOrder.map((p) => DataCell(Text('${set.finalCumulativeScores[p.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)))),
            ],
          ),
        ],
      ),
    );
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
        stream: FirebaseFirestore.instance
            .collection('scores')
            .where('appUserId', isEqualTo: uid)
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains("FAILED_PRECONDITION") || error.contains("index")) {
               return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(t.get('loading_history'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
            }
            return Center(child: Text(t.get('error', args: {'msg': error})));
          }
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text(t.get('no_history')));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final start = (data['startTime'] as Timestamp).toDate();
              final dateStr = DateFormat('MM/dd HH:mm').format(start);
              final winner = data['winner'] ?? "???";
              final playerNames = (data['players'] as List).map((p) => p['name']).join(", ");

              return ListTile(
                leading: const Icon(Icons.cloud_done, color: Colors.blue),
                title: Text("$dateStr Win: $winner"),
                subtitle: Text("Players: $playerNames"),
                onTap: () => _viewDetail(context, data, start),
              );
            },
          );
        },
      ),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> data, DateTime start) {
    final t = L10n.of(context);
    try {
      final List<dynamic> playersData = data['players'] as List<dynamic>;
      final List<Player> players = playersData.map((p) => Player(id: p['id'], name: p['name'], initialOrder: 0)).toList();

      final List<dynamic> historyData = data['history'] as List<dynamic>;
      final List<SetRecord> sets = historyData.map((s) {
        final List<String> order = List<String>.from(s['playerOrder'] ?? []);
        final set = SetRecord(s['setNumber'], s['starterId'], order);
        (s['turns'] as List).forEach((t) {
          set.turns.add(TurnRecord(
            t['turnNumber'], 
            Map<String, int>.from(t['scores']),
            systemCalculated: Set<String>.from(t['systemCalculated'] ?? []),
          ));
        });
        s['finalScores'].forEach((k, v) => set.finalCumulativeScores[k] = v);
        return set;
      }).toList();

      Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(sets: sets, startTime: start, players: players)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('error', args: {'msg': '$e'}))));
    }
  }
}
