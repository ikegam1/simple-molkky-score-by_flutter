
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

  final Map<int, String> _options = {
    1: '1番 (1セット)',
    2: '2番 (2セット)',
    3: '2先 (2本先取)',
    5: '3先 (3本先取)',
    10: '10番 (10セット)',
    11: '11先 (11本先取)',
  };

  void _add() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _playerNames.add(_nameController.text);
        _nameController.clear();
      });
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'プレイヤー名', suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))),
              onSubmitted: (_) => _add(),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (oldIdx < newIdx) newIdx -= 1;
                    _playerNames.insert(newIdx, _playerNames.removeAt(oldIdx));
                  });
                },
                children: [
                  for (int i = 0; i < _playerNames.length; i++)
                    ListTile(key: Key('$i-${_playerNames[i]}'), leading: const Icon(Icons.drag_handle), title: Text('${i + 1}. ${_playerNames[i]}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _playerNames.removeAt(i)))),
                ],
              ),
            ),
            DropdownButtonFormField<int>(
              value: _selectedModeKey,
              items: _options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _selectedModeKey = v!),
              decoration: const InputDecoration(labelText: '試合形式'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playerNames.isEmpty ? null : () {
                final players = _playerNames.asMap().entries.map((e) => Player(id: e.value, name: e.value, initialOrder: e.key)).toList();
                MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                int limit = _selectedModeKey;
                if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                
                final match = MolkkyMatch(players: players, limit: limit, type: type);
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(match: match)));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: const Text('ゲーム開始', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            const Text('v0.1.1', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  void _onSkitelTap(int num) {
    if (isSetFinished) return;
    setState(() {
      if (selectedSkitels.contains(num)) selectedSkitels.remove(num); else selectedSkitels.add(num);
    });
  }

  void _submitThrow() {
    if (isSetFinished) return;
    final player = widget.match.players[currentPlayerIndex];
    
    setState(() {
      // 1. スコア処理
      GameLogic.processThrow(player, selectedSkitels, widget.match);
      player.matchScoreHistory.add(player.scoreHistory.last);

      // 2. 即時勝利判定
      Player? setWinner;
      for (var p in widget.match.players) {
        if (p.currentScore == widget.match.targetScore) {
          setWinner = p;
          break;
        }
      }

      // 3. 終了または次へ
      if (setWinner != null) {
        isSetFinished = true;
        setWinner.setsWon++;
        for (var p in widget.match.players) p.setFinalScores.add(p.currentScore);
        _showSetWinnerDialog(setWinner);
      } else {
        selectedSkitels.clear();
        _nextPlayer();
      }
    });
  }

  void _nextPlayer() {
    int startIdx = currentPlayerIndex;
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.match.players.length;
    } while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex != startIdx);
    if (currentPlayerIndex == 0) currentTurnInSet++;
  }

  void _undo() {
    if (isSetFinished) return;
    setState(() {
      if (currentPlayerIndex == 0 && currentTurnInSet > 1) {
        currentTurnInSet--;
        currentPlayerIndex = widget.match.players.length - 1;
      } else if (currentPlayerIndex > 0) {
        currentPlayerIndex--;
      } else return;

      while (widget.match.players[currentPlayerIndex].scoreHistory.isEmpty) {
        if (currentPlayerIndex == 0 && currentTurnInSet > 1) {
          currentTurnInSet--;
          currentPlayerIndex = widget.match.players.length - 1;
        } else if (currentPlayerIndex > 0) currentPlayerIndex--; else break;
      }

      final p = widget.match.players[currentPlayerIndex];
      if (p.scoreHistory.isNotEmpty) {
        int last = p.scoreHistory.removeLast();
        p.matchScoreHistory.removeLast();
        p.currentScore -= last;
        if (last == 0 && p.consecutiveMisses > 0) {
          p.consecutiveMisses--;
          p.isDisqualified = false;
        }
      }
      selectedSkitels.clear();
    });
  }

  void _showSummary({String title = '現在の状況'}) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 10,
          columns: const [DataColumn(label: Text('名')), DataColumn(label: Text('セット')), DataColumn(label: Text('総点')), DataColumn(label: Text('投数'))],
          rows: widget.match.players.map((p) => DataRow(cells: [DataCell(Text(p.name)), DataCell(Text('${p.setsWon}')), DataCell(Text('${p.totalMatchScore}')), DataCell(Text('${p.totalMatchThrows}'))])).toList(),
        ),
      ),
      actions: [
        ElevatedButton.icon(onPressed: _export, icon: const Icon(Icons.download), label: const Text('画像を保存')),
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('戻る')),
      ],
    ));
  }

  void _showSetWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: Text('第 ${widget.match.currentSetIndex} セット終了'),
      content: Text('${winner.name} さんが勝利！'),
      actions: [
        TextButton(onPressed: () {
          Navigator.pop(c);
          if (widget.match.isMatchOver) {
            _showMatchWinnerDialog(widget.match.matchWinner ?? winner);
          } else {
            setState(() {
              widget.match.prepareNextSet();
              currentPlayerIndex = 0;
              currentTurnInSet = 1;
              isSetFinished = false;
              selectedSkitels.clear();
            });
          }
        }, child: Text(widget.match.isMatchOver ? '最終結果へ' : '次のセットへ'))
      ],
    ));
  }

  void _showMatchWinnerDialog(Player winner) {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: const Text('🎊 優勝！ 🎊'),
      content: Text('${winner.name} さんの勝利です！'),
      actions: [
        ElevatedButton.icon(onPressed: _export, icon: const Icon(Icons.download), label: const Text('最終結果を保存')),
        TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('終了'))
      ],
    ));
  }

  Future<void> _export() async {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final dateString = dateFormat.format(widget.match.startTime);
    final players = widget.match.players;

    List<Map<String, dynamic>> flatHistory = [];
    int globalTurn = 0;
    int currentSet = 1;
    int turnInCurrentSet = 1;

    // プレイヤーごとの履歴インデックスを管理
    Map<String, int> pIndices = { for (var p in players) p.id : 0 };
    bool hasData = true;

    while (hasData) {
      hasData = false;
      Map<String, int> turnScores = {};
      bool setEndedInThisTurn = false;

      for (var p in players) {
        int idx = pIndices[p.id]!;
        if (idx < p.matchScoreHistory.length) {
          turnScores[p.id] = p.matchScoreHistory[idx];
          pIndices[p.id] = idx + 1;
          hasData = true;
          // セット終了行を挿入すべきかチェック
          if (p.setFinalScores.length >= currentSet && p.matchScoreHistory.take(idx+1).fold(0, (a,b)=>a+b) == p.setFinalScores[currentSet-1]) {
             setEndedInThisTurn = true;
          }
        }
      }

      if (turnScores.isNotEmpty) {
        flatHistory.add({ 'type': 'score', 'turn': turnInCurrentSet, 'scores': turnScores });
        turnInCurrentSet++;
      }

      if (setEndedInThisTurn) {
        flatHistory.add({ 'type': 'separator', 'set': currentSet });
        currentSet++;
        turnInCurrentSet = 1;
      }
    }

    // 100行ごとにページ分割
    int pageSize = 100;
    int pages = (flatHistory.length / pageSize).ceil();
    if (pages == 0) pages = 1;

    for (int p = 0; p < pages; p++) {
      final chunk = flatHistory.skip(p * pageSize).take(pageSize).toList();
      final widgetToCapture = Container(
        padding: const EdgeInsets.all(20), color: Colors.white, width: 800,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Molkky Match Result', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900])),
          Text('開始: $dateString | Page: ${p + 1}/$pages', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          Table(border: TableBorder.all(color: Colors.grey), children: [
            TableRow(decoration: BoxDecoration(color: Colors.blue[50]), children: [
              const TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('ターン', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              ...players.map((pl) => TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text(pl.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)))),
            ]),
            ...chunk.map((item) {
              if (item['type'] == 'separator') {
                return TableRow(decoration: BoxDecoration(color: Colors.orange[50]), children: [
                  TableCell(child: Padding(padding: const EdgeInsets.all(4), child: Text('第${item['set']}セット終了', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                  ...players.map((_) => const TableCell(child: SizedBox())),
                ]);
              } else {
                return TableRow(children: [
                  TableCell(child: Padding(padding: const EdgeInsets.all(8), child: Text('${item['turn']}'))),
                  ...players.map((pl) => TableCell(child: Padding(padding: const EdgeInsets.all(8), child: Text(item['scores'].containsKey(pl.id) ? '${item['scores'][pl.id]}' : '-')))),
                ]);
              }
            }),
          ]),
        ]),
      );
      final bytes = await screenshotController.captureFromWidget(widgetToCapture);
      _download(bytes, 'molkky_result_p${p + 1}.png');
    }
  }

  void _download(Uint8List bytes, String name) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute("download", name)..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.match.players[currentPlayerIndex];
    return Scaffold(
      appBar: AppBar(title: Text('第 ${widget.match.currentSetIndex} セット'), actions: [TextButton.icon(onPressed: () => _showSummary(), icon: const Icon(Icons.history, size: 18), label: const Text('履歴'))]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Text('${currentPlayer.name} の番 (ターン $currentTurnInSet)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
            child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                columns: [const DataColumn(label: SizedBox(width: 40, child: Text('ターン'))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('得点', style: TextStyle(fontSize: 9)), Text('合計', style: TextStyle(fontSize: 9))])])))])],
                rows: List.generate(currentTurnInSet, (i) {
                  int turn = currentTurnInSet - i;
                  return DataRow(cells: [DataCell(Center(child: Text('$turn'))), ...widget.match.players.expand((p) {
                    int score = 0, total = 0;
                    if (p.scoreHistory.length >= turn) {
                      score = p.scoreHistory[turn - 1];
                      int tmp = 0;
                      for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > 50) tmp = 25; }
                      total = tmp;
                    }
                    return [DataCell(Row(children: [Container(width: 40, alignment: Alignment.center, child: Text(p.scoreHistory.length >= turn ? '$score' : '-')), Container(width: 40, alignment: Alignment.center, color: Colors.blue[50], child: Text(p.scoreHistory.length >= turn ? '$total' : '-', style: const TextStyle(fontWeight: FontWeight.bold)))]))];
                  })]);
                }),
              ),
            ))),
          ),
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(children: [
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0), itemCount: 12, itemBuilder: (c, i) {
                final num = i + 1; final isSelected = selectedSkitels.contains(num);
                return ElevatedButton(onPressed: () => _onSkitelTap(num), style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.orange[100] : Colors.white, foregroundColor: Colors.black, side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
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
