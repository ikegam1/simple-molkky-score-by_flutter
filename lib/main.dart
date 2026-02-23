
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:html' as html;
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

  void _add() { if (_nameController.text.isNotEmpty) { setState(() { _playerNames.add(_nameController.text); _nameController.clear(); }); } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セットアップ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'プレイヤー名', suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add()),
            Expanded(child: ReorderableListView(onReorder: (o, n) { setState(() { if (o < n) n -= 1; _playerNames.insert(n, _playerNames.removeAt(o)); }); }, children: [ for (int i = 0; i < _playerNames.length; i++) ListTile(key: Key('$i-${_playerNames[i]}'), leading: const Icon(Icons.drag_handle), title: Text('${i + 1}. ${_playerNames[i]}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _playerNames.removeAt(i)))) ])),
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
            const Text('v0.1.8', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
  final ScreenshotController screenshotController = ScreenshotController();
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
        systemCalculatedIds.add(s.id); // システム補填フラグ
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

  void _showSummary() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('マッチ状況'),
      content: SingleChildScrollView(child: DataTable(columnSpacing: 10, columns: const [DataColumn(label: Text('名')), DataColumn(label: Text('セット')), DataColumn(label: Text('総点')), DataColumn(label: Text('投数'))],
        rows: widget.match.players.map((p) => DataRow(cells: [DataCell(Text(p.name)), DataCell(Text('${p.setsWon}')), DataCell(Text('${p.totalMatchScore}')), DataCell(Text('${p.totalMatchThrows}'))])).toList())),
      actions: [ElevatedButton.icon(onPressed: _export, icon: const Icon(Icons.download), label: const Text('画像を保存')), TextButton(onPressed: () => Navigator.pop(c), child: const Text('戻る'))],
    ));
  }

  void _showSetWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: Text('第 ${widget.match.currentSetIndex} セット終了'), content: Text('${winner.name} さんが勝利！'),
      actions: [TextButton(onPressed: () {
        Navigator.pop(c); if (widget.match.isMatchOver) _showMatchWinnerDialog(winner);
        else setState(() { widget.match.prepareNextSet(); currentPlayerIndex = 0; currentTurnInSet = 1; isSetFinished = false; turnInProgressScores.clear(); systemCalculatedIds.clear(); selectedSkitels.clear(); });
      }, child: Text(widget.match.isMatchOver ? '最終結果へ' : '次のセットへ'))]));
  }

  void _showMatchWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(title: const Text('🎊 優勝！ 🎊'), content: Text('${winner.name} さんの勝利です！'),
      actions: [ElevatedButton.icon(onPressed: _export, icon: const Icon(Icons.download), label: const Text('保存')), TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('終了'))]));
  }

  Future<void> _export() async {
    final players = widget.match.players;
    final dateString = DateFormat('yyyy/MM/dd HH:mm').format(widget.match.startTime);
    List<SetRecord> allSets = List.from(widget.match.completedSets);
    if (!isSetFinished) {
       SetRecord ongoing = SetRecord(widget.match.currentSetRecord.setNumber, widget.match.currentSetRecord.starterPlayerId);
       ongoing.turns.addAll(widget.match.currentSetRecord.turns);
       if (turnInProgressScores.isNotEmpty) ongoing.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
       allSets.add(ongoing);
    } else allSets.add(widget.match.currentSetRecord);

    List<Widget> rows = [];
    rows.add(_buildImageHeader(players));
    for (var set in allSets) {
      for (var turn in set.turns) rows.add(_buildImageTurnRow(turn, players, set.starterPlayerId));
      Map<String, int> scores = set.finalCumulativeScores.isNotEmpty ? set.finalCumulativeScores : { for (var p in players) p.id : p.currentScore };
      rows.add(_buildImageSetSummaryRow(set.setNumber, scores, players));
    }

    final widgetToCapture = Container(padding: const EdgeInsets.all(10), color: Colors.white, width: 600,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Molkky Result', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
        Text('開始: $dateString', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        Column(children: rows),
      ]),
    );

    _download(await screenshotController.captureFromWidget(widgetToCapture, delay: const Duration(milliseconds: 200)), 'molkky_result.png');
  }

  Widget _buildImageHeader(List<Player> players) {
    return Container(color: const Color(0xFFF1F8FE), padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [ const Expanded(flex: 1, child: Center(child: Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))), ...players.map((p) => Expanded(flex: 2, child: Center(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)))) ]));
  }

  Widget _buildImageTurnRow(TurnRecord turn, List<Player> players, String starterId) {
    return Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))), padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(flex: 1, child: Center(child: Text('${turn.turnNumber}', style: const TextStyle(fontSize: 11)))),
        ...players.map((p) {
          bool isSys = turn.systemCalculatedPlayerIds.contains(p.id);
          String txt = turn.scores.containsKey(p.id) ? (isSys ? "-" : "${turn.scores[p.id]}") : "-";
          return Expanded(flex: 2, child: Center(child: Text(txt, style: TextStyle(fontWeight: p.id == starterId ? FontWeight.bold : FontWeight.normal, fontSize: 13))));
        })]));
  }

  Widget _buildImageSetSummaryRow(int setNum, Map<String, int> totals, List<Player> players) {
    return Container(color: const Color(0xFFFFF8E1), padding: const EdgeInsets.symmetric(vertical: 2), margin: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Expanded(flex: 1, child: Center(child: Text('S$setNum計', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)))),
        ...players.map((p) => Expanded(flex: 2, child: Center(child: Text('${totals[p.id] ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)))))]));
  }

  void _download(Uint8List bytes, String name) {
    final blob = html.Blob([bytes]); final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute("download", name)..click(); html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.match.players[currentPlayerIndex];
    return Scaffold(
      appBar: AppBar(title: Text('第 ${widget.match.currentSetIndex} セット'), actions: [TextButton.icon(onPressed: _showSummary, icon: const Icon(Icons.history, size: 18), label: const Text('履歴'))]),
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
