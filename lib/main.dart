
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/game_models.dart';
import 'logic/game_logic.dart';

void main() => runApp(const SimpleMolkkyApp());

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
  final List<String> _playerNames = [];
  final TextEditingController _nameController = TextEditingController();
  int _selectedModeKey = 3;
  final Map<int, String> _options = { 1: '1番 (1セット)', 2: '2番 (2セット)', 3: '2先 (2本先取)', 5: '3先 (3本先取)', 10: '10番 (10セット)', 11: '11先 (11本先取)' };

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedPlayers = prefs.getStringList('saved_player_names');
    if (savedPlayers != null && savedPlayers.isNotEmpty) {
      setState(() {
        _playerNames.addAll(savedPlayers);
      });
    }
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_player_names', _playerNames);
  }

  void _add() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _playerNames.add(_nameController.text);
        _nameController.clear();
      });
      _savePlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セットアップ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'プレイヤー名', suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add()),
            Expanded(child: ReorderableListView(
              onReorder: (o, n) { 
                setState(() { 
                  if (o < n) n -= 1; 
                  _playerNames.insert(n, _playerNames.removeAt(o)); 
                }); 
                _savePlayers();
              }, 
              children: [ 
                for (int i = 0; i < _playerNames.length; i++) 
                  ListTile(
                    key: Key('$i-${_playerNames[i]}'), 
                    leading: const Icon(Icons.drag_handle), 
                    title: Text('${i + 1}. ${_playerNames[i]}'), 
                    trailing: IconButton(
                      icon: const Icon(Icons.delete), 
                      onPressed: () { 
                        setState(() => _playerNames.removeAt(i)); 
                        _savePlayers();
                      }
                    )
                  ) 
              ]
            )),
            DropdownButtonFormField<int>(value: _selectedModeKey, items: _options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => _selectedModeKey = v!), decoration: const InputDecoration(labelText: '試合形式')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playerNames.isEmpty ? null : () {
                final players = _playerNames.asMap().entries.map((e) => Player(id: e.value, name: e.value, initialOrder: e.key)).toList();
                MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                int limit = _selectedModeKey; if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(match: MolkkyMatch(players: players, limit: limit, type: type))));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: const Text('ゲーム開始', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            const Text('v0.1.10', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final MolkkyMatch match;
  const GameScreen({super.key, required this.match});
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
          Navigator.pop(c); if (widget.match.isMatchOver) _showMatchWinnerDialog(winner);
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
