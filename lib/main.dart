
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/game_models.dart';
import 'logic/game_logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SimpleMolkkyApp());
}

class SimpleMolkkyApp extends StatelessWidget {
  const SimpleMolkkyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Molkky Score',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  final Map<int, String> _options = { 1: '1番 (1セット)', 2: '2番 (2セット)', 3: '2先 (2本先取)', 5: '3先 (3本先取)', 10: '10番 (10セット)', 11: '11先 (11本先取)' };
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('セットアップ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))),
            tooltip: '戦績確認',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_firebaseUid.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('Firebase ID: ${_firebaseUid.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: Colors.grey))),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'プレイヤー名', suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add()),
            Expanded(child: ReorderableListView(
              onReorder: (o, n) { setState(() { if (o < n) n -= 1; _registeredPlayers.insert(n, _registeredPlayers.removeAt(o)); }); _savePlayers(); }, 
              children: [ for (int i = 0; i < _registeredPlayers.length; i++) ListTile(key: Key(_registeredPlayers[i].id), leading: const Icon(Icons.drag_handle), title: Text('${i + 1}. ${_registeredPlayers[i].name}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() => _registeredPlayers.removeAt(i)); _savePlayers(); })) ]
            )),
            DropdownButtonFormField<int>(value: _selectedModeKey, items: _options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => _selectedModeKey = v!), decoration: const InputDecoration(labelText: '試合形式')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registeredPlayers.isEmpty ? null : () {
                final playersForMatch = _registeredPlayers.asMap().entries.map((e) => Player(id: e.value.id, name: e.value.name, initialOrder: e.key)).toList();
                MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                int limit = _selectedModeKey; if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(appUserId: _firebaseUid, match: MolkkyMatch(players: playersForMatch, limit: limit, type: type))));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: const Text('ゲーム開始', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))),
              icon: const Icon(Icons.cloud_done),
              label: const Text('戦績確認'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
            ),
            const SizedBox(height: 10),
            const Text('v0.2.1', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      SetRecord ongoing = SetRecord(widget.match.currentSetRecord.setNumber, widget.match.currentSetRecord.starterPlayerId);
      ongoing.turns.addAll(widget.match.currentSetRecord.turns);
      if (turnInProgressScores.isNotEmpty) ongoing.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
      allSets.add(ongoing);
    } else allSets.add(widget.match.currentSetRecord);
    Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(match: widget.match, sets: allSets)));
  }

  void _showSetWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: Text('第 ${widget.match.currentSetIndex} セット終了'), content: Text('${winner.name} さんが勝利！'),
      actions: [
        TextButton(onPressed: _goToHistory, child: const Text('履歴を確認')),
        TextButton(onPressed: () {
          Navigator.pop(c); if (widget.match.isMatchOver) { _uploadMatchData(); _showMatchWinnerDialog(winner); }
          else setState(() { widget.match.prepareNextSet(); currentPlayerIndex = 0; currentTurnInSet = 1; isSetFinished = false; turnInProgressScores.clear(); systemCalculatedIds.clear(); selectedSkitels.clear(); });
        }, child: Text(widget.match.isMatchOver ? '最終結果へ' : '次のセットへ'))]));
  }

  void _showMatchWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: const Text('🎊 マッチ終了 🎊'), content: Text('優勝: ${winner.name} さん'),
      actions: [
        TextButton(onPressed: _goToHistory, child: const Text('履歴を確認')),
        TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('終了'))
      ]));
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.match.players[currentPlayerIndex];
    return Scaffold(
      appBar: AppBar(title: Text('第 ${widget.match.currentSetIndex} セット'), actions: [TextButton.icon(onPressed: _goToHistory, icon: const Icon(Icons.list_alt, size: 18), label: const Text('履歴'))]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Text('${currentPlayer.name} の番 (ターン $currentTurnInSet)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
            child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                columns: [const DataColumn(label: SizedBox(width: 40, child: Text('ターン'))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('得点', style: TextStyle(fontSize: 9)), Text('合計', style: TextStyle(fontSize: 9))])])))])],
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
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(children: [
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0), itemCount: 12, itemBuilder: (c, i) {
                final num = i + 1; final isSelected = selectedSkitels.contains(num);
                return ElevatedButton(onPressed: () => _onSkitelTap(num), style: ElevatedButton.styleFrom(backgroundColor: isSelected ? const Color(0xFFFFF3E0) : Colors.white, foregroundColor: Colors.black, side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
              }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _undo, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: Colors.red), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.undo, size: 18), Text(' 戻る')]))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: _submitThrow, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline), Text(selectedSkitels.isEmpty ? ' 0点 (ミス)' : ' 決定 (${selectedSkitels.length == 1 ? selectedSkitels.first : selectedSkitels.length}点)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final MolkkyMatch match;
  final List<SetRecord> sets;
  const HistoryPage({super.key, required this.match, required this.sets});
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final players = match.players;
    return Scaffold(
      appBar: AppBar(title: const Text('全セット履歴')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Molkky Match Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            Text('開始: ${dateFormat.format(match.startTime)}', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            for (var set in sets) ...[
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), color: const Color(0xFFE3F2FD), child: Text('第 ${set.setNumber} セット', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: DataTable(columnSpacing: 20, headingRowHeight: 40,
                  columns: [const DataColumn(label: Text('T')), ...players.map((p) => DataColumn(label: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))))],
                  rows: [
                    ...set.turns.map((turn) => DataRow(cells: [
                      DataCell(Text('${turn.turnNumber}')),
                      ...players.map((p) {
                        bool isStarter = p.id == set.starterPlayerId; bool isSys = turn.systemCalculatedPlayerIds.contains(p.id);
                        String txt = turn.scores.containsKey(p.id) ? (isSys ? "-" : "${turn.scores[p.id]}") : "-";
                        return DataCell(Text(txt, style: TextStyle(fontWeight: isStarter ? FontWeight.bold : FontWeight.normal, fontSize: 16)));
                      }),
                    ])),
                    DataRow(color: WidgetStateProperty.all(const Color(0xFFFFF8E1)),
                      cells: [
                        const DataCell(Text('計', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...players.map((p) {
                          int total = set.finalCumulativeScores[p.id] ?? p.currentScore;
                          return DataCell(Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class GlobalHistoryPage extends StatelessWidget {
  final String uid;
  const GlobalHistoryPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('戦績確認')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scores')
            .where('appUserId', isEqualTo: uid)
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // インデックス作成中などで発生するエラーをキャッチし、不自然なメッセージを隠す
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains("FAILED_PRECONDITION") || error.contains("index")) {
               return const Center(
                 child: Padding(
                   padding: EdgeInsets.all(24.0),
                   child: Text("戦績データを準備中です...\n(初回はインデックス作成のため数分かかる場合があります)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                 ),
               );
            }
            return Center(child: Text("エラーが発生しました: $error"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("まだ戦績がありません"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final start = (data['startTime'] as Timestamp).toDate();
              final dateStr = DateFormat('MM/dd HH:mm').format(start);
              final winner = data['winner'] ?? "不明";
              final players = (data['players'] as List).map((p) => p['name']).join(", ");

              return ListTile(
                leading: const Icon(Icons.cloud_done, color: Colors.blue),
                title: Text("$dateStr 優勝: $winner"),
                subtitle: Text("参加: $players"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('詳細表示は今後のアップデートで実装予定です！')));
                },
              );
            },
          );
        },
      ),
    );
  }
}
