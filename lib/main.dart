
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:speech_to_text/speech_to_text.dart';
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
      'self5turn_solo_only': 'Self 5-Turn is solo only (1 player)',
      'self5turn_mode': 'Self 5-Turn (solo)',
      'self5turn_challenge_n': 'Challenge {n}',
      'self5turn_success': 'Success! 🎉',
      'self5turn_failure': 'Failed...',
      'consecutive_success': 'Streak: {n}',
      'next_challenge': 'Next Challenge',
      'back_to_top': 'Back to Top',
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
      'self5turn_solo_only': 'セルフ5ターンは1名専用です',
      'self5turn_mode': 'セルフ5ターン（1人用）',
      'self5turn_challenge_n': 'チャレンジ {n}',
      'self5turn_success': '成功！🎉',
      'self5turn_failure': '失敗...',
      'consecutive_success': '連続成功: {n}回',
      'next_challenge': '次のチャレンジへ',
      'back_to_top': 'トップへ',
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
  bool _voiceInputEnabled = false; // 音声入力設定の追加

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
    // key=-1: self5Turn, key=1/2/10: fixedSets, others: raceTo (limit=ceil(key/2))
    final Map<int, String> options = {
      1: t.get('sets_count', args: {'n': '1'}),
      2: t.get('sets_count', args: {'n': '2'}),
      3: t.get('race_to', args: {'n': '2'}),
      5: t.get('race_to', args: {'n': '3'}),
      7: t.get('race_to', args: {'n': '4'}),
      9: t.get('race_to', args: {'n': '5'}),
      10: t.get('sets_count', args: {'n': '10'}),
      11: t.get('race_to', args: {'n': '11'}),
      -1: t.get('self5turn_mode'),
    };
    final bool self5TurnEnabled = _registeredPlayers.length <= 1;

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
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpPage())), tooltip: '使い方'),
          IconButton(icon: const Icon(Icons.history), onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))), tooltip: t.get('match_history')),
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
            TextField(controller: _nameController, decoration: InputDecoration(labelText: t.get('player_name'), suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add))), onSubmitted: (_) => _add(), maxLength: 20, buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null),
            Expanded(child: ReorderableListView(
              onReorder: (o, n) { setState(() { if (o < n) n -= 1; _registeredPlayers.insert(n, _registeredPlayers.removeAt(o)); }); _savePlayers(); }, 
              children: [ for (int i = 0; i < _registeredPlayers.length; i++) ListTile(key: Key(_registeredPlayers[i].id), leading: const Icon(Icons.drag_handle), title: Text('${i + 1}. ${_registeredPlayers[i].name}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() { _registeredPlayers.removeAt(i); }); _savePlayers(); })) ]
            )),
            DropdownButtonFormField<int>(
              value: _selectedModeKey,
              items: options.entries.map((e) {
                final isSelf5Turn = e.key == -1;
                final enabled = !isSelf5Turn || self5TurnEnabled;
                return DropdownMenuItem<int>(
                  value: e.key,
                  enabled: enabled,
                  child: Text(e.value, style: TextStyle(color: enabled ? null : Colors.grey)),
                );
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedModeKey = v); },
              decoration: InputDecoration(labelText: t.get('game_mode')),
            ),
            const SizedBox(height: 10),
            // 音声入力設定スイッチの追加
            SwitchListTile(
              title: const Text('音声入力 (試験中)', style: TextStyle(fontSize: 16)),
              value: _voiceInputEnabled,
              onChanged: (bool value) => setState(() => _voiceInputEnabled = value),
              secondary: Icon(Icons.mic, color: _voiceInputEnabled ? Colors.blue : Colors.grey),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _registeredPlayers.isEmpty ? null : () {
                // セルフ5ターンは1名専用。2名以上ではエラー
                if (_selectedModeKey == -1 && _registeredPlayers.length > 1) {
                  _showError(t.get('self5turn_solo_only'));
                  return;
                }
                final playersForMatch = _registeredPlayers.asMap().entries.map((e) => Player(id: e.value.id, name: e.value.name, initialOrder: e.key)).toList();
                MolkkyMatch match;
                if (_selectedModeKey == -1) {
                  match = MolkkyMatch(players: playersForMatch, limit: 99, type: MatchType.self5Turn);
                } else {
                  MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                  int limit = _selectedModeKey; if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                  match = MolkkyMatch(players: playersForMatch, limit: limit, type: type);
                }
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(appUserId: _firebaseUid, match: match, voiceEnabled: _voiceInputEnabled)));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: Text(t.get('start_game'), style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))), icon: const Icon(Icons.cloud_done), label: Text(t.get('match_history')), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45))),
            const SizedBox(height: 10),
            if (_firebaseUid.isNotEmpty) Text(t.get('anonymous_id', args: {'id': _firebaseUid.substring(0, 8)}), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('v1.9.3', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final MolkkyMatch match;
  final String appUserId;
  final bool voiceEnabled;
  const GameScreen({super.key, required this.match, required this.appUserId, this.voiceEnabled = false});
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

  // 音声認識
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  String? _localeId; // 利用可能な日本語ロケールID
  String _voiceText = ''; // リアルタイム認識テキスト（デバッグ兼UX）

  bool _micHeld = false;          // user is holding mic button
  bool _autoMicActive = false;    // 60s auto mode is active
  Timer? _autoMicTimer;           // countdown for auto mode

  bool get _voiceActive => _micHeld || _autoMicActive;

  // 経過秒タイマー
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  Timer? _speechConfirmTimer;
  int _listenSessionId = 0; // セッションIDで古い認識結果を除外する

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _resetElapsedTimer();
  }

  @override
  void dispose() {
    _autoMicTimer?.cancel();
    _elapsedTimer?.cancel();
    _speechConfirmTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    if (!widget.voiceEnabled) return; // 音声無効時は初期化しない
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() {});
        // 'done' のみで再起動。
        // 'notListening' は listen() 直後にも発火するため、
        // ここで再起動するとループ（緑点滅）の原因になる。
        if (status == 'done' && !isSetFinished && _voiceActive) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_voiceActive) _startListening();
          });
        }
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        if (!mounted) return;
        setState(() {});
        if (!isSetFinished && _voiceActive) Future.delayed(const Duration(seconds: 1), _startListening);
      },
    );
    if (_speechAvailable) {
      // 利用可能なロケールから日本語を探して使用する
      // Webではlocales()が空リストを返すことがあるため安全に処理する
      try {
        final locales = await _speech.locales();
        if (locales.isNotEmpty) {
          final jaLocale = locales.firstWhere(
            (l) => l.localeId.startsWith('ja'),
            orElse: () => locales.first,
          );
          _localeId = jaLocale.localeId;
        }
        debugPrint('Speech locale: $_localeId');
      } catch (e) {
        debugPrint('locales() failed: $e');
      }
    }
    if (mounted) setState(() {});
    // 初期化直後は自動60秒モードで開始
    if (_speechAvailable && mounted) {
      _startAutoMic();
    }
  }

  void _startAutoMic() {
    if (!widget.voiceEnabled || !_speechAvailable || !mounted) return;
    _autoMicTimer?.cancel();
    setState(() => _autoMicActive = true);
    _autoMicTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      setState(() => _autoMicActive = false);
      _speech.stop();
    });
    // 必ず stop してから少し待って再スタート（エンジンのリセットを確実にする）
    _speech.stop();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _voiceActive) _startListening();
    });
  }

  void _resetElapsedTimer() {
    _elapsedTimer?.cancel();
    setState(() => _elapsedSeconds = 0);
    if (isSetFinished) return;
    if (_autoMicActive) _startAutoMic();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _elapsedTimer?.cancel(); return; }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds == 60) {
        SystemSound.play(SystemSoundType.alert);
      }
    });
  }

  void _startListening() {
    if (!widget.voiceEnabled || !_speechAvailable || _speech.isListening || isSetFinished || !mounted || !_voiceActive) return;
    final sessionId = ++_listenSessionId;
    _speech.listen(
      onResult: (result) {
        // 古いセッションの遅延結果は無視する
        if (!mounted || _listenSessionId != sessionId) return;
        setState(() => _voiceText = result.recognizedWords);

        // 途中結果：3秒フォールバックタイマー（finalResultが遅い端末への保険）
        _speechConfirmTimer?.cancel();
        if (!result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speechConfirmTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted && _voiceActive && _listenSessionId == sessionId) {
              final handled = _processVoiceInput(result.recognizedWords);
              if (handled) {
                // スコア確定時のみセッションを無効化して遅延finalResultの二重送信を防ぐ
                ++_listenSessionId;
                setState(() => _voiceText = '');
              }
            }
          });
        }

        if (result.finalResult) {
          _speechConfirmTimer?.cancel();
          _processVoiceInput(result.recognizedWords);
          setState(() => _voiceText = '');
        }
      },
      localeId: _localeId ?? 'ja-JP',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
    );
  }

  /// 音声入力を解析してスコアを適用する。スコアを確定した場合 true を返す
  bool _processVoiceInput(String text) {
    if (isSetFinished) return false;
    final score = _parseVoiceScore(text);
    if (score == null) return false;

    // 成功時に音とバイブレーションでフィードバック
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎤 $text'),
      duration: const Duration(milliseconds: 1500),
      backgroundColor: Colors.blue.shade700,
    ));

    if (score < 0) {
      selectedSkitels = [];
    } else {
      selectedSkitels = [score];
    }
    _submitThrow();
    // _submitThrow内の else ブランチで _startAutoMic / _resetElapsedTimer が呼ばれる
    return true;
  }

  /// ウェイクワード検索：STT の認識揺れ（投てき終了 等）にも対応
  int _wakeWordEnd(String text) {
    // 句読点やスペースを排除して比較（認識精度向上）
    final normalized = text.replaceAll(RegExp(r'[、。,.\s　]'), '');
    
    // 完全一致パターン（長いものを先に照合して誤マッチを防ぐ）
    for (final w in [
      '投擲終了', '投てき終了', 'とうてき終了', '投テキ終了',
      '投擲しゅうりょう', '投擲修了', '投擲週了',
    ]) {
      final idx = normalized.indexOf(w);
      if (idx >= 0) return idx + w.length;
    }
    // 部分一致（STT認識ズレ対応）
    for (final w in [
      'てきしゅ', '敵襲', 'てき終', 'てき修', 'テキ終', 'テキ修',
      '圧倒的', // STT誤認識パターン
      '入力',   // 「入力10点」など
      '終了',   // 「終了2点」など短い発話にも対応
    ]) {
      final idx = normalized.indexOf(w);
      if (idx >= 0) return idx + w.length;
    }
    return -1;
  }

  /// ウェイクワード以降のテキストから点数を解析する。
  /// 戻り値: 1〜12=ピン番号、-1=ミス、null=認識失敗
  int? _parseVoiceScore(String text) {
    final normalized = text.replaceAll(RegExp(r'[、。,.\s　]'), '');

    // 「N点を入力」「N点入れて」「N点入力」パターン（点数がウェイクワードの前に来る）
    // アラビア数字（「10点入力」「10てん入力」の両形式に対応）
    final scoreFirstMatch = RegExp(r'(\d{1,2})(?:点|てん)(?:を入力|入れて|入力)').firstMatch(normalized);
    if (scoreFirstMatch != null) {
      final n = int.tryParse(scoreFirstMatch.group(1)!);
      if (n != null && n >= 1 && n <= 12) return n;
    }
    // 日本語数字（長いものを先に照合して誤マッチを防ぐ）
    // 日本語数字（長いものを先に照合して誤マッチを防ぐ）
    // 「点」はSTTでは「てん」と出ることもある
    const jpScoreFirstList = <(String, int)>[
      ('じゅうに', 12), ('十二', 12), ('じゅういち', 11), ('十一', 11),
      ('じゅう', 10), ('十', 10), ('きゅう', 9), ('九', 9),
      ('はち', 8), ('八', 8), ('なな', 7), ('しち', 7), ('七', 7),
      ('ろく', 6), ('六', 6), ('ご', 5), ('五', 5),
      ('よん', 4), ('よっ', 4), ('四', 4), ('さん', 3), ('三', 3),
      ('に', 2), ('二', 2), ('いっ', 1), ('いち', 1), ('一', 1),
    ];
    for (final (jp, score) in jpScoreFirstList) {
      // 「にてん入力」「さんてんを入力」「十てん入れて」など
      if (RegExp('${RegExp.escape(jp)}(?:てん|点)(?:を入力|入れて|入力)').hasMatch(normalized)) return score;
    }

    final wakeEnd = _wakeWordEnd(text);
    String afterWake;
    if (wakeEnd >= 0) {
      afterWake = normalized.substring(wakeEnd);
    } else {
      // ウェイクワードが必須なため、それ以外は無視する
      return null;
    }

    if (afterWake.isEmpty) return null;
    if (afterWake.contains('ミス') || afterWake.contains('みす')) return -1;

    // アラビア数字を優先して検出
    final digitMatch = RegExp(r'(\d+)').firstMatch(afterWake);
    if (digitMatch != null) {
      final n = int.tryParse(digitMatch.group(1)!);
      if (n != null && n >= 1 && n <= 12) return n;
    }

    // 日本語数字（長いパターンを先に照合して部分一致を防ぐ）
    const jpMap = <String, int>{
      'じゅうに': 12, '十二': 12,
      'じゅういち': 11, '十一': 11,
      'じゅう': 10, '十': 10,
      'きゅう': 9, '九': 9,
      'はち': 8, '八': 8,
      'ななてん': 7, 'しちてん': 7, 'なな': 7, 'しち': 7, '七': 7,
      'ろくてん': 6, 'ろく': 6, '六': 6,
      'ごてん': 5, 'ご': 5, '五': 5,
      'よんてん': 4, 'してん': 4, 'よん': 4, '四': 4,
      'さんてん': 3, 'さん': 3, '三': 3,
      'にてん': 2, '二': 2,
      'いってん': 1, 'いちてん': 1, 'いち': 1, '一': 1,
    };

    for (final entry in jpMap.entries) {
      if (afterWake.contains(entry.key)) return entry.value;
    }

    return null;
  }

  void _onSkitelTap(int num) { if (isSetFinished) return; setState(() { if (selectedSkitels.contains(num)) selectedSkitels.remove(num); else selectedSkitels.add(num); }); }

  void _submitThrow() {
    if (isSetFinished) return;
    bool self5TurnSucceeded = false;
    bool self5TurnFailed = false;
    final player = widget.match.players[currentPlayerIndex];
    setState(() {
      GameLogic.processThrow(player, selectedSkitels, widget.match);
      int lastPoints = player.scoreHistory.last;
      player.matchScoreHistory.add(lastPoints);
      turnInProgressScores[player.id] = lastPoints;

      // === Self5Turn mode: 5投制チャレンジ判定 ===
      if (widget.match.type == MatchType.self5Turn) {
        widget.match.currentSetRecord.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores)));
        turnInProgressScores.clear(); systemCalculatedIds.clear();
        bool succeeded = player.currentScore == widget.match.targetScore;
        bool failed = player.isDisqualified || (!succeeded && currentTurnInSet >= 5);
        if (succeeded) {
          self5TurnSucceeded = true;
          isSetFinished = true;
          widget.match.consecutiveSuccesses++;
          widget.match.finalizeCurrentSetIfNeeded();
        } else if (failed) {
          self5TurnFailed = true;
          isSetFinished = true;
          widget.match.finalizeCurrentSetIfNeeded();
        } else {
          selectedSkitels.clear();
          currentTurnInSet++;
        }
        return; // 通常ロジックをスキップ
      }
      // === End Self5Turn mode ===

      final survivors = widget.match.players.where((p) => !p.isDisqualified).toList();

      if (widget.match.players.length >= 2 && survivors.length == 1) {
        final s = survivors.first;
        int needed = widget.match.targetScore - s.currentScore;
        s.currentScore = widget.match.targetScore;
        s.scoreHistory.add(needed); // セット内スコア表示用（matchScoreHistory と対で必要）
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
    // タイマーと音声の管理
    if (widget.match.type == MatchType.self5Turn) {
      if (isSetFinished) {
        _elapsedTimer?.cancel(); _autoMicTimer?.cancel(); _speech.stop();
        if (self5TurnSucceeded) _showSelf5TurnSuccessDialog();
        else if (self5TurnFailed) { _uploadSelf5TurnData(); _showSelf5TurnFailureDialog(); }
      } else {
        _resetElapsedTimer(); _startAutoMic();
      }
      return;
    }
    // セット終了時はタイマーと音声を停止
    if (isSetFinished) {
      _elapsedTimer?.cancel();
      _autoMicTimer?.cancel();
      _speech.stop();
    } else {
      _resetElapsedTimer();
      _startAutoMic(); // 点数確定後に確実に入力待ち再開
    }
  }

  void _nextPlayer() {
    int start = currentPlayerIndex;
    do { currentPlayerIndex = (currentPlayerIndex + 1) % widget.match.players.length; } while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex != start);
    // currentPlayerIndex <= start はラップアラウンドを意味する（プレイヤー0が失格でも正しく判定）
    if (currentPlayerIndex <= start) currentTurnInSet++;
  }

  void _undo() {
    if (isSetFinished || (currentTurnInSet == 1 && currentPlayerIndex == 0)) return;
    setState(() {
      if (currentPlayerIndex == 0) { currentTurnInSet--; currentPlayerIndex = widget.match.players.length - 1; } else { currentPlayerIndex--; }
      while (widget.match.players[currentPlayerIndex].isDisqualified && currentPlayerIndex > 0) { currentPlayerIndex--; }
      final p = widget.match.players[currentPlayerIndex];
      if (p.scoreHistory.isNotEmpty) {
        int last = p.scoreHistory.removeLast(); p.matchScoreHistory.removeLast();
        // scoreSnapshot を使って投擲前スコアを正確に復元（バースト時も正しく戻る）
        if (p.scoreSnapshot.isNotEmpty) p.currentScore = p.scoreSnapshot.removeLast();
        turnInProgressScores.remove(p.id); systemCalculatedIds.remove(p.id);
        if (last == 0 && p.consecutiveMisses > 0) { p.consecutiveMisses--; p.isDisqualified = false; }
      }
      // self5Turn: TurnRecordも直前分を削除する（各投で即追加しているため）
      if (widget.match.type == MatchType.self5Turn && widget.match.currentSetRecord.turns.isNotEmpty) {
        widget.match.currentSetRecord.turns.removeLast();
      }
      selectedSkitels.clear();
    });
    // アンドゥ後に確実に入力待ち再開
    _resetElapsedTimer();
    _startAutoMic();
  }

  void _showSelf5TurnSuccessDialog() {
    final t = L10n.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text('${t.get('self5turn_challenge_n', args: {'n': '${widget.match.currentSetIndex}'})} ${t.get('self5turn_success')}'),
      content: Text(t.get('consecutive_success', args: {'n': '${widget.match.consecutiveSuccesses}'}),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      actions: [
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); _startNextChallenge(); },
          child: Text(t.get('next_challenge')),
        ),
      ],
    ));
  }

  void _showSelf5TurnFailureDialog() {
    final t = L10n.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text(t.get('self5turn_failure'), style: const TextStyle(fontSize: 20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.get('consecutive_success', args: {'n': '${widget.match.consecutiveSuccesses}'}),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ]),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(ctx); Navigator.popUntil(context, (r) => r.isFirst); },
          child: Text(t.get('back_to_top')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            final newPlayers = widget.match.players.map((p) => Player(id: p.id, name: p.name, initialOrder: p.initialOrder)).toList();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => GameScreen(
              appUserId: widget.appUserId,
              match: MolkkyMatch(players: newPlayers, limit: 99, type: MatchType.self5Turn),
              voiceEnabled: widget.voiceEnabled,
            )));
          },
          child: Text(t.get('next_challenge')),
        ),
      ],
    ));
  }

  void _startNextChallenge() {
    widget.match.prepareNextSet();
    setState(() {
      currentPlayerIndex = 0; currentTurnInSet = 1; isSetFinished = false;
      turnInProgressScores.clear(); systemCalculatedIds.clear(); selectedSkitels.clear();
    });
    _resetElapsedTimer();
    _startAutoMic();
  }

  Future<void> _uploadSelf5TurnData() async {
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
        'matchType': 'MatchType.self5Turn',
        'consecutiveSuccesses': match.consecutiveSuccesses,
        'players': match.players.map((p) => {'id': p.id, 'name': p.name}).toList(),
        'history': setsToUpload.map((s) => {
          'setNumber': s.setNumber,
          'turns': s.turns.map((t) => {'turnNumber': t.turnNumber, 'scores': t.scores}).toList(),
          'finalScores': s.finalCumulativeScores,
        }).toList(),
      };
      await FirebaseFirestore.instance.collection('scores').add(data);
    } catch (e) { debugPrint("Self5Turn Upload Error: $e"); }
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
    Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(
      match: widget.match,
      sets: allSets,
      isSelf5Turn: widget.match.type == MatchType.self5Turn,
      consecutiveSuccesses: widget.match.consecutiveSuccesses,
    )));
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
            _startAutoMic(); // 次のセット開始時に自動60秒モードで音声認識を再開
            _resetElapsedTimer();
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

  Widget _buildMicButton() {
    final active = _voiceActive;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _micHeld = true);
        if (!_speech.isListening) _startListening();
      },
      onTapUp: (_) {
        setState(() => _micHeld = false);
        if (!_autoMicActive) _speech.stop();
      },
      onTapCancel: () {
        setState(() => _micHeld = false);
        if (!_autoMicActive) _speech.stop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? Icons.mic : Icons.mic_off,
          size: 20,
          color: active ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

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

    final isSelf5Turn = widget.match.type == MatchType.self5Turn;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text(isSelf5Turn
            ? t.get('self5turn_challenge_n', args: {'n': '${widget.match.currentSetIndex}'})
            : t.get('set_n', args: {'n': '${widget.match.currentSetIndex}'})),
          const SizedBox(width: 8),
          if (_speechAvailable) _buildMicButton(),
        ]),
        actions: [TextButton.icon(onPressed: _goToHistory, icon: const Icon(Icons.list_alt, size: 18), label: Text(t.get('match_history')))]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (isSelf5Turn)
                  Text(t.get('consecutive_success', args: {'n': '${widget.match.consecutiveSuccesses}'}),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))
                else
                  _buildScoreSummaryRow(),
                const SizedBox(height: 6),
                RichText(text: TextSpan(style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: nameColor), children: [
                  TextSpan(text: '${currentPlayer.name} '),
                  TextSpan(text: '(${t.get('turn_n', args: {'n': '$currentTurnInSet'})})'),
                  TextSpan(text: missIcons, style: const TextStyle(color: Colors.red)),
                ])),
                if (reachMsg != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(reachMsg, style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold))),
                if (_speechAvailable && _speech.isListening && _voiceText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(_voiceText, style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
              ],
            )),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
            child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                columns: [DataColumn(label: SizedBox(width: 40, child: Text(t.get('turn_label')))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: 12, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text(t.get('points'), style: const TextStyle(fontSize: 9)), Text(t.get('total'), style: const TextStyle(fontSize: 9))])])))])],
                rows: List.generate(currentTurnInSet, (i) {
                  int turn = currentTurnInSet - i;
                  final isCurrent = i == 0;
                  return DataRow(
                    color: isCurrent ? WidgetStateProperty.all(const Color(0xFFFFF9C4)) : null,
                    cells: [DataCell(Center(child: Text('$turn'))), ...widget.match.players.expand((p) {
                      int score = 0, total = 0;
                      bool hasScore = p.scoreHistory.length >= turn;
                      if (hasScore) { score = p.scoreHistory[turn - 1]; int tmp = 0; for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > 50) tmp = 25; } total = tmp; }
                      final fontSize = isCurrent ? 17.0 : 15.0;
                      return [DataCell(Row(children: [
                        Container(width: 40, alignment: Alignment.center, child: Text(hasScore ? '$score' : '', style: TextStyle(fontSize: fontSize))),
                        Container(width: 40, alignment: Alignment.center, color: const Color(0xFFE3F2FD), child: Text(hasScore ? '$total' : '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)))]))];
                    })]);
                }),
              ),
            ))),
          ),
          Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 32), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(children: [
              LayoutBuilder(builder: (_, gc) {
                // 点数ボタングリッドの高さを画面の40%に制限（横長画面対策）
                final maxGridH = MediaQuery.of(context).size.height * 0.4;
                final cellH = (maxGridH - 8.0 * 2) / 3;
                final cellW = (gc.maxWidth - 8.0 * 3) / 4;
                final aspectRatio = (cellW / cellH).clamp(2.0, double.infinity);
                return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: aspectRatio), itemCount: 12, itemBuilder: (c, i) {
                  final num = i + 1; final isSelected = selectedSkitels.contains(num);
                  return GestureDetector(
                    onDoubleTap: () {
                      if (isSetFinished) return;
                      setState(() => selectedSkitels = [num]);
                      _submitThrow();
                    },
                    child: ElevatedButton(onPressed: () => _onSkitelTap(num), style: ElevatedButton.styleFrom(backgroundColor: isSelected ? const Color(0xFFFFF3E0) : Colors.white, foregroundColor: Colors.black, side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('$num', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  );
                });
              }),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: OutlinedButton(onPressed: _undo, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 4)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.undo, size: 16), Text(' ${t.get('undo')}', style: const TextStyle(fontSize: 13))]))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: _submitThrow, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline), Text(selectedSkitels.isEmpty ? ' 0 ${t.get('pts')} (${t.get('miss')})' : ' ${t.get('confirm')} (${selectedSkitels.length == 1 ? selectedSkitels.first : selectedSkitels.length} ${t.get('pts')})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _resetElapsedTimer,
                  child: SizedBox(
                    width: 52,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$_elapsedSeconds', style: TextStyle(fontSize: 28, fontFamily: 'Courier', fontWeight: FontWeight.bold, color: _elapsedSeconds >= 60 ? Colors.red : Colors.black87, letterSpacing: 1)),
                      const Text('sec', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ),
                ),
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
  final String? winnerName;
  final bool isSelf5Turn;
  final int consecutiveSuccesses;
  const HistoryPage({super.key, this.match, required this.sets, this.startTime, this.players, this.winnerName, this.isSelf5Turn = false, this.consecutiveSuccesses = 0});

  Map<String, int> _finalSetWins(List<Player> allPlayers) {
    final wins = <String, int>{for (var p in allPlayers) p.id: 0};

    for (final set in sets) {
      String? winnerId;
      // モルックの勝利条件は50点ちょうど。サバイバー自動完了も50点に設定されるため、
      // 最高スコアではなく50点のプレイヤーを勝者とする。
      for (final p in allPlayers) {
        if ((set.finalCumulativeScores[p.id] ?? 0) == 50) {
          winnerId = p.id;
          break;
        }
      }
      // フォールバック：50点のプレイヤーがいない場合（進行中セット表示時など）は最高スコアで判定
      if (winnerId == null) {
        int best = -1;
        for (final p in allPlayers) {
          final score = set.finalCumulativeScores[p.id] ?? 0;
          if (score > best) { best = score; winnerId = p.id; }
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

  String _resolveWinnerName(List<Player> allPlayers, Map<String, int> totals, Map<String, int> wins) {
    if (winnerName != null && winnerName!.trim().isNotEmpty && winnerName != 'None') return winnerName!;
    if (match?.matchWinner != null) return match!.matchWinner!.name;

    final sorted = List<Player>.from(allPlayers);
    sorted.sort((a, b) {
      final setCmp = (wins[b.id] ?? 0).compareTo(wins[a.id] ?? 0);
      if (setCmp != 0) return setCmp;
      final totalCmp = (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0);
      if (totalCmp != 0) return totalCmp;
      return a.initialOrder.compareTo(b.initialOrder);
    });
    return sorted.isNotEmpty ? sorted.first.name : '???';
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
        if (isSelf5Turn)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFE3F2FD),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.get('self5turn_mode'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(t.get('consecutive_success', args: {'n': '$consecutiveSuccesses'}),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ]),
          )
        else
          Builder(builder: (context) {
            final wins = _finalSetWins(allPlayers);
            final totals = _finalTotals(allPlayers);
            final winner = _resolveWinnerName(allPlayers, totals, wins);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: const Color(0xFFE3F2FD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Winner : $winner', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _buildHistoryTotalScore(allPlayers, totals, wins),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        for (var set in sets) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFE3F2FD),
            child: Text(
              isSelf5Turn
                ? t.get('self5turn_challenge_n', args: {'n': '${set.setNumber}'})
                : t.get('set_n', args: {'n': '${set.setNumber}'}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class GlobalHistoryPage extends StatefulWidget {
  final String uid;
  const GlobalHistoryPage({super.key, required this.uid});
  @override
  State<GlobalHistoryPage> createState() => _GlobalHistoryPageState();
}

class _GlobalHistoryPageState extends State<GlobalHistoryPage> {
  String _filter = 'all'; // 'all', 'normal', 'self5Turn'

  static bool _isSelf5TurnRecord(Map<String, dynamic> data) =>
      data['matchType'] == 'MatchType.self5Turn';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.get('match_history'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scores').where('appUserId', isEqualTo: widget.uid).orderBy('startTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains("FAILED_PRECONDITION") || error.contains("index")) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(t.get('loading_history'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
            return Center(child: Text(t.get('error', args: {'msg': error})));
          }
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allDocs = snapshot.data!.docs;
          if (allDocs.isEmpty) return Center(child: Text(t.get('no_history')));

          final hasSelf5Turn = allDocs.any((d) => _isSelf5TurnRecord(d.data() as Map<String, dynamic>));
          final hasNormal = allDocs.any((d) => !_isSelf5TurnRecord(d.data() as Map<String, dynamic>));
          final showFilter = hasSelf5Turn && hasNormal;

          final docs = showFilter && _filter != 'all'
              ? allDocs.where((d) {
                  final isSelf = _isSelf5TurnRecord(d.data() as Map<String, dynamic>);
                  return _filter == 'self5Turn' ? isSelf : !isSelf;
                }).toList()
              : allDocs;

          return Column(children: [
            if (showFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _filter,
                  decoration: const InputDecoration(labelText: 'フィルター', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('すべて')),
                    DropdownMenuItem(value: 'normal', child: Text('通常試合')),
                    DropdownMenuItem(value: 'self5Turn', child: Text('セルフ5ターン')),
                  ],
                  onChanged: (v) => setState(() => _filter = v!),
                ),
              ),
            Expanded(child: ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final start = (data['startTime'] as Timestamp).toDate();
              final playerNames = (data['players'] as List).map((p) => p['name']).join(", ");
              if (_isSelf5TurnRecord(data)) {
                final streak = data['consecutiveSuccesses'] ?? 0;
                return ListTile(
                  leading: const Icon(Icons.flag, color: Colors.green),
                  title: Text("${DateFormat('MM/dd HH:mm').format(start)} ${t.get('self5turn_mode')}"),
                  subtitle: Text("${t.get('consecutive_success', args: {'n': '$streak'})} / $playerNames"),
                  onTap: () => _viewDetail(context, data, start),
                );
              }
              final winner = data['winner'] ?? "???";
              return ListTile(leading: const Icon(Icons.cloud_done, color: Colors.blue), title: Text("${DateFormat('MM/dd HH:mm').format(start)} Win: $winner"), subtitle: Text("Players: $playerNames"), onTap: () => _viewDetail(context, data, start));
            })),
          ]);
        },
      ),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> data, DateTime start) {
    final t = L10n.of(context);
    try {
      final List<Player> players = (data['players'] as List).map((p) => Player(id: p['id'], name: p['name'], initialOrder: 0)).toList();
      final isSelf5Turn = _isSelf5TurnRecord(data);
      final consecutiveSuccesses = data['consecutiveSuccesses'] as int? ?? 0;
      final List<SetRecord> sets = (data['history'] as List).map((s) {
        final playerOrder = isSelf5Turn ? players.map((p) => p.id).toList() : List<String>.from(s['playerOrder'] ?? []);
        final starterId = isSelf5Turn ? players.first.id : (s['starterId'] ?? '');
        final set = SetRecord(s['setNumber'], starterId, playerOrder);
        (s['turns'] as List).forEach((t) => set.turns.add(TurnRecord(t['turnNumber'], Map<String, int>.from(t['scores']), systemCalculated: Set<String>.from(t['systemCalculated'] ?? []))));
        (s['finalScores'] as Map).forEach((k, v) => set.finalCumulativeScores[k] = v as int);
        return set;
      }).toList();
      Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(
        sets: sets, startTime: start, players: players,
        winnerName: isSelf5Turn ? null : data['winner'] as String?,
        isSelf5Turn: isSelf5Turn,
        consecutiveSuccesses: consecutiveSuccesses,
      )));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('error', args: {'msg': '$e'})))); }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HelpPage — 使い方ページ
// ─────────────────────────────────────────────────────────────────────────────

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpSection(
              title: '1. ゲームの準備',
              items: [
                'プレイヤー名を入力して「追加」→ 最大8人まで登録できます',
                'リストのハンドル（☰）をドラッグして投げ順を調整できます',
                '試合形式を選択します（例：2先 ＝ 2本先取）',
                '音声でスコアを入力したい場合は「音声入力」をONにしてください（試験中）',
                '「ゲーム開始」を押してスタート！',
              ],
            ),
            SizedBox(height: 20),
            _HelpSection(
              title: '2. スコアの入力',
              items: [
                '倒れたピンの番号（1〜12）をタップして選択',
                '複数のピンが倒れた場合は倒れた本数のボタンを1つタップ',
                '「決定」ボタンで確定',
                'ミスの場合は何も選ばずそのまま「0 Pts (ミス)」を押す',
                '間違えた場合は「戻る」で1つ前に戻れます',
              ],
            ),
            SizedBox(height: 20),
            _HelpSection(
              title: '3. 音声でスコアを入力する（音声入力ON時）',
              body: 'マイクに向かって話しかけるだけで自動的に入力されます。',
              examples: [
                '「投てき終了、12点」',
                '「入力、5点」',
                '「投てき終了、ミス」',
              ],
              note: '※ 音声入力がうまく認識されない場合はボタンで手動入力してください。',
            ),
            SizedBox(height: 20),
            _HelpSection(
              title: '4. 試合の進め方',
              items: [
                '誰かがちょうど50点を取るとそのセットが終了',
                'セット終了後に次のセットの投げ順を変更できます',
                '設定した試合形式（〇先など）で先に勝ち数に達した人が優勝',
              ],
            ),
            SizedBox(height: 20),
            _HelpSection(
              title: '5. 戦績を確認する',
              items: [
                '画面右上の「戦績確認」からこれまでの試合結果を見られます',
              ],
            ),
            SizedBox(height: 20),
            _HelpSection(
              title: '6. セルフ5ターン（1人用練習モード）',
              items: [
                'プレイヤーが1名の場合のみ「セルフ5ターン」モードが選べます',
                '5投で50点ちょうどに到達できれば「成功」',
                '6投以上になるか、5投で50点に届かない場合は「失敗」でゲーム終了',
                '何回連続で成功できるかを競います（連続成功記録を更新しましょう！）',
                '失敗後は「トップへ」でタイトル画面に戻るか「次のチャレンジへ」で新記録に挑戦',
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? body;
  final List<String> examples;
  final String? note;

  const _HelpSection({
    required this.title,
    this.items = const [],
    this.body,
    this.examples = const [],
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        if (body != null) ...[
          Text(body!, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],
        for (final item in items) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ],
        if (examples.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 4, left: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('話し方の例：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                for (final ex in examples)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(ex, style: const TextStyle(fontSize: 14)),
                  ),
              ],
            ),
          ),
        ],
        if (note != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ],
      ],
    );
  }
}
