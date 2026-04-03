
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
import 'package:google_sign_in/google_sign_in.dart';
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
      'voice_input': 'Voice Input (Beta)',
      'help_title': 'How to Play',
      'pts': 'pts',
      'hyakin_mode': 'Hyakin (表裏 2 sets)',
      'self5turn_fail_1': 'So close! Keep it up! 😤',
      'self5turn_fail_2_3': 'Not bad at all! 👍',
      'self5turn_fail_4_5': 'Seriously!? That\'s amazing! 🤩',
      'self5turn_fail_6_8': 'Incredible! I can\'t believe it! 😱',
      'self5turn_fail_9plus': 'Are you a pro?! The legendary {name}!! 🏆',
      'match_draw': '🤝 Draw!',
      'match_draw_detail': 'Same sets won and total score — it\'s a draw!',
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
      'voice_input': '音声入力（試験中）',
      'help_title': '使い方',
      'pts': '点',
      'hyakin_mode': '100均（表裏2セット）',
      'self5turn_fail_1': '惜しい！まだまだこれから！😤',
      'self5turn_fail_2_3': 'なかなかやりますね！👍',
      'self5turn_fail_4_5': 'マジで！？凄いです！🤩',
      'self5turn_fail_6_8': '凄いです！信じられません！😱',
      'self5turn_fail_9plus': 'プロですか？世界の{name}！！🏆',
      'match_draw': '🤝 引き分け！',
      'match_draw_detail': 'セット数・合計点数が同じため引き分けです！',
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
        if (locale != null && locale.languageCode.startsWith('en')) return const Locale('en');
        return const Locale('ja');
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
  bool _isGoogleLinked = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final isGoogle = currentUser.providerData.any((p) => p.providerId == 'google.com');
        setState(() {
          _firebaseUid = currentUser.uid;
          _isGoogleLinked = isGoogle;
        });
      } else {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        setState(() { _firebaseUid = userCredential.user!.uid; });
      }
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

  Future<void> _showGoogleSignInDialog() async {
    if (_isGoogleLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Googleアカウントと連携済みです')),
      );
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 22)),
            SizedBox(width: 8),
            Text('Googleアカウント連携'),
          ],
        ),
        content: const Text(
          'Googleアカウントでログインすると、これまでの戦歴がアカウントに紐づき、別端末や環境でログインした場合も保持されるようになります。\nログインされますか？',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Googleでログイン')),
        ],
      ),
    );
    if (result == true) {
      await _signInWithGoogle();
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // 匿名ログインが未完了の場合は先に完了させる
      var currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        currentUser = cred.user!;
        setState(() => _firebaseUid = cred.user!.uid);
      }
      final oldUid = currentUser.uid;

      if (kIsWeb) {
        await _signInWithGoogleWeb(currentUser, oldUid);
      } else {
        await _signInWithGoogleMobile(currentUser, oldUid);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) _showError('Googleログインに失敗しました');
    }
  }

  Future<void> _signInWithGoogleWeb(User currentUser, String oldUid) async {
    final provider = GoogleAuthProvider();
    try {
      await currentUser.linkWithPopup(provider);
      setState(() => _isGoogleLinked = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleアカウントと連携しました！'), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        final credential = e.credential;
        if (credential == null) rethrow;

        // 1. まだ oldUid(匿名)として認証中のうちにデータを読み取る
        //    (サインイン後は appUserId != request.auth.uid となり permission-denied になるため)
        final oldData = await _fetchAllScoreData(oldUid);

        // 2. 既存のcredentialでGoogle認証に切り替え（2回目のポップアップ不要）
        final result = await FirebaseAuth.instance.signInWithCredential(credential);
        final newUid = result.user!.uid;

        // 3. newUidとして認証された状態で新規ドキュメントを作成
        if (oldUid != newUid && oldData.isNotEmpty) {
          await _writeScoreDataAsNewUid(oldData, newUid);
        }
        setState(() { _firebaseUid = newUid; _isGoogleLinked = true; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Googleアカウントでログインし、戦歴をマージしました！'), backgroundColor: Colors.green),
          );
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> _signInWithGoogleMobile(User currentUser, String oldUid) async {
    // Webでは使用しないためmobile専用としてここでインスタンス化
    final googleSignIn = GoogleSignIn(
      serverClientId: '52196197674-342o533f0npiujhr6u61nlkplko95laa.apps.googleusercontent.com',
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      final userCredential = await currentUser.linkWithCredential(credential);
      final newUid = userCredential.user!.uid;
      setState(() { _firebaseUid = newUid; _isGoogleLinked = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleアカウントと連携しました！'), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // 1. まだ oldUid(匿名)として認証中のうちにデータを読み取る
        final oldData = await _fetchAllScoreData(oldUid);

        // 2. Google認証に切り替え
        final result = await FirebaseAuth.instance.signInWithCredential(credential);
        final newUid = result.user!.uid;

        // 3. newUidとして認証された状態で新規ドキュメントを作成
        if (oldUid != newUid && oldData.isNotEmpty) {
          await _writeScoreDataAsNewUid(oldData, newUid);
        }
        setState(() { _firebaseUid = newUid; _isGoogleLinked = true; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Googleアカウントでログインし、戦歴をマージしました！'), backgroundColor: Colors.green),
          );
        }
      } else {
        rethrow;
      }
    }
  }

  /// oldUidに紐づく全スコアデータをFirestoreから読み取る。
  /// ※oldUidとして認証されている状態で呼ぶこと（サインイン前）。
  Future<List<Map<String, dynamic>>> _fetchAllScoreData(String uid) async {
    final List<Map<String, dynamic>> all = [];
    const batchSize = 500;
    while (true) {
      final snapshot = await FirebaseFirestore.instance
          .collection('scores')
          .where('appUserId', isEqualTo: uid)
          .limit(batchSize)
          .get();
      all.addAll(snapshot.docs.map((d) => d.data()));
      if (snapshot.docs.length < batchSize) break;
    }
    return all;
  }

  /// 読み取ったスコアデータをnewUidで新規ドキュメントとして書き込む。
  /// ※newUidとして認証された状態で呼ぶこと（サインイン後）。
  /// 旧ドキュメント(appUserId == oldUid)はFirestoreに残るが参照されなくなる。
  Future<void> _writeScoreDataAsNewUid(
    List<Map<String, dynamic>> data,
    String newUid,
  ) async {
    const batchSize = 500;
    for (int i = 0; i < data.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      for (final record in data.skip(i).take(batchSize)) {
        final ref = FirebaseFirestore.instance.collection('scores').doc();
        batch.set(ref, {...record, 'appUserId': newUid});
      }
      await batch.commit();
    }
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
      -2: t.get('hyakin_mode'),
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
          IconButton(
            icon: Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _isGoogleLinked ? Colors.green : const Color(0xFF4285F4),
              ),
            ),
            onPressed: _showGoogleSignInDialog,
            tooltip: _isGoogleLinked ? 'Google連携済み' : 'Googleアカウント連携',
          ),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpPage())), tooltip: t.get('help_title')),
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
              title: Text(t.get('voice_input'), style: const TextStyle(fontSize: 16)),
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
                } else if (_selectedModeKey == -2) {
                  match = MolkkyMatch(players: playersForMatch, limit: 2, type: MatchType.hyakin);
                } else {
                  MatchType type = [1, 2, 10].contains(_selectedModeKey) ? MatchType.fixedSets : MatchType.raceTo;
                  int limit = _selectedModeKey; if (type == MatchType.raceTo && _selectedModeKey != 11) limit = (_selectedModeKey / 2).ceil();
                  match = MolkkyMatch(players: playersForMatch, limit: limit, type: type);
                }
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameScreen(appUserId: _firebaseUid, match: match, voiceEnabled: _voiceInputEnabled, appLocale: Localizations.localeOf(context))));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
              child: Text(t.get('start_game'), style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _firebaseUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (c) => GlobalHistoryPage(uid: _firebaseUid))), icon: const Icon(Icons.cloud_done), label: Text(t.get('match_history')), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45))),
            const SizedBox(height: 10),
            if (_firebaseUid.isNotEmpty) Text(t.get('anonymous_id', args: {'id': _firebaseUid.substring(0, 8)}), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('v1.10.14', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
  final Locale? appLocale;
  const GameScreen({super.key, required this.match, required this.appUserId, this.voiceEnabled = false, this.appLocale});
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
  String? _localeId; // 利用可能なSTTロケールID
  String _voiceText = ''; // リアルタイム認識テキスト（デバッグ兼UX）
  String _lastInterimText = ''; // finalResultが空だった場合のフォールバック用

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
        // 'notListening' は listen() 直後にも発火するため除外。
        if (status == 'done' && !isSetFinished && _voiceActive) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _voiceActive && !_speech.isListening) _startListening();
          });
        }
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        if (!mounted) return;
        setState(() {});
        if (!isSetFinished && _voiceActive) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _voiceActive && !_speech.isListening) _startListening();
          });
        }
      },
    );
    if (_speechAvailable) {
      // 利用可能なロケールからアプリ言語に合うものを探す
      // Webではlocales()が空リストを返すことがあるため安全に処理する
      try {
        final locales = await _speech.locales();
        if (locales.isNotEmpty) {
          final langCode = widget.appLocale?.languageCode ?? 'ja';
          final matched = locales.firstWhere(
            (l) => l.localeId.startsWith(langCode),
            orElse: () => locales.first,
          );
          _localeId = matched.localeId;
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
    // stop してから再スタート（前セッションのクリーンリセット）
    _speech.stop();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _voiceActive && !_speech.isListening) _startListening();
    });
  }

  void _resetElapsedTimer() {
    _elapsedTimer?.cancel();
    setState(() => _elapsedSeconds = 0);
    if (isSetFinished) return;
    // _startAutoMic の呼び出しは呼び出し元に任せる（二重呼び出し防止）
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _elapsedTimer?.cancel(); return; }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds == 60) {
        SystemSound.play(SystemSoundType.alert);
      }
      // ハートビート: pauseFor 経過直後に isListening=false になる窓でのセッション破壊を防ぐため
      // 経過秒が5の倍数のときのみ再起動を試みる（1秒周期より干渉リスクを大幅低減）
      if (_voiceActive && !_speech.isListening && !isSetFinished && _elapsedSeconds % 5 == 0) {
        _startListening();
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

        // 途中結果: フォールバックタイマー（finalResultが遅い端末への保険）
        _speechConfirmTimer?.cancel();
        if (!result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _lastInterimText = result.recognizedWords; // finalResult空時のフォールバック用に保存
          _speechConfirmTimer = Timer(const Duration(milliseconds: 800), () {
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
          // finalResultのテキストが空の場合は直前のinterim結果をフォールバックとして使う
          // （STTが認識済みテキストを空でfinalizeする端末への対応）
          final finalText = result.recognizedWords.trim().isNotEmpty
              ? result.recognizedWords
              : _lastInterimText;
          _lastInterimText = '';
          _processVoiceInput(finalText);
          setState(() => _voiceText = '');
        }
      },
      localeId: _localeId ?? (widget.appLocale?.languageCode == 'en' ? 'en-US' : 'ja-JP'),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(milliseconds: 1500),
    );
  }

  /// 音声入力を解析してスコアを適用する。スコアを確定した場合 true を返す
  bool _processVoiceInput(String text) {
    if (isSetFinished) return false;

    // 音声Undo検出（日本語のみ）
    if ((widget.appLocale?.languageCode ?? 'ja') == 'ja') {
      final n = text.replaceAll(RegExp(r'[、。,.\s　]'), '');
      if (n.contains('戻る') || n.contains('戻って') || n.contains('戻り') ||
          n.contains('取り消し') || n.contains('とりけし')) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎤 $text'),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.orange.shade700,
        ));
        _undo();
        return true;
      }
    }

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
      'スコア',   // ウェイクワード追加
      '入力',   // 「入力10点」など
      '終了',   // 「終了2点」など短い発話にも対応
    ]) {
      final idx = normalized.indexOf(w);
      if (idx >= 0) return idx + w.length;
    }
    // English wake words (case-insensitive, spaces already removed)
    final normalizedLower = normalized.toLowerCase();
    for (final w in ['done', 'score', 'enter', 'input', 'finish']) {
      final idx = normalizedLower.indexOf(w);
      if (idx >= 0) return idx + w.length;
    }
    return -1;
  }

  /// 日本語音声テキストをひらがな読みに正規化する
  /// カタカナ→ひらがな変換後、同音異義語・漢字をひらがなに展開する
  /// これにより _parseVoiceScore の照合を単純なひらがなマッチに統一できる
  String _normalizeJaPhonetic(String text) {
    // 句読点・空白を除去
    var s = text.replaceAll(RegExp(r'[、。,.\s　]'), '');
    // 全角数字→半角数字
    s = s.replaceAllMapped(RegExp(r'[０-９]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0xFF10 + 0x30));
    // カタカナ→ひらがな（U+30A1–U+30F6 の範囲; 長音符「ー」は対象外）
    s = s.replaceAllMapped(RegExp(r'[\u30A1-\u30F6]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x60));
    // 同音異義語フレーズ・漢字数字をひらがなに変換（長いものを先に処理）
    const map = [
      // 長音符を含むパターン（カタカナ→ひらがな変換後に対処）
      ('じゅてーむ', 'じゅうてん'),       // ジュテーム (je t'aime)
      // 同音異義語フレーズ
      ('銃に店', 'じゅうにてん'), ('銃に', 'じゅうにてん'),
      ('獣医点', 'じゅういちてん'), ('10移転', 'じゅういちてん'),
      ('住人', 'じゅうにてん'),
      ('発展', 'はってん'), ('鉢店', 'はちてん'),
      ('御殿', 'ごてん'),
      ('休店', 'きゅうてん'), ('急転', 'きゅうてん'),
      ('位置点', 'いちてん'), ('移転', 'いちてん'),
      // 英語音声の同音漢字
      ('刷り', 'すりー'),
      ('湾', 'わん'), ('通', 'つう'),
      // 複合パターン（個別漢字変換より先に処理）
      ('獣医', 'じゅういち'),
      ('銃位置', 'じゅういち'),
      ('住に', 'じゅうに'), ('獣に', 'じゅうに'),
      ('重に', 'じゅうに'), ('柔に', 'じゅうに'),
      ('奈々', 'なな'), ('菜々', 'なな'),
      // 個別漢字（数字の同音異義語・長い複合は上で処理済み）
      // 1 = いち
      ('壱', 'いち'), ('位置', 'いち'),
      // 2 = に
      ('弐', 'に'), ('仁', 'に'), ('煮', 'に'), ('尼', 'に'), ('似', 'に'), ('荷', 'に'),
      // 3 = さん
      ('酸', 'さん'), ('産', 'さん'),
      ('山', 'さん'), ('参', 'さん'), ('散', 'さん'), ('算', 'さん'), ('賛', 'さん'),
      // 4 = し
      ('死', 'し'),
      // 5 = ご
      ('誤', 'ご'), ('語', 'ご'), ('碁', 'ご'), ('御', 'ご'), ('護', 'ご'),
      // 6 = ろく
      ('禄', 'ろく'), ('録', 'ろく'),
      // 8 = はち
      ('蜂', 'はち'), ('鉢', 'はち'),
      // 9 = きゅう
      ('球', 'きゅう'), ('究', 'きゅう'), ('級', 'きゅう'), ('給', 'きゅう'),
      ('救', 'きゅう'), ('宮', 'きゅう'), ('求', 'きゅう'), ('弓', 'きゅう'),
      ('旧', 'きゅう'), ('急', 'きゅう'),
      // 10 = じゅう
      ('重', 'じゅう'), ('銃', 'じゅう'), ('住', 'じゅう'), ('獣', 'じゅう'),
      ('充', 'じゅう'), ('柔', 'じゅう'), ('縦', 'じゅう'),
      // 漢字数字（長い順）
      ('十二', 'じゅうに'), ('十一', 'じゅういち'), ('十', 'じゅう'),
      ('九', 'きゅう'), ('八', 'はち'), ('七', 'なな'),
      ('六', 'ろく'), ('五', 'ご'), ('四', 'よん'),
      ('三', 'さん'), ('二', 'に'), ('一', 'いち'),
      // 点数サフィックス（漢字・ひらがな）
      // ※ カタカナ→ひらがな変換後にこのテーブルが適用されるため
      //   ポイント→ぽいんと に変換済みのひらがな表記で照合する
      ('ぽいんと', 'てん'), ('ぽいん', 'てん'),
      ('点', 'てん'), ('店', 'てん'), ('手', 'てん'), ('転', 'てん'),
      // ミス関連漢字
      ('零', 'れい'), ('霊', 'れい'),
    ];
    for (final (from, to) in map) {
      s = s.replaceAll(from, to);
    }
    // 英語単語の大文字小文字を統一（STTが "One" や "TWO" と返す場合に対応）
    s = s.toLowerCase();
    return s;
  }

  /// テキストから点数を解析する。
  /// ロケールが日本語の場合はウェイクワード不要。英語版はウェイクワード必須のまま。
  /// 戻り値: 1〜12=ピン番号、-1=ミス、null=認識失敗
  int? _parseVoiceScore(String text) {
    final isJa = (widget.appLocale?.languageCode ?? 'ja') == 'ja';
    final normalized = text.replaceAll(RegExp(r'[、。,.\s　]'), '');

    if (!isJa) {
      // === 英語パス: ウェイクワード必須（変更なし） ===
      final wakeEnd = _wakeWordEnd(text);
      if (wakeEnd < 0) return null;
      final afterWake = normalized.substring(wakeEnd).toLowerCase();
      if (afterWake.isEmpty) return null;
      if (afterWake.contains('miss')) return -1;
      final digitMatch = RegExp(r'(\d+)').firstMatch(afterWake);
      if (digitMatch != null) {
        final n = int.tryParse(digitMatch.group(1)!);
        if (n != null && n >= 1 && n <= 12) return n;
      }
      const enMap = <String, int>{
        'twelve': 12, 'eleven': 11, 'ten': 10,
        'nine': 9, 'eight': 8, 'seven': 7, 'six': 6, 'five': 5,
        'four': 4, 'three': 3, 'two': 2, 'one': 1,
      };
      for (final entry in enMap.entries) {
        if (RegExp(r'\b' + entry.key + r'\b').hasMatch(afterWake)) return entry.value;
      }
      return null;
    }

    // === 日本語パス: ウェイクワード不要 ===
    // 先にひらがなへ正規化することで漢字・カタカナ・同音異義語を統一処理できる
    final ja = _normalizeJaPhonetic(text);

    // 1. アラビア数字 + てん (1-12)
    //    正規化後はサフィックスが全て「てん」に統一されている
    final digitMatch = RegExp(r'([0-9]{1,2})てん').firstMatch(ja);
    if (digitMatch != null) {
      final n = int.tryParse(digitMatch.group(1)!);
      if (n != null && n >= 1 && n <= 12) return n;
    }

    // 2. ひらがな数字 + てん（長いパターンを先に照合して部分一致を防ぐ）
    const jpScoreList = <(String, int)>[
      ('じゅうに', 12), ('じゅういち', 11),
      ('じゅっ', 10), ('じゅう', 10),
      ('きゅう', 9), ('はっ', 8), ('はち', 8),
      ('なな', 7), ('しち', 7), ('ろく', 6), ('ご', 5),
      ('よん', 4), ('よっ', 4), ('さん', 3), ('に', 2),
      ('いっ', 1), ('いち', 1),
    ];
    for (final (jp, score) in jpScoreList) {
      if (ja.contains('${jp}てん')) return score;
    }

    // 3. 裸のアラビア数字 1-12（STTが「点」を省略した場合のフォールバック）
    //    例: STT が「10点」→「10」と返した場合にもスコアとして認識する
    final bareMatch = RegExp(r'^([0-9]{1,2})$').firstMatch(ja);
    if (bareMatch != null) {
      final n = int.tryParse(bareMatch.group(1)!);
      if (n != null && n >= 1 && n <= 12) return n;
    }

    // 4. 単体読み・英語数字（STTが「点」を省略、または英語で発話した場合）
    //    正規化後の文字列が完全一致する場合のみスコアとして認識する
    const standaloneMap = <String, int>{
      'いち': 1, 'one': 1, 'わん': 1,
      'に': 2, 'two': 2, 'つー': 2, 'つう': 2,
      'さん': 3, 'three': 3, 'すりー': 3,
      'よん': 4, 'し': 4, 'four': 4, 'ふぉー': 4,
      'ご': 5, 'five': 5, 'ふぁいぶ': 5,
      'ろく': 6, 'six': 6, 'しっくす': 6,
      'なな': 7, 'しち': 7, 'seven': 7, 'せぶん': 7,
      'はち': 8, 'eight': 8, 'えいと': 8,
      'きゅう': 9, 'きゅー': 9, 'nine': 9, 'ないん': 9, 'q': 9,
      'じゅう': 10, 'ten': 10,  // 'てん' は除外: 数字接尾辞と衝突するため
      'じゅういち': 11, 'eleven': 11, 'いれぶん': 11,
      'じゅうに': 12, 'twelve': 12, 'とぅえるぶ': 12,
    };
    if (standaloneMap.containsKey(ja)) return standaloneMap[ja]!;

    // 5. ミス判定（スコアチェック後; 「10てん」→「0」誤マッチを防ぐ）
    if (ja.contains('ふぉると') ||
        RegExp(r'(?<![0-9])0てん').hasMatch(ja) ||
        ja.contains('ぜろてん') || ja.contains('れいてん')) {
      return -1;
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
      // === Hyakin Set 2 mode: custom throw processing (must run before normal processThrow) ===
      if (widget.match.type == MatchType.hyakin && widget.match.currentSetIndex == 2) {
        final set1Score = player.setFinalScores.isNotEmpty ? player.setFinalScores[0] : 0;
        GameLogic.processHyakinSet2Throw(player, selectedSkitels, widget.match, set1Score);
        int hyakinPoints = player.scoreHistory.last;
        player.matchScoreHistory.add(hyakinPoints);
        turnInProgressScores[player.id] = hyakinPoints;

        // Survivor logic for hyakin Set 2
        final survivors2 = widget.match.players.where((p) => !p.isDisqualified).toList();
        if (widget.match.players.length >= 2 && survivors2.length == 1) {
          final s = survivors2.first;
          final sSet1 = s.setFinalScores.isNotEmpty ? s.setFinalScores[0] : 0;
          final sTarget = 100 - sSet1;
          int needed = sTarget - s.currentScore;
          s.currentScore = sTarget;
          s.scoreHistory.add(needed);
          s.matchScoreHistory.add(needed);
          turnInProgressScores[s.id] = needed;
          systemCalculatedIds.add(s.id);
          for (var p in widget.match.players) if (p.isDisqualified) p.currentScore = 0;
        }

        // Winner check: anyone who reached their personal target (100 - set1Score)
        Player? hyakinWinner;
        for (var p in widget.match.players) {
          final pSet1 = p.setFinalScores.isNotEmpty ? p.setFinalScores[0] : 0;
          if (p.currentScore == 100 - pSet1) { hyakinWinner = p; break; }
        }

        if (hyakinWinner != null) {
          isSetFinished = true;
          hyakinWinner.setsWon++;
          widget.match.currentSetRecord.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
          widget.match.finalizeCurrentSetIfNeeded();
          final finalWinner = widget.match.matchWinner ?? hyakinWinner;
          _uploadMatchData(finalWinner);
          _showMatchWinnerDialog(finalWinner);
        } else {
          if (currentPlayerIndex == widget.match.players.length - 1) {
            widget.match.currentSetRecord.turns.add(TurnRecord(currentTurnInSet, Map.from(turnInProgressScores), systemCalculated: Set.from(systemCalculatedIds)));
            turnInProgressScores.clear(); systemCalculatedIds.clear();
          }
          selectedSkitels.clear(); _nextPlayer();
        }
        return; // skip normal logic
      }
      // === End Hyakin Set 2 mode ===

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
           if (widget.match.isMatchDraw) {
             _uploadMatchData(null);
             _showMatchDrawDialog();
           } else {
             final finalWinner = widget.match.matchWinner ?? winner;
             _uploadMatchData(finalWinner);
             _showMatchWinnerDialog(finalWinner);
           }
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
    final n = widget.match.consecutiveSuccesses;
    final playerName = widget.match.players.isNotEmpty ? widget.match.players.first.name : '';
    String resultMsg;
    if (n == 0) {
      resultMsg = t.get('self5turn_failure');
    } else if (n == 1) {
      resultMsg = t.get('self5turn_fail_1');
    } else if (n <= 3) {
      resultMsg = t.get('self5turn_fail_2_3');
    } else if (n <= 5) {
      resultMsg = t.get('self5turn_fail_4_5');
    } else if (n <= 8) {
      resultMsg = t.get('self5turn_fail_6_8');
    } else {
      resultMsg = t.get('self5turn_fail_9plus', args: {'name': playerName});
    }
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text(resultMsg, style: const TextStyle(fontSize: 20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.get('consecutive_success', args: {'n': '$n'}),
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

  Future<void> _uploadMatchData(Player? finalWinner) async {
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
        'winner': finalWinner?.name ?? 'DRAW',
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
    String? resolvedWinnerName;
    if (widget.match.isMatchOver) {
      resolvedWinnerName = widget.match.isMatchDraw ? 'DRAW' : widget.match.matchWinner?.name;
    }
    Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(
      match: widget.match,
      sets: allSets,
      isSelf5Turn: widget.match.type == MatchType.self5Turn,
      isHyakin: widget.match.type == MatchType.hyakin,
      consecutiveSuccesses: widget.match.consecutiveSuccesses,
      winnerName: resolvedWinnerName,
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

  void _showMatchDrawDialog() {
    final t = L10n.of(context);
    final int finishedSetNum = widget.match.currentSetIndex;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text('${t.get('set_n', args: {'n': '$finishedSetNum'})} - ${t.get('match_over')}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.get('match_draw'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(t.get('match_draw_detail'), style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ]),
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
        if (!_autoMicActive) {
          // 60秒タイムアウト後のタップ → 自動マイクを再起動
          _startAutoMic();
          _resetElapsedTimer();
        } else if (!_speech.isListening) {
          _startListening();
        }
      },
      onTapUp: (_) {
        setState(() => _micHeld = false);
        // _autoMicActive が true（再開直後含む）なら止めない
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
    final isHyakinSet2 = widget.match.type == MatchType.hyakin && widget.match.currentSetIndex == 2;

    const color = Color(0xFF39FF14);
    const bigStyle = TextStyle(fontSize: 40, fontWeight: FontWeight.w800, fontFamily: 'Courier', color: color, letterSpacing: 1.5);
    const smallStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Courier', color: color, letterSpacing: 1.0);
    const sepStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Courier', color: color);

    List<InlineSpan> spans;
    if (isHyakinSet2) {
      spans = [];
      for (int i = 0; i < players.length; i++) {
        final p = players[i];
        final s1 = p.setFinalScores.isNotEmpty ? p.setFinalScores[0] : 0;
        if (players.length > 2) spans.add(TextSpan(text: '${p.name} ', style: smallStyle));
        spans.add(TextSpan(text: '${s1 + p.currentScore}', style: bigStyle));
        if (_stars(p.setsWon).isNotEmpty) spans.add(TextSpan(text: _stars(p.setsWon), style: smallStyle));
        if (i < players.length - 1) spans.add(TextSpan(text: ' - ', style: sepStyle));
      }
    } else {
      final showTotal = widget.match.currentSetIndex > 1;
      spans = [];
      for (int i = 0; i < players.length; i++) {
        final p = players[i];
        if (players.length > 2) spans.add(TextSpan(text: '${p.name} ', style: smallStyle));
        spans.add(TextSpan(text: '${p.currentScore}', style: bigStyle));
        if (showTotal) spans.add(TextSpan(text: '(${_runningTotal(p)})', style: smallStyle));
        if (_stars(p.setsWon).isNotEmpty) spans.add(TextSpan(text: _stars(p.setsWon), style: smallStyle));
        if (i < players.length - 1) spans.add(TextSpan(text: ' - ', style: sepStyle));
      }
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF2E2E2E),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: RichText(
          text: TextSpan(children: spans),
        ),
      ),
    );
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
    if (!isSetFinished) {
      if (widget.match.type == MatchType.hyakin && widget.match.currentSetIndex == 2) {
        final set1 = currentPlayer.setFinalScores.isNotEmpty ? currentPlayer.setFinalScores[0] : 0;
        final remaining = (100 - set1) - currentPlayer.currentScore;
        if (remaining <= 12 && remaining > 0) {
          reachMsg = t.get('reach_msg', args: {'name': currentPlayer.name, 'n': '$remaining'});
        }
      } else if (currentPlayer.currentScore >= 38) {
        reachMsg = t.get('reach_msg', args: {'name': currentPlayer.name, 'n': '${50 - currentPlayer.currentScore}'});
      }
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
          if (!isSelf5Turn) _buildScoreSummaryRow(),
          Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue[100]!), borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (isSelf5Turn)
                  Text(t.get('consecutive_success', args: {'n': '${widget.match.consecutiveSuccesses}'}),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
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
          Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
            const turnColW = 44.0;
            const dtHMargin = 24.0;   // DataTable のデフォルト horizontalMargin
            const containerMargin = 16.0; // Container margin: 8px × 2
            const colSpacing = 10.0;
            final numPlayers = widget.match.players.length;
            // DataTable 実幅 = dtHMargin*2 + turnColW + colSpacing*numPlayers + playerColW*numPlayers
            // 利用可能幅 = constraints.maxWidth - containerMargin
            final available = constraints.maxWidth - containerMargin;
            final playerColW = ((available - 2 * dtHMargin - turnColW - colSpacing * numPlayers) / numPlayers).clamp(60.0, 200.0);
            final cellW = (playerColW / 2).floorToDouble();
            final headerNameSize = (cellW * 0.14).clamp(9.0, 13.0);
            final headerSubSize = (cellW * 0.11).clamp(8.0, 10.0);
            return Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
              child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: DataTable(columnSpacing: 10, headingRowHeight: 40, dataRowMinHeight: 30, dataRowMaxHeight: 40, border: TableBorder.all(color: Colors.grey[300]!), headingRowColor: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                  columns: [DataColumn(label: SizedBox(width: turnColW, child: Text(t.get('turn_label')))), ...widget.match.players.expand((p) => [DataColumn(label: Container(width: playerColW, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(p.name, style: TextStyle(fontSize: headerNameSize, color: p == currentPlayer ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text(t.get('points'), style: TextStyle(fontSize: headerSubSize)), Text(t.get('total'), style: TextStyle(fontSize: headerSubSize))])])))])],
                  rows: List.generate(currentTurnInSet, (i) {
                    int turn = currentTurnInSet - i;
                    final isCurrent = i == 0;
                    return DataRow(
                      color: isCurrent ? WidgetStateProperty.all(const Color(0xFFFFF9C4)) : null,
                      cells: [DataCell(Center(child: Text('$turn'))), ...widget.match.players.expand((p) {
                        int score = 0, total = 0;
                        bool hasScore = p.scoreHistory.length >= turn;
                        final isHyakinSet2 = widget.match.type == MatchType.hyakin && widget.match.currentSetIndex == 2;
                        if (hasScore) {
                          score = p.scoreHistory[turn - 1];
                          if (isHyakinSet2) {
                            final pSet1 = p.setFinalScores.isNotEmpty ? p.setFinalScores[0] : 0;
                            final pTarget = 100 - pSet1;
                            final pBurst = 75 - pSet1;
                            int tmp = 0; for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > pTarget) tmp = pBurst; }
                            total = pSet1 + tmp; // combined total (Set 1 + Set 2)
                          } else {
                            int tmp = 0; for (int k = 0; k < turn; k++) { tmp += p.scoreHistory[k]; if (tmp > 50) tmp = 25; }
                            total = tmp;
                          }
                        }
                        final fontSize = (cellW * 0.35).clamp(11.0, isCurrent ? 17.0 : 15.0);
                        return [DataCell(Row(children: [
                          Container(width: cellW, alignment: Alignment.center, child: Text(hasScore ? '$score' : '', style: TextStyle(fontSize: fontSize))),
                          Container(width: cellW, alignment: Alignment.center, color: const Color(0xFFE3F2FD), child: Text(hasScore ? '$total' : '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)))]))];
                      })]);
                  }),
                ),
              )));
          })),
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
                  onTap: () {
                    // タイムアウト後でも確実に音声待ち受けを再開する
                    _startAutoMic();
                    _resetElapsedTimer();
                  },
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
  final bool isHyakin;
  const HistoryPage({super.key, this.match, required this.sets, this.startTime, this.players, this.winnerName, this.isSelf5Turn = false, this.consecutiveSuccesses = 0, this.isHyakin = false});

  Map<String, int> _finalSetWins(List<Player> allPlayers) {
    final wins = <String, int>{for (var p in allPlayers) p.id: 0};

    for (final set in sets) {
      String? winnerId;
      // 100均モードのSet2: 合計(set1+set2)==100 で勝利
      if (isHyakin && set.setNumber == 2 && sets.length >= 2) {
        final set1 = sets.firstWhere((s) => s.setNumber == 1, orElse: () => set);
        for (final p in allPlayers) {
          final s1 = set1.finalCumulativeScores[p.id] ?? 0;
          final s2 = set.finalCumulativeScores[p.id] ?? 0;
          if (s1 + s2 == 100) { winnerId = p.id; break; }
        }
      } else {
        // モルックの勝利条件は50点ちょうど。サバイバー自動完了も50点に設定されるため、
        // 最高スコアではなく50点のプレイヤーを勝者とする。
        for (final p in allPlayers) {
          if ((set.finalCumulativeScores[p.id] ?? 0) == 50) {
            winnerId = p.id;
            break;
          }
        }
      }
      // フォールバック：勝者が特定できない場合は最高スコアで判定
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

  String _resolveWinnerName(BuildContext context, List<Player> allPlayers, Map<String, int> totals, Map<String, int> wins) {
    if (winnerName == 'DRAW') return L10n.of(context).get('match_draw');
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
            final winner = _resolveWinnerName(context, allPlayers, totals, wins);
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
  String _self5TurnSort = 'date_desc'; // 'date_desc', 'date_asc', 'streak_desc'
  int _currentPage = 0;
  static const int _pageSize = 50;

  static bool _isSelf5TurnRecord(Map<String, dynamic> data) =>
      data['matchType'] == 'MatchType.self5Turn';

  void _setFilter(String v) => setState(() { _filter = v; _currentPage = 0; });
  void _setSort(String v) => setState(() { _self5TurnSort = v; _currentPage = 0; });

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
          final showingOnlySelf5Turn = _filter == 'self5Turn' || (!showFilter && hasSelf5Turn);

          // Filter
          var filtered = showFilter && _filter != 'all'
              ? allDocs.where((d) {
                  final isSelf = _isSelf5TurnRecord(d.data() as Map<String, dynamic>);
                  return _filter == 'self5Turn' ? isSelf : !isSelf;
                }).toList()
              : List.from(allDocs);

          // Sort for self5Turn view
          if (showingOnlySelf5Turn) {
            if (_self5TurnSort == 'date_asc') {
              filtered.sort((a, b) {
                final ta = (a.data() as Map)['startTime'] as Timestamp;
                final tb = (b.data() as Map)['startTime'] as Timestamp;
                return ta.compareTo(tb);
              });
            } else if (_self5TurnSort == 'streak_desc') {
              filtered.sort((a, b) {
                final sa = ((a.data() as Map)['consecutiveSuccesses'] as int?) ?? 0;
                final sb = ((b.data() as Map)['consecutiveSuccesses'] as int?) ?? 0;
                return sb.compareTo(sa);
              });
            }
            // date_desc: already ordered by Firestore (descending startTime)
          }

          // Pagination
          final totalDocs = filtered.length;
          final totalPages = (totalDocs / _pageSize).ceil().clamp(1, double.maxFinite).toInt();
          final safePage = _currentPage.clamp(0, totalPages - 1);
          final pageStart = safePage * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, totalDocs);
          final pageDocs = filtered.sublist(pageStart, pageEnd);

          return Column(children: [
            if (showFilter || showingOnlySelf5Turn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  if (showFilter)
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _filter,
                      decoration: const InputDecoration(labelText: 'フィルター', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('すべて')),
                        DropdownMenuItem(value: 'normal', child: Text('通常試合')),
                        DropdownMenuItem(value: 'self5Turn', child: Text('セルフ5ターン')),
                      ],
                      onChanged: (v) => _setFilter(v!),
                    )),
                  if (showFilter && showingOnlySelf5Turn) const SizedBox(width: 8),
                  if (showingOnlySelf5Turn)
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _self5TurnSort,
                      decoration: const InputDecoration(labelText: '並び替え', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('日付↓')),
                        DropdownMenuItem(value: 'date_asc', child: Text('日付↑')),
                        DropdownMenuItem(value: 'streak_desc', child: Text('連続↓')),
                      ],
                      onChanged: (v) => _setSort(v!),
                    )),
                ]),
              ),
            Expanded(child: ListView.builder(itemCount: pageDocs.length, itemBuilder: (context, index) {
              final data = pageDocs[index].data() as Map<String, dynamic>;
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
              final isDraw = winner == 'DRAW';
              return ListTile(
                leading: Icon(isDraw ? Icons.handshake : Icons.cloud_done, color: isDraw ? Colors.orange : Colors.blue),
                title: Text("${DateFormat('MM/dd HH:mm').format(start)} ${isDraw ? t.get('match_draw') : 'Win: $winner'}"),
                subtitle: Text("Players: $playerNames"),
                onTap: () => _viewDetail(context, data, start),
              );
            })),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: safePage > 0 ? () => setState(() => _currentPage = safePage - 1) : null),
                  Text('${safePage + 1} / $totalPages', style: const TextStyle(fontSize: 14)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: safePage < totalPages - 1 ? () => setState(() => _currentPage = safePage + 1) : null),
                ]),
              ),
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
      final isHyakin = data['matchType'] == 'MatchType.hyakin';
      Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryPage(
        sets: sets, startTime: start, players: players,
        winnerName: isSelf5Turn ? null : data['winner'] as String?,
        isSelf5Turn: isSelf5Turn,
        isHyakin: isHyakin,
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
    final t = L10n.of(context);
    final isJa = Localizations.localeOf(context).languageCode == 'ja';

    final sections = isJa ? _jaSections(t) : _enSections(t);

    return Scaffold(
      appBar: AppBar(title: Text(t.get('help_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              sections[i],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _jaSections(L10n t) => [
    const _HelpSection(
      title: '1. ゲームの準備',
      items: [
        'プレイヤー名を入力して「追加」→ 最大8人まで登録できます',
        'リストのハンドル（☰）をドラッグして投げ順を調整できます',
        '試合形式を選択します（例：2先 ＝ 2本先取）',
        '音声でスコアを入力したい場合は「音声入力」をONにしてください（試験中）',
        '「ゲーム開始」を押してスタート！',
      ],
    ),
    const _HelpSection(
      title: '2. スコアの入力',
      items: [
        '倒れたピンの番号（1〜12）をタップして選択',
        '複数のピンが倒れた場合は倒れた本数のボタンを1つタップ',
        '「決定」ボタンで確定',
        'ミスの場合は何も選ばずそのまま「0 Pts (ミス)」を押す',
        '間違えた場合は「戻る」で1つ前に戻れます',
      ],
    ),
    const _HelpSection(
      title: '3. 音声でスコアを入力する（音声入力ON時）',
      body: 'マイクに向かって得点を話しかけると自動的に入力されます。',
      examplesLabel: '例：',
      examples: [
        '「1点」〜「12点」',
        '「フォルト」（ミスの場合）',
        '「戻る」「取り消し」（直前の入力を取り消し）',
      ],
      note: '※ 音声入力がうまく認識されない場合はボタンで手動入力してください。',
    ),
    const _HelpSection(
      title: '4. 試合の進め方',
      items: [
        '誰かがちょうど50点を取るとそのセットが終了',
        'セット終了後に次のセットの投げ順を変更できます',
        '設定した試合形式（〇先など）で先に勝ち数に達した人が優勝',
      ],
    ),
    const _HelpSection(
      title: '5. 戦績を確認する',
      items: [
        '画面右上の「戦績確認」からこれまでの試合結果を見られます',
      ],
    ),
    const _HelpSection(
      title: '6. セルフ5ターン（1人用練習モード）',
      items: [
        'プレイヤーが1名の場合のみ「セルフ5ターン」モードが選べます',
        '5投で50点ちょうどに到達できれば「成功」',
        '6投以上になるか、5投で50点に届かない場合は「失敗」でゲーム終了',
        '何回連続で成功できるかを競います（連続成功記録を更新しましょう！）',
        '失敗後は「トップへ」でタイトル画面に戻るか「次のチャレンジへ」で新記録に挑戦',
      ],
    ),
    const _HelpSection(
      title: '7. 100均モード（表裏2セット）',
      items: [
        '試合形式で「100均（表裏2セット）」を選択します',
        '1セット目は通常のモルック（50点ちょうどで勝利）',
        '2セット目は1セット目との合計が100点ちょうどになれば勝利',
        '2セット目でバースト（100点超え）した場合は合計が75点に戻ります',
        '2セット目で3回連続ミスをすると2セット目の得点が0点になります',
        '上部のスコア表示は合計得点のみ表示されます（カッコ表記なし）',
      ],
    ),
    const _HelpSection(
      title: '8. 小ネタ',
      items: [
        '秒数の上をタップすると0にリセットできるよ',
        'スコアの入力は数字のダブルタップでもできるよ',
      ],
    ),
  ];

  List<Widget> _enSections(L10n t) => [
    const _HelpSection(
      title: '1. Setup',
      items: [
        'Enter a player name and tap "Add" — up to 8 players',
        'Drag the handle (☰) to reorder the throwing order',
        'Select a game mode (e.g. "First to 2 sets")',
        'Turn on "Voice Input (Beta)" to enter scores by voice',
        'Tap "Start Game" to begin!',
      ],
    ),
    const _HelpSection(
      title: '2. Entering Scores',
      items: [
        'Tap the pin number (1–12) that was knocked down',
        'If multiple pins fell, tap the count button once',
        'Tap "Confirm" to submit the score',
        'For a miss, tap "0 pts (Miss)" without selecting any pin',
        'Tap "Undo" to go back one step',
      ],
    ),
    const _HelpSection(
      title: '3. Voice Input (when enabled)',
      body: 'Just speak toward the microphone — scores are entered automatically.',
      examplesLabel: 'Example phrases:',
      examples: [
        '"Done, 12 points"',
        '"Score five"',
        '"Done, miss"',
      ],
      note: '* If voice input fails to recognize, use the buttons to enter manually.',
    ),
    const _HelpSection(
      title: '4. How the Game Progresses',
      items: [
        'A set ends when someone reaches exactly 50 points',
        'After each set you can reorder players for the next set',
        'The first player to reach the target wins the match',
      ],
    ),
    const _HelpSection(
      title: '5. Viewing Match History',
      items: [
        'Tap the history icon in the top-right corner to view past results',
      ],
    ),
    const _HelpSection(
      title: '6. Self 5-Turn (Solo Practice Mode)',
      items: [
        'Available only when 1 player is registered',
        'Reach exactly 50 points in 5 throws to succeed',
        'Fail if you exceed 5 throws or cannot reach 50',
        'Challenge yourself to build the longest success streak!',
        'After failing, return to the top or start the next challenge',
      ],
    ),
    const _HelpSection(
      title: '7. Hyakin Mode (表裏 2 Sets)',
      items: [
        'Select "Hyakin (表裏 2 sets)" from the game mode options',
        'Set 1 is normal Mölkky — reach exactly 50 to win',
        'Set 2: reach a combined total (Set 1 + Set 2) of exactly 100 to win',
        'Going over 100 in Set 2 (burst) resets the combined total back to 75',
        '3 consecutive misses in Set 2 resets Set 2 score to 0',
        'The score display shows the combined total only (no parentheses)',
      ],
    ),
    const _HelpSection(
      title: '8. Tips',
      items: [
        'Tap on the timer to reset it to 0',
        'Double-tap a number to enter that score directly',
      ],
    ),
  ];
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? body;
  final List<String> examples;
  final String examplesLabel;
  final String? note;

  const _HelpSection({
    required this.title,
    this.items = const [],
    this.body,
    this.examples = const [],
    this.examplesLabel = '話し方の例：',
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
                Text(examplesLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
