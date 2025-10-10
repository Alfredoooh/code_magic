// lib/main.dart
//
// App de Chat (single-file) — usa apenas:
//   firebase_core: ^2.24.2
//   firebase_auth: ^4.16.0
//   firebase_database: ^10.4.0
//
// Instruções:
// 1) Confirma pubspec.yaml com essas dependências e executa `flutter pub get`.
// 2) Coloca google-services.json (Android) / GoogleService-Info.plist (iOS).
// 3) Garante que no Android gradle config tens o plugin google-services aplicado.
// 4) Se usas CodeMagic, certifica-te que o workflow faz `flutter pub get` antes de construir.
//
// Nota: Evitei nomes/assunções que tipicamente causam falhas no frontend em CI.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// ----------------------------
// UTILIDADES
// ----------------------------
T? safeCast<T>(dynamic value) {
  try {
    return value as T;
  } catch (e) {
    return null;
  }
}

Map<String, dynamic> mapFromSnapshot(dynamic v) {
  if (v == null) return {};
  if (v is Map) {
    return Map<String, dynamic>.from(v.map((k, val) => MapEntry(k.toString(), val)));
  }
  // JSON string?
  if (v is String) {
    try {
      final decoded = json.decode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {}
  }
  return {};
}

List<String> listStringsFrom(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is Map) return v.keys.map((k) => k.toString()).toList();
  return [];
}

String nowIso() => DateTime.now().toIso8601String();
int nowEpoch() => DateTime.now().millisecondsSinceEpoch;

// ----------------------------
// MODELS
// ----------------------------
class AppUser {
  final String uid;
  final String email;
  String name;
  String location;
  int age;
  String signo;
  String avatarUrl;
  bool online;
  int lastSeen;

  AppUser({
    required this.uid,
    required this.email,
    this.name = '',
    this.location = '',
    this.age = 0,
    this.signo = '',
    this.avatarUrl = '',
    this.online = false,
    required this.lastSeen,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    return AppUser(
      uid: uid,
      email: m['email'] ?? '',
      name: m['name'] ?? '',
      location: m['location'] ?? '',
      age: (m['age'] is int) ? m['age'] : int.tryParse('${m['age']}') ?? 0,
      signo: m['signo'] ?? '',
      avatarUrl: m['avatarUrl'] ?? '',
      online: m['online'] == true,
      lastSeen: (m['lastSeenEpoch'] is int) ? m['lastSeenEpoch'] : int.tryParse('${m['lastSeenEpoch'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'location': location,
      'age': age,
      'signo': signo,
      'avatarUrl': avatarUrl,
      'online': online,
      'lastSeenEpoch': lastSeen,
    };
  }
}

class Message {
  final String id;
  final String fromUid;
  String text;
  final int timestamp;
  bool edited;
  Map<String, dynamic> meta;

  Message({
    required this.id,
    required this.fromUid,
    required this.text,
    required this.timestamp,
    this.edited = false,
    Map<String, dynamic>? meta,
  }) : meta = meta ?? {};

  factory Message.fromMap(String id, Map<String, dynamic> m) {
    return Message(
      id: id,
      fromUid: m['fromUid'] ?? '',
      text: m['text'] ?? '',
      timestamp: (m['timestamp'] is int) ? m['timestamp'] : int.tryParse('${m['timestamp'] ?? 0}') ?? 0,
      edited: m['edited'] == true,
      meta: m['meta'] != null ? Map<String, dynamic>.from(m['meta']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'text': text,
      'timestamp': timestamp,
      'edited': edited,
      'meta': meta,
    };
  }
}

class ChatRoom {
  final String id;
  final bool isGroup;
  String title;
  String groupAdmin;
  Map<String, bool> members;

  ChatRoom({
    required this.id,
    this.isGroup = false,
    this.title = '',
    this.groupAdmin = '',
    Map<String, bool>? members,
  }) : members = members ?? {};

  factory ChatRoom.fromMap(String id, Map<String, dynamic> m) {
    final mem = <String, bool>{};
    if (m['members'] is Map) {
      (m['members'] as Map).forEach((k, v) {
        mem[k.toString()] = v == true;
      });
    } else if (m['members'] is List) {
      for (var e in List.from(m['members'])) {
        mem['${e}'] = true;
      }
    }
    return ChatRoom(
      id: id,
      isGroup: m['isGroup'] == true,
      title: m['title'] ?? '',
      groupAdmin: m['groupAdmin'] ?? '',
      members: mem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGroup': isGroup,
      'title': title,
      'groupAdmin': groupAdmin,
      'members': members,
    };
  }
}

// ----------------------------
// FIREBASE SERVICE
// ----------------------------
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  User? user() => _auth.currentUser;

  // Initialize presence when called
  void enablePresence(String uid) {
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    final userRef = _root.child('users').child(uid);
    connectedRef.onValue.listen((event) async {
      final val = event.snapshot.value;
      final connected = val == true || val == 'true';
      if (connected) {
        try {
          await userRef.update({'online': true, 'lastSeenEpoch': nowEpoch()});
          userRef.onDisconnect().update({'online': false, 'lastSeenEpoch': nowEpoch()});
        } catch (e) {
          // ignore
        }
      } else {
        // connection lost
      }
    }, onError: (err) {
      // debug
      // print('presence listen error: $err');
    });
  }

  Future<UserCredential> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    final now = nowEpoch();
    await _root.child('users').child(uid).set({
      'email': email,
      'name': '',
      'location': '',
      'age': 0,
      'signo': '',
      'avatarUrl': '',
      'online': false,
      'lastSeenEpoch': now,
    });
    try {
      if (!cred.user!.emailVerified) await cred.user!.sendEmailVerification();
    } catch (e) {}
    return cred;
  }

  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred;
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _root.child('users').child(uid).update({'online': false, 'lastSeenEpoch': nowEpoch()});
      } catch (e) {}
    }
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // PROFILE
  DatabaseReference usersRef() => _root.child('users');

  Future<AppUser?> getUserOnce(String uid) async {
    final snap = await usersRef().child(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, mapFromSnapshot(snap.value));
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await usersRef().child(uid).update(data);
  }

  // CHATROOMS
  DatabaseReference chatRoomsRef() => _root.child('chatRooms');
  DatabaseReference messagesRef(String chatId) => _root.child('messages').child(chatId);
  DatabaseReference lastMsgRef(String chatId) => _root.child('lastMessages').child(chatId);

  String privateChatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  Future<void> createPrivateIfNotExists(String a, String b) async {
    final id = privateChatId(a, b);
    final ref = chatRoomsRef().child(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'isGroup': false,
        'title': '',
        'groupAdmin': a,
        'members': {a: true, b: true}
      });
    } else {
      // ensure members map correct
      final m = mapFromSnapshot(snap.value);
      if (m['members'] is List) {
        // migrate to map
        final arr = List.from(m['members']);
        final mapMembers = <String, bool>{};
        for (var e in arr) mapMembers['${e}'] = true;
        await ref.child('members').set(mapMembers);
      }
    }
  }

  Future<String> createGroup(String title, String creatorUid, List<String> members) async {
    final ref = chatRoomsRef().push();
    final id = ref.key!;
    final membersMap = <String, bool>{};
    for (var m in members) membersMap[m] = true;
    membersMap[creatorUid] = true;
    await ref.set({
      'isGroup': true,
      'title': title,
      'groupAdmin': creatorUid,
      'members': membersMap,
    });
    return id;
  }

  Future<void> sendMessage(String chatId, Message msg) async {
    final ref = messagesRef(chatId).push();
    await ref.set(msg.toMap());
    await lastMsgRef(chatId).set({'text': msg.text, 'fromUid': msg.fromUid, 'timestamp': msg.timestamp});
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await messagesRef(chatId).child(messageId).update({'text': newText, 'edited': true});
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await messagesRef(chatId).child(messageId).remove();
  }

  // typing
  DatabaseReference typingRef(String chatId) => _root.child('typing').child(chatId);
  Future<void> setTyping(String chatId, String uid, bool typing) async {
    final r = typingRef(chatId).child(uid);
    if (typing) {
      await r.set(true);
      await r.onDisconnect().remove();
    } else {
      await r.remove();
    }
  }

  // helpers:
  Query usersByNameQuery(String prefix) => usersRef().orderByChild('name').startAt(prefix).endAt(prefix + "\uf8ff");
}

final firebaseService = FirebaseService();

// ----------------------------
// MAIN
// ----------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<User?>? _authSub;
  User? _user;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      setState(() => _user = u);
      if (u != null) {
        // enable presence tracking
        firebaseService.enablePresence(u.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false,
      ),
      home: _user == null ? AuthScreen() : HomeScreen(),
    );
  }
}

// ----------------------------
// AUTH UI
// ----------------------------
class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> signIn() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await firebaseService.signIn(_email.text.trim(), _pass.text);
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) firebaseService.enablePresence(u.uid);
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Erro';
    } catch (e) {
      error = 'Erro desconhecido: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> signUp() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await firebaseService.signUp(_email.text.trim(), _pass.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conta criada. Verifica o email se necessário.')));
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Erro';
    } catch (e) {
      error = 'Erro desconhecido: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: min(520, w - 40)),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_rounded, size: 72),
                  SizedBox(height: 8),
                  Text('ChatApp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                  SizedBox(height: 8),
                  TextField(controller: _pass, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
                  SizedBox(height: 12),
                  if (error.isNotEmpty) ...[
                    Text(error, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(onPressed: loading ? null : signIn, icon: Icon(Icons.login), label: Text('Entrar'))),
                      SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: loading ? null : signUp, icon: Icon(Icons.person_add), label: Text('Registar'))),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final email = _email.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Introduz o email para recuperar.')));
                        return;
                      }
                      try {
                        await firebaseService.resetPassword(email);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email de recuperação enviado.')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar email.')));
                      }
                    },
                    child: Text('Esqueci a password'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------
// HOME + NAV
// ----------------------------
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int idx = 0;
  final pages = [ChatsPage(), PeoplePage(), GroupsPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatApp'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await firebaseService.signOut();
            },
            tooltip: 'Sair',
          )
        ],
      ),
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Pessoas'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Grupos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
      floatingActionButton: idx == 0
          ? FloatingActionButton(
              child: Icon(Icons.message),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewChatScreen())),
            )
          : null,
    );
  }
}

// ----------------------------
// CHATS PAGE: lista de conversas (lastMessages)
// ----------------------------
class ChatsPage extends StatefulWidget {
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  Map<String, dynamic> lastMessages = {};
  StreamSubscription? _sub;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('lastMessages').onValue.listen((event) {
      final m = mapFromSnapshot(event.snapshot.value);
      setState(() => lastMessages = m);
    }, onError: (e) {
      // ignore
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String titleForChat(String chatId, Map<String, dynamic> data) {
    final isPrivate = chatId.contains('_');
    if (isPrivate) {
      final parts = chatId.split('_');
      final other = parts[0] == uid ? parts[1] : parts[0];
      return other;
    } else {
      return data['title'] ?? 'Grupo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = lastMessages.entries.toList()
      ..sort((a, b) {
        final ta = (a.value['timestamp'] ?? 0) as int;
        final tb = (b.value['timestamp'] ?? 0) as int;
        return tb.compareTo(ta);
      });

    return ListView(
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text('Conversas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ...items.map((e) {
          final chatId = e.key;
          final d = Map<String, dynamic>.from(e.value);
          final t = titleForChat(chatId, d);
          final txt = d['text'] ?? '';
          final ts = d['timestamp'] ?? 0;
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.chat)),
            title: Text(t),
            subtitle: Text(txt, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(ts == 0 ? '' : DateTime.fromMillisecondsSinceEpoch(ts).hour.toString().padLeft(2, '0') + ':' + DateTime.fromMillisecondsSinceEpoch(ts).minute.toString().padLeft(2, '0')),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, isGroup: !chatId.contains('_')))),
          );
        }).toList(),
      ],
    );
  }
}

// ----------------------------
// PEOPLE PAGE: lista de utilizadores
// ----------------------------
class PeoplePage extends StatefulWidget {
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  Map<String, dynamic> users = {};
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
      final m = mapFromSnapshot(event.snapshot.value);
      setState(() => users = m);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final list = users.entries.where((e) => e.key != myUid).toList()
      ..sort((a, b) => (a.value['name'] ?? '').toString().compareTo((b.value['name'] ?? '').toString()));
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text('Utilizadores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final uid = list[i].key;
              final d = Map<String, dynamic>.from(list[i].value);
              final name = d['name'] ?? d['email'] ?? 'Anon';
              final location = d['location'] ?? '';
              final online = d['online'] == true;
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
                subtitle: Text(location),
                trailing: online ? Icon(Icons.circle, color: Colors.green, size: 12) : Icon(Icons.circle_outlined, size: 12),
                onTap: () async {
                  final my = FirebaseAuth.instance.currentUser!.uid;
                  await firebaseService.createPrivateIfNotExists(my, uid);
                  final chatId = firebaseService.privateChatId(my, uid);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, isGroup: false)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------
// GROUPS PAGE
// ----------------------------
class GroupsPage extends StatefulWidget {
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  Map<String, dynamic> _groups = {};
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('chatRooms').onValue.listen((event) {
      final m = mapFromSnapshot(event.snapshot.value);
      setState(() => _groups = m);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _groups.entries.toList();
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text('Grupos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final id = list[i].key;
              final d = Map<String, dynamic>.from(list[i].value);
              final title = d['title'] ?? 'Grupo';
              final members = d['members'] is Map ? (d['members'] as Map).length : (d['members'] is List ? (d['members'] as List).length : 0);
              final isGroup = d['isGroup'] == true;
              if (!isGroup) return SizedBox.shrink();
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.group)),
                title: Text(title),
                subtitle: Text('$members membros'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(chatId: id, isGroup: true))),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Criar Grupo'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateGroupScreen())),
          ),
        )
      ],
    );
  }
}

// ----------------------------
// PROFILE PAGE
// ----------------------------
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> userMap = {};
  StreamSubscription? _sub;

  final _name = TextEditingController();
  final _location = TextEditingController();
  final _age = TextEditingController();
  String _signo = '';

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('users').child(uid).onValue.listen((event) {
      final m = mapFromSnapshot(event.snapshot.value);
      setState(() {
        userMap = m;
        _name.text = m['name'] ?? '';
        _location.text = m['location'] ?? '';
        _age.text = (m['age'] ?? '').toString();
        _signo = m['signo'] ?? '';
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _name.dispose();
    _location.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nm = _name.text.trim();
    final loc = _location.text.trim();
    final age = int.tryParse(_age.text.trim()) ?? 0;
    await firebaseService.updateProfile(uid, {'name': nm, 'location': loc, 'age': age, 'signo': _signo});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Perfil atualizado')));
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Padding(
      padding: EdgeInsets.all(12),
      child: ListView(
        children: [
          Center(child: CircleAvatar(radius: 44, child: Icon(Icons.person, size: 44))),
          SizedBox(height: 8),
          Text(email, textAlign: TextAlign.center),
          SizedBox(height: 12),
          TextField(controller: _name, decoration: InputDecoration(labelText: 'Nome')),
          SizedBox(height: 8),
          TextField(controller: _location, decoration: InputDecoration(labelText: 'Localização')),
          SizedBox(height: 8),
          TextField(controller: _age, decoration: InputDecoration(labelText: 'Idade'), keyboardType: TextInputType.number),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _signo.isEmpty ? null : _signo,
            items: ['Áries', 'Touro', 'Gêmeos', 'Câncer', 'Leão', 'Virgem', 'Libra', 'Escorpião', 'Sagitário', 'Capricórnio', 'Aquário', 'Peixes']
                .map((s) => DropdownMenuItem(child: Text(s), value: s))
                .toList(),
            onChanged: (v) => setState(() => _signo = v ?? ''),
            decoration: InputDecoration(labelText: 'Signo'),
          ),
          SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: Text('Salvar')),
        ],
      ),
    );
  }
}

// ----------------------------
// CHAT SCREEN
// ----------------------------
class ChatScreen extends StatefulWidget {
  final String chatId;
  final bool isGroup;
  ChatScreen({required this.chatId, required this.isGroup});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  List<Message> _messages = [];
  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  Set<String> _othersTyping = {};
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final messagesRef = FirebaseDatabase.instance.ref('messages').child(widget.chatId);
    _msgSub = messagesRef.orderByChild('timestamp').onChildAdded.listen((event) {
      final m = Message.fromMap(event.snapshot.key ?? '', mapFromSnapshot(event.snapshot.value));
      setState(() {
        _messages.insert(0, m);
      });
    }, onError: (e) {});

    _typingSub = FirebaseDatabase.instance.ref('typing').child(widget.chatId).onValue.listen((event) {
      final map = mapFromSnapshot(event.snapshot.value);
      final set = <String>{};
      map.forEach((k, v) {
        if (k != _uid) set.add(k);
      });
      setState(() => _othersTyping = set);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _text.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final txt = _text.text.trim();
    if (txt.isEmpty) return;
    final id = FirebaseDatabase.instance.ref('messages').child(widget.chatId).push().key ?? '';
    final msg = Message(id: id, fromUid: _uid, text: txt, timestamp: nowEpoch());
    try {
      await firebaseService.sendMessage(widget.chatId, msg);
      _text.clear();
      await firebaseService.setTyping(widget.chatId, _uid, false);
      setState(() => _isTyping = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar')));
    }
  }

  void _onTyping(String t) {
    if (!_isTyping) {
      _isTyping = true;
      firebaseService.setTyping(widget.chatId, _uid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(milliseconds: 1200), () {
      _isTyping = false;
      firebaseService.setTyping(widget.chatId, _uid, false);
    });
  }

  Future<void> _editMessage(Message m) async {
    final ctl = TextEditingController(text: m.text);
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar mensagem'),
        content: TextField(controller: ctl),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()), child: Text('Salvar')),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await firebaseService.editMessage(widget.chatId, m.id, res);
    }
  }

  Future<void> _deleteMessage(Message m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar mensagem?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Não')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Sim')),
        ],
      ),
    );
    if (ok == true) {
      await firebaseService.deleteMessage(widget.chatId, m.id);
      setState(() => _messages.removeWhere((it) => it.id == m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chatId;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(child: Icon(widget.isGroup ? Icons.group : Icons.person)),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_othersTyping.isNotEmpty) Text('${_othersTyping.length} a escrever...', style: TextStyle(fontSize: 12))
          ])
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('Sem mensagens'))
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final mine = m.fromUid == _uid;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            if (mine) {
                              showModalBottomSheet(context: context, builder: (c) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(leading: Icon(Icons.edit), title: Text('Editar'), onTap: () { Navigator.of(c).pop(); _editMessage(m); }),
                                  ListTile(leading: Icon(Icons.delete), title: Text('Apagar'), onTap: () { Navigator.of(c).pop(); _deleteMessage(m); }),
                                ],
                              ));
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine ? Colors.indigo.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.text),
                                SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${DateTime.fromMillisecondsSinceEpoch(m.timestamp).hour.toString().padLeft(2,'0')}:${DateTime.fromMillisecondsSinceEpoch(m.timestamp).minute.toString().padLeft(2,'0')}', style: TextStyle(fontSize: 10)),
                                    if (m.edited) SizedBox(width: 6),
                                    if (m.edited) Text('(edit)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      onChanged: _onTyping,
                      decoration: InputDecoration(hintText: 'Escreve uma mensagem'),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ----------------------------
// NEW CHAT SCREEN
// ----------------------------
class NewChatScreen extends StatefulWidget {
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  Map<String, dynamic> users = {};
  StreamSubscription? _usersSub;
  final myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
      setState(() => users = mapFromSnapshot(event.snapshot.value));
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = users.entries.where((e) => e.key != myUid).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Novo chat')),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final otherUid = list[i].key;
          final d = Map<String, dynamic>.from(list[i].value);
          final name = d['name'] ?? d['email'];
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(name),
            onTap: () async {
              await firebaseService.createPrivateIfNotExists(myUid, otherUid);
              final chatId = firebaseService.privateChatId(myUid, otherUid);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, isGroup: false)));
            },
          );
        },
      ),
    );
  }
}

// ----------------------------
// CREATE GROUP SCREEN
// ----------------------------
class CreateGroupScreen extends StatefulWidget {
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _title = TextEditingController();
  Map<String, dynamic> users = {};
  Set<String> selected = {};
  StreamSubscription? _usersSub;
  final myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
      setState(() => users = mapFromSnapshot(event.snapshot.value));
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _usersSub?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    final t = _title.text.trim();
    if (t.isEmpty || selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Título e pelo menos 1 membro obrigatórios')));
      return;
    }
    final membersList = selected.toList();
    final id = await firebaseService.createGroup(t, myUid, membersList);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen(chatId: id, isGroup: true)));
  }

  @override
  Widget build(BuildContext context) {
    final list = users.entries.where((e) => e.key != myUid).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Criar Grupo')),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.all(12), child: TextField(controller: _title, decoration: InputDecoration(labelText: 'Nome do grupo'))),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final uid = list[i].key;
                final d = Map<String, dynamic>.from(list[i].value);
                final name = d['name'] ?? d['email'];
                final sel = selected.contains(uid);
                return CheckboxListTile(value: sel, onChanged: (v) {
                  setState(() {
                    if (v == true) selected.add(uid); else selected.remove(uid);
                  });
                }, title: Text(name));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: ElevatedButton(onPressed: _create, child: Text('Criar grupo')),
          )
        ],
      ),
    );
  }
}