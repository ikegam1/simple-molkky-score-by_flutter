
import 'package:flutter/material.dart';
import 'models/game_models.dart';
import 'logic/game_logic.dart';

void main() {
  runApp(const SimpleMolkkyApp());
}

class SimpleMolkkyApp extends StatelessWidget {
  const SimpleMolkkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Molkky Score',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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
  int _selectedSetMode = 3;

  final Map<int, String> _setOptions = {
    1: '1番 (1セット)',
    2: '2番 (2セット)',
    3: '2先 (2本先取)',
    5: '3先 (3本先取)',
    11: '11先 (11本先取)',
  };

  void _addPlayer() {
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
              decoration: InputDecoration(
                labelText: 'プレイヤー名を入力',
                suffixIcon: IconButton(onPressed: _addPlayer, icon: const Icon(Icons.add)),
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _playerNames.removeAt(oldIndex);
                    _playerNames.insert(newIndex, item);
                  });
                },
                children: [
                  for (int index = 0; index < _playerNames.length; index++)
                    ListTile(
                      key: Key('$index-${_playerNames[index]}'),
                      leading: const Icon(Icons.drag_handle),
                      title: Text('${index + 1}. ${_playerNames[index]}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => _playerNames.removeAt(index)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            DropdownButtonFormField<int>(
              value: _selectedSetMode,
              items: _setOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (val) => setState(() => _selectedSetMode = val!),
              decoration: const InputDecoration(labelText: '試合形式'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playerNames.isEmpty ? null : () {
                final players = <Player>[];
                for (int i = 0; i < _playerNames.length; i++) {
                  players.add(Player(id: _playerNames[i], name: _playerNames[i], initialOrder: i));
                }
                
                int winTarget;
                if (_selectedSetMode == 11) {
                  winTarget = 11;
                } else if (_selectedSetMode == 1 || _selectedSetMode == 2) {
                  winTarget = _selectedSetMode;
                } else {
                  winTarget = (_selectedSetMode / 2).ceil();
                }
                
                final match = MolkkyMatch(players: players, totalSetsToWin: winTarget);
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(match: match)));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: const Text('ゲーム開始', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            const Text('v0.1.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
  int currentTurn = 1;

  void _onSkitelTap(int num) {
    setState(() {
      if (selectedSkitels.contains(num)) {
        selectedSkitels.remove(num);
      } else {
        selectedSkitels.add(num);
      }
    });
  }

  void _submitThrow() {
    final player = widget.match.players[currentPlayerIndex];
    setState(() {
      GameLogic.processThrow(player, selectedSkitels, widget.match);
      int lastPoints = player.scoreHistory.last;
      player.matchScoreHistory.add(lastPoints);

      if (GameLogic.checkSetWinner(player, widget.match)) {
        _showSetWinnerDialog(player);
      }
      selectedSkitels.clear();
      _nextPlayer();
    });
  }

  void _nextPlayer() {
    int oldIndex = currentPlayerIndex;
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.match.players.length;
    } while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex != oldIndex);
    
    if (currentPlayerIndex == 0) {
      currentTurn++;
    }
  }

  void _undo() {
    setState(() {
      if (currentPlayerIndex == 0 && currentTurn > 1) {
        currentTurn--;
        currentPlayerIndex = widget.match.players.length - 1;
      } else if (currentPlayerIndex > 0) {
        currentPlayerIndex--;
      }

      final player = widget.match.players[currentPlayerIndex];
      if (player.scoreHistory.isNotEmpty) {
        int lastPoints = player.scoreHistory.removeLast();
        player.matchScoreHistory.removeLast();
        player.currentScore -= lastPoints; 
        if (lastPoints == 0 && player.consecutiveMisses > 0) {
          player.consecutiveMisses--;
          player.isDisqualified = false;
        }
      }
      selectedSkitels.clear();
    });
  }

  void _showSummaryDialog({String title = '現在の状況'}) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('--- マッチ統計 ---', style: TextStyle(color: Colors.grey)),
              Flexible(
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(label: Text('名')),
                      DataColumn(label: Text('セット')),
                      DataColumn(label: Text('総点')),
                      DataColumn(label: Text('投数')),
                    ],
                    rows: widget.match.players.map((p) => DataRow(cells: [
                      DataCell(Text(p.name)),
                      DataCell(Text('${p.setsWon}')),
                      DataCell(Text('${p.totalMatchScore}')),
                      DataCell(Text('${p.totalMatchThrows}')),
                    ])).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('戻る')),
        ],
      ),
    );
  }

  void _showSetWinnerDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('第 ${widget.match.currentSetIndex} セット終了'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${winner.name} さんが50点到達！', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              const Text('--- マッチ状況 ---', style: TextStyle(color: Colors.grey)),
              Flexible(
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(label: Text('名')),
                      DataColumn(label: Text('セット')),
                      DataColumn(label: Text('総点')),
                      DataColumn(label: Text('投数')),
                    ],
                    rows: widget.match.players.map((p) => DataRow(cells: [
                      DataCell(Text(p.name)),
                      DataCell(Text('${p.setsWon}')),
                      DataCell(Text('${p.totalMatchScore}')),
                      DataCell(Text('${p.totalMatchThrows}')),
                    ])).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              if (widget.match.matchWinner != null) {
                _showMatchWinnerDialog(widget.match.matchWinner!);
              } else {
                setState(() {
                  widget.match.prepareNextSet();
                  currentPlayerIndex = 0;
                  currentTurn = 1;
                });
              }
            },
            child: const Text('次のセットへ'),
          )
        ],
      ),
    );
  }

  void _showMatchWinnerDialog(Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('🎊 優勝！ 🎊'),
        content: Text('${winner.name} さんの勝利です！'),
        actions: [
          TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('終了'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.match.players[currentPlayerIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${widget.match.currentSetIndex} セット'),
        actions: [
          TextButton.icon(
            onPressed: _showSummaryDialog,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('履歴'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue[100]!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(8),
            child: Text(
              '${currentPlayer.name} の番です (ターン $currentTurn)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 10,
                    headingRowHeight: 40,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 40,
                    border: TableBorder.all(color: Colors.grey[300]!),
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                    columns: [
                      const DataColumn(label: SizedBox(width: 40, child: Text('ターン', textAlign: TextAlign.center))),
                      ...widget.match.players.expand((p) => [
                        DataColumn(label: Container(
                          width: 80, 
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text('得点', style: TextStyle(fontSize: 9)),
                                  Text('合計', style: TextStyle(fontSize: 9)),
                                ],
                              )
                            ],
                          ),
                        )),
                      ]),
                    ],
                    rows: List.generate(currentTurn, (i) {
                      int turnNum = currentTurn - i;
                      return DataRow(cells: [
                        DataCell(Center(child: Text('$turnNum'))),
                        ...widget.match.players.expand((p) {
                          int score = 0;
                          int total = 0;
                          if (p.scoreHistory.length >= turnNum) {
                            score = p.scoreHistory[turnNum - 1];
                            int tempTotal = 0;
                            for (int k = 0; k < turnNum; k++) {
                              tempTotal += p.scoreHistory[k];
                              if (tempTotal > 50) tempTotal = 25;
                            }
                            total = tempTotal;
                          }
                          return [
                            DataCell(
                              Row(
                                children: [
                                  Container(width: 40, alignment: Alignment.center, child: Text(p.scoreHistory.length >= turnNum ? '$score' : '-', style: const TextStyle(fontSize: 13))),
                                  Container(width: 40, alignment: Alignment.center, color: Colors.blue[50], child: Text(p.scoreHistory.length >= turnNum ? '$total' : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                ],
                              )
                            ),
                          ];
                        }),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]
            ),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (c, i) {
                    final num = i + 1;
                    final isSelected = selectedSkitels.contains(num);
                    return ElevatedButton(
                      onPressed: () => _onSkitelTap(num),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isSelected ? Colors.orange[100] : Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                      child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _undo,
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.undo, size: 18), SizedBox(width: 4), Text('戻る')]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submitThrow,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 8),
                            Text(
                              selectedSkitels.isEmpty ? '0点 (ミス)' : '決定 (${selectedSkitels.length == 1 ? selectedSkitels.first : selectedSkitels.length}点)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
