// lib/main.dart
// App de Chat em um único ficheiro (usa: firebase_core, firebase_auth, firebase_database)
// ATENÇÃO: já assumo que configuraste o Firebase no Android / iOS (google-services.json / GoogleService-Info.plist).
// Dependências no pubspec.yaml:
//   firebase_core: ^2.24.2
//   firebase_auth: ^4.16.0
//   firebase_database: ^10.4.0
//
// Observações:
// - Não há OTP. Login por email+password. Há verificação de email (sendEmailVerification).
// - Armazenamento: Realtime Database.
// - Presença: .info/connected + onDisconnect for presence.
// - Mensagens: nós /messages/{chatId}/{messageId}
// - Chats privados: chatId = uid1_uid2 (ordenado) ; Grupos: /groups/{groupId}/messages
// - UI: Material, NavigationBar (pill native), bottom tabs.
// - Adaptar às tuas regras de segurança pós-teste.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// ---------- CONFIG ----------
const bool REQUIRE_EMAIL_VERIFICATION = true; // exige email verificado para aceder
// ----------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

// ---------- MODELS ----------
class AppUser {
  final String uid;
  final String email;
  String name;
  String location;
  int age;
  String signo;
  String avatarUrl;
  bool online;
  int lastSeenEpoch;

  AppUser({
    required this.uid,
    required this.email,
    this.name = '',
    this.location = '',
    this.age = 0,
    this.signo = '',
    this.avatarUrl = '',
    this.online = false,
    this.lastSeenEpoch = 0,
  });

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      age: map['age'] ?? 0,
      signo: map['signo'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      online: map['online'] ?? false,
      lastSeenEpoch: map['lastSeenEpoch'] ?? 0,
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
      'lastSeenEpoch': lastSeenEpoch,
    };
  }
}

class Message {
  final String id;
  final String fromUid;
  final String text;
  final int timestamp;
  final bool edited;

  Message({
    required this.id,
    required this.fromUid,
    required this.text,
    required this.timestamp,
    this.edited = false,
  });

  factory Message.fromMap(String id, Map<dynamic, dynamic> map) {
    return Message(
      id: id,
      fromUid: map['fromUid'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      edited: map['edited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'text': text,
      'timestamp': timestamp,
      'edited': edited,
    };
  }
}

class ChatRoom {
  final String id;
  final String title;
  final bool isGroup;
  final List<String> members; // uids
  final String groupAdmin; // empty if private

  ChatRoom({
    required this.id,
    required this.title,
    required this.isGroup,
    required this.members,
    this.groupAdmin = '',
  });

  factory ChatRoom.fromMap(String id, Map<dynamic, dynamic> map) {
    return ChatRoom(
      id: id,
      title: map['title'] ?? '',
      isGroup: map['isGroup'] ?? false,
      members: map['members'] != null ? List<String>.from(map['members']) : [],
      groupAdmin: map['groupAdmin'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isGroup': isGroup,
      'members': members,
      'groupAdmin': groupAdmin,
    };
  }
}

// ---------- SERVICES ----------
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRoot = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  // Auth
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // create user node in Realtime DB
    final uid = cred.user!.uid;
    await _dbRoot.child('users').child(uid).set({
      'email': email,
      'name': '',
      'location': '',
      'age': 0,
      'signo': '',
      'avatarUrl': '',
      'online': false,
      'lastSeenEpoch': DateTime.now().millisecondsSinceEpoch,
    });
    // send verification email (if required)
    try {
      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
      }
    } catch (e) {
      // ignore
    }
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred;
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await setUserOnline(uid, false);
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // PROFILE
  DatabaseReference usersRef() => _dbRoot.child('users');

  Future<void> updateProfile(String uid, Map<String, dynamic> values) async {
    await usersRef().child(uid).update(values);
  }

  Future<AppUser?> getUserOnce(String uid) async {
    final snap = await usersRef().child(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, Map<dynamic, dynamic>.from(snap.value as Map));
  }

  // PRESENCE
  Future<void> setUserOnline(String uid, bool online) async {
    final ref = usersRef().child(uid);
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.update({
      'online': online,
      'lastSeenEpoch': now,
    });
  }

  // presence with .info/connected and onDisconnect
  void enablePresenceListener(String uid) {
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    final userStatusRef = usersRef().child(uid);
    connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        // set online true and setup onDisconnect to set offline
        await userStatusRef.update({
          'online': true,
          'lastSeenEpoch': DateTime.now().millisecondsSinceEpoch,
        });
        userStatusRef.onDisconnect().update({
          'online': false,
          'lastSeenEpoch': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // connection lost
      }
    });
  }

  // CHAT / MESSAGES
  String privateChatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  DatabaseReference messagesRef(String chatId) => _dbRoot.child('messages').child(chatId);

  Future<void> sendMessage(String chatId, Message msg) async {
    final ref = messagesRef(chatId).push();
    await ref.set(msg.toMap());
  }

  Future<void> createGroup(String title, String creatorUid, List<String> members) async {
    final groupRef = _dbRoot.child('groups').push();
    final groupId = groupRef.key!;
    final chatRoom = ChatRoom(
      id: groupId,
      title: title,
      isGroup: true,
      members: members,
      groupAdmin: creatorUid,
    );
    await groupRef.set(chatRoom.toMap());
    // create a node to link group messages: /messages/{groupId} will be used
  }

  DatabaseReference groupsRef() => _dbRoot.child('groups');
  DatabaseReference chatRoomsRef() => _dbRoot.child('chatRooms'); // optional mapping

  // last messages summary (for chats list)
  DatabaseReference lastMsgRef(String chatId) => _dbRoot.child('lastMessages').child(chatId);

  Future<void> setLastMessage(String chatId, Message msg) async {
    await lastMsgRef(chatId).set({
      'text': msg.text,
      'fromUid': msg.fromUid,
      'timestamp': msg.timestamp,
    });
  }

  // Search users by name/email (simple full scan, consider index in rules)
  Query allUsersQuery() => usersRef().orderByChild('name');

  // typing indicator
  DatabaseReference typingRef(String chatId, String uid) => _dbRoot.child('typing').child(chatId).child(uid);

  Future<void> setTyping(String chatId, String uid, bool isTyping) async {
    final ref = typingRef(chatId, uid);
    if (isTyping) {
      await ref.set(true);
      ref.onDisconnect().remove();
    } else {
      await ref.remove();
    }
  }
}

final firebaseService = FirebaseService();

// ---------- UI ----------
class ChatApp extends StatefulWidget {
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (REQUIRE_EMAIL_VERIFICATION && !user.emailVerified) {
          // keep in login flow but allow user to request verification
        } else {
          // enable presence tracking
          firebaseService.enablePresenceListener(user.uid);
        }
      }
      setState(() {});
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        // NO gradients, flat clean Material design
        colorSchemeSeed: Colors.indigo,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? user;
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
      setState(() {
        user = u;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return SignInScreen();
    } else {
      if (REQUIRE_EMAIL_VERIFICATION && !user!.emailVerified) {
        return EmailVerifyScreen(user: user!);
      }
      return HomeScreen();
    }
  }
}

// ---------- LOGIN / SIGNUP ----------
class SignInScreen extends StatefulWidget {
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await firebaseService.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      final u = FirebaseAuth.instance.currentUser!;
      if (REQUIRE_EMAIL_VERIFICATION && !u.emailVerified) {
        // keep in verify screen
      } else {
        firebaseService.enablePresenceListener(u.uid);
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Erro no login';
    } catch (e) {
      _error = 'Erro desconhecido';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await firebaseService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      // user created, email verification sent
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conta criada. Verifica o email.')));
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Erro no registo';
    } catch (e) {
      _error = 'Erro desconhecido';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Layout: centered card, nice Material without gradients
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_rounded, size: 64),
                  SizedBox(height: 12),
                  Text('Bem-vindo ao ChatApp', style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_rounded)),
                    obscureText: true,
                  ),
                  SizedBox(height: 12),
                  if (_error.isNotEmpty) ...[
                    Text(_error, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: Icon(Icons.login_rounded),
                          label: Text('Entrar'),
                          onPressed: _loading ? null : _signIn,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.person_add_rounded),
                          label: Text('Registar'),
                          onPressed: _loading ? null : _signup,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final email = _emailCtrl.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Introduz o email para recuperar.')));
                        return;
                      }
                      await firebaseService.sendPasswordReset(email);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email de recuperação enviado.')));
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

class EmailVerifyScreen extends StatefulWidget {
  final User user;
  EmailVerifyScreen({required this.user});
  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  bool _sent = false;
  bool _loading = false;

  Future<void> _send() async {
    setState(() {
      _loading = true;
    });
    try {
      await widget.user.sendEmailVerification();
      setState(() {
        _sent = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar email.')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
    });
    await widget.user.reload();
    if (widget.user.emailVerified) {
      // reload and go to home automatically (auth state changes)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email verificado!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email ainda não verificado.')));
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifica o Email'),
        actions: [
          IconButton(
            onPressed: () async {
              await firebaseService.signOut();
            },
            icon: Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.mark_email_read_rounded, size: 56),
              SizedBox(height: 8),
              Text('Verifica o teu email', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text('Enviámos um email para ${widget.user.email}. Confirma a verificação.'),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: _loading ? null : _send, child: Text(_sent ? 'Reenviar' : 'Enviar email'))),
                  SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: _loading ? null : _check, child: Text('Já verifiquei'))),
                ],
              ),
              SizedBox(height: 8),
              TextButton(onPressed: () async => await firebaseService.signOut(), child: Text('Sair')),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------- HOME + TABS ----------
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const tabs = ['Chats', 'People', 'Groups', 'Profile'];
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final List<Widget> _pages = [
    ChatsListPage(),
    PeopleListPage(),
    GroupsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatApp'),
        actions: [
          IconButton(
              onPressed: () async {
                await firebaseService.reloadUser();
                setState(() {});
              },
              icon: Icon(Icons.refresh_rounded))
        ],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        // NavigationBar provides pill native indicator (Material 3)
        destinations: [
          NavigationDestination(icon: RoundedIcon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
          NavigationDestination(icon: RoundedIcon(Icons.people_outline_rounded), label: 'People'),
          NavigationDestination(icon: RoundedIcon(Icons.group_outlined), label: 'Groups'),
          NavigationDestination(icon: RoundedIcon(Icons.person_outline_rounded), label: 'Perfil'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              child: Icon(Icons.message_rounded),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewChatPage()));
              },
            )
          : null,
    );
  }
}

class RoundedIcon extends StatelessWidget {
  final IconData icon;
  RoundedIcon(this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 0)
      ]),
      padding: EdgeInsets.all(6),
      child: Icon(icon),
    );
  }
}

// ---------- CHATS LIST ----------
class ChatsListPage extends StatefulWidget {
  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  late final String uid;
  late DatabaseReference lastMessagesRef;
  StreamSubscription<DatabaseEvent>? _lastSub;
  Map<String, dynamic> lastMessages = {}; // chatId -> map

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    lastMessagesRef = FirebaseDatabase.instance.ref('lastMessages');
    // we'll listen to lastMessages and filter those where chatId contains uid or groups where user is member
    _lastSub = lastMessagesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        setState(() => lastMessages = {});
        return;
      }
      final map = Map<String, dynamic>.from(data.map((k, v) => MapEntry(k.toString(), v)));
      setState(() {
        lastMessages = map;
      });
    });
  }

  @override
  void dispose() {
    _lastSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show chats where chatId contains uid OR group ids (we might need to fetch groups separately)
    final items = lastMessages.entries.toList()
      ..sort((a, b) {
        final ta = (a.value['timestamp'] ?? 0) as int;
        final tb = (b.value['timestamp'] ?? 0) as int;
        return tb.compareTo(ta);
      });
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text('Conversas recentes', style: Theme.of(context).textTheme.titleLarge),
        ),
        ...items.map((entry) {
          final chatId = entry.key;
          final data = Map<String, dynamic>.from(entry.value as Map);
          final ts = data['timestamp'] ?? 0;
          final txt = data['text'] ?? '';
          final fromUid = data['fromUid'] ?? '';
          final isPrivate = chatId.contains('_'); // simple heuristic
          String title = isPrivate ? 'Mensagem privada' : 'Grupo';
          if (isPrivate) {
            final parts = chatId.split('_');
            final otherUid = parts[0] == uid ? parts[1] : parts[0];
            title = otherUid;
          } else {
            title = chatId;
          }
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.chat_rounded)),
            title: Text(title),
            subtitle: Text(txt, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatTime(ts)),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, isGroup: !isPrivate)));
            },
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  String _formatTime(int epoch) {
    if (epoch == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ---------- PEOPLE LIST (contacts) ----------
class PeopleListPage extends StatefulWidget {
  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  final usersRef = FirebaseDatabase.instance.ref('users');
  StreamSubscription<DatabaseEvent>? _usersSub;
  Map<String, dynamic> _users = {};

  @override
  void initState() {
    super.initState();
    _usersSub = usersRef.onValue.listen((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) {
        setState(() => _users = {});
        return;
      }
      final m = Map<String, dynamic>.from(map.map((k, v) => MapEntry(k.toString(), v)));
      setState(() => _users = m);
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final list = _users.entries.where((e) => e.key != uid).toList()
      ..sort((a, b) {
        final an = (a.value['name'] ?? '') as String;
        final bn = (b.value['name'] ?? '') as String;
        return an.compareTo(bn);
      });
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text('Utilizadores', style: Theme.of(context).textTheme.titleLarge)),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final uid = list[i].key;
              final data = Map<String, dynamic>.from(list[i].value);
              final name = data['name'] ?? data['email'] ?? 'Anon';
              final online = data['online'] ?? false;
              final location = data['location'] ?? '';
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(name),
                subtitle: Text(location),
                trailing: online ? Icon(Icons.circle, color: Colors.green, size: 12) : Icon(Icons.circle_outlined, size: 12),
                onTap: () {
                  final myUid = FirebaseAuth.instance.currentUser!.uid;
                  final chatId = firebaseService.privateChatIdFor(myUid, uid);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, isGroup: false, otherUid: uid)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------- GROUPS PAGE ----------
class GroupsPage extends StatefulWidget {
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final groupsRef = FirebaseDatabase.instance.ref('groups');
  StreamSubscription<DatabaseEvent>? _groupsSub;
  Map<String, dynamic> _groups = {};

  @override
  void initState() {
    super.initState();
    _groupsSub = groupsRef.onValue.listen((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) {
        setState(() => _groups = {});
        return;
      }
      final m = Map<String, dynamic>.from(map.map((k, v) => MapEntry(k.toString(), v)));
      setState(() => _groups = m);
    });
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _groups.entries.toList();
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text('Grupos', style: Theme.of(context).textTheme.titleLarge)),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final id = items[i].key;
              final data = Map<String, dynamic>.from(items[i].value);
              final title = data['title'] ?? 'Grupo';
              final members = data['members'] != null ? List<String>.from(data['members']) : [];
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.group_rounded)),
                title: Text(title),
                subtitle: Text('${members.length} membros'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: id, isGroup: true)));
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: Icon(Icons.add_rounded),
            label: Text('Criar grupo'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateGroupPage()));
            },
          ),
        )
      ],
    );
  }
}

// ---------- PROFILE PAGE ----------
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseReference userRef;
  StreamSubscription<DatabaseEvent>? _userSub;
  AppUser? appUser;

  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _signo = '';

  @override
  void initState() {
    super.initState();
    userRef = FirebaseDatabase.instance.ref('users').child(uid);
    _userSub = userRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final u = AppUser.fromMap(uid, Map<dynamic, dynamic>.from(data));
      setState(() {
        appUser = u;
        _nameCtrl.text = u.name;
        _locationCtrl.text = u.location;
        _ageCtrl.text = u.age == 0 ? '' : u.age.toString();
        _signo = u.signo;
      });
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    await firebaseService.updateProfile(uid, {
      'name': name,
      'location': location,
      'age': age,
      'signo': _signo,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Perfil atualizado')));
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.email ?? '';
    return Padding(
      padding: EdgeInsets.all(12),
      child: ListView(
        children: [
          Center(
            child: CircleAvatar(radius: 44, child: Icon(Icons.person_rounded, size: 44)),
          ),
          SizedBox(height: 12),
          Text(email, textAlign: TextAlign.center),
          SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Nome')),
          SizedBox(height: 8),
          TextField(controller: _locationCtrl, decoration: InputDecoration(labelText: 'Localização')),
          SizedBox(height: 8),
          TextField(controller: _ageCtrl, decoration: InputDecoration(labelText: 'Idade'), keyboardType: TextInputType.number),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _signo.isEmpty ? null : _signo,
            hint: Text('Signo'),
            items: [
              'Áries', 'Touro', 'Gêmeos', 'Câncer', 'Leão', 'Virgem', 'Libra', 'Escorpião', 'Sagitário', 'Capricórnio', 'Aquário', 'Peixes'
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _signo = v ?? ''),
          ),
          SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text('Salvar')),
          SizedBox(height: 12),
          OutlinedButton(onPressed: () async => await firebaseService.signOut(), child: Text('Sair')),
        ],
      ),
    );
  }
}

// ---------- CHAT PAGE ----------
class ChatPage extends StatefulWidget {
  final String chatId;
  final bool isGroup;
  final String? otherUid; // for private chats
  ChatPage({required this.chatId, required this.isGroup, this.otherUid});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseReference messagesRef;
  late DatabaseReference typingRef;
  StreamSubscription<DatabaseEvent>? _messagesSub;
  List<Message> _messages = [];
  Timer? _typingTimer;
  bool _isTyping = false;
  StreamSubscription<DatabaseEvent>? _typingSub;
  Set<String> othersTyping = {};

  @override
  void initState() {
    super.initState();
    messagesRef = firebaseService.messagesRef(widget.chatId);
    messagesRef.onChildAdded.listen(_onMessageAdded);
    messagesRef.onChildChanged.listen(_onMessageChanged);
    messagesRef.onChildRemoved.listen(_onMessageRemoved);
    typingRef = FirebaseDatabase.instance.ref('typing').child(widget.chatId);
    _typingSub = typingRef.onValue.listen((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      final set = <String>{};
      if (map != null) {
        map.forEach((k, v) {
          if (k != uid) set.add(k.toString());
        });
      }
      setState(() {
        othersTyping = set;
      });
    });
  }

  void _onMessageAdded(DatabaseEvent event) {
    final id = event.snapshot.key!;
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    final msg = Message.fromMap(id, data);
    setState(() {
      _messages.insert(0, msg);
    });
  }

  void _onMessageChanged(DatabaseEvent event) {
    final id = event.snapshot.key!;
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    final msg = Message.fromMap(id, data);
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx >= 0) _messages[idx] = msg;
    });
  }

  void _onMessageRemoved(DatabaseEvent event) {
    final id = event.snapshot.key!;
    setState(() {
      _messages.removeWhere((m) => m.id == id);
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _typingTimer?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final id = firebaseService.messagesRef(widget.chatId).push().key ?? '';
    final msg = Message(id: id, fromUid: uid, text: text, timestamp: DateTime.now().millisecondsSinceEpoch);
    await firebaseService.sendMessage(widget.chatId, msg);
    await firebaseService.setLastMessage(widget.chatId, msg);
    _controller.clear();
    await firebaseService.setTyping(widget.chatId, uid, false);
    setState(() {
      _isTyping = false;
    });
  }

  void _onTyping(String text) {
    if (!_isTyping) {
      _isTyping = true;
      firebaseService.setTyping(widget.chatId, uid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(milliseconds: 1200), () {
      _isTyping = false;
      firebaseService.setTyping(widget.chatId, uid, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isGroup ? 'Grupo' : (widget.otherUid ?? 'Privado');
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(child: Icon(widget.isGroup ? Icons.group_rounded : Icons.person_rounded)),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title),
            if (othersTyping.isNotEmpty) Text('${othersTyping.length} a escrever...', style: TextStyle(fontSize: 12))
          ]),
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded))
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
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = m.fromUid == uid;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(_timeString(m.timestamp), style: TextStyle(fontSize: 10, color: Colors.black54)),
                                if (mine) SizedBox(width: 6),
                                if (mine) Icon(Icons.check, size: 12),
                              ])
                            ],
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
                  IconButton(onPressed: () {}, icon: Icon(Icons.attach_file_rounded)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onTyping,
                      decoration: InputDecoration(hintText: 'Escreve uma mensagem'),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: Icon(Icons.send_rounded)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _timeString(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ---------- CREATE GROUP PAGE ----------
class CreateGroupPage extends StatefulWidget {
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _titleCtrl = TextEditingController();
  Map<String, dynamic> users = {};
  Set<String> selected = {};
  StreamSubscription<DatabaseEvent>? _usersSub;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) {
        setState(() => users = {});
        return;
      }
      setState(() => users = Map<String, dynamic>.from(map.map((k, v) => MapEntry(k.toString(), v))));
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Título e pelo menos 1 membro')));
      return;
    }
    final creator = FirebaseAuth.instance.currentUser!.uid;
    final members = selected.toList()..add(creator);
    await firebaseService.createGroup(title, creator, members);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final list = users.entries.toList();
    return Scaffold(
      appBar: AppBar(title: Text('Criar grupo')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'Nome do grupo')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final uid = list[i].key;
                final data = Map<String, dynamic>.from(list[i].value);
                final name = data['name'] ?? data['email'];
                final isSelected = selected.contains(uid);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true)
                      selected.add(uid);
                    else
                      selected.remove(uid);
                  }),
                  title: Text(name),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: FilledButton(onPressed: _create, child: Text('Criar grupo')),
          )
        ],
      ),
    );
  }
}

// ---------- NEW CHAT PAGE ----------
class NewChatPage extends StatefulWidget {
  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  Map<String, dynamic> users = {};
  StreamSubscription<DatabaseEvent>? _usersSub;

  @override
  void initState() {
    super.initState();
    _usersSub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return;
      setState(() => users = Map<String, dynamic>.from(map.map((k, v) => MapEntry(k.toString(), v))));
    });
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final list = users.entries.where((e) => e.key != uid).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar conversa')),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final otherUid = list[i].key;
          final data = Map<String, dynamic>.from(list[i].value);
          final name = data['name'] ?? data['email'];
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(name),
            onTap: () {
              final chatId = firebaseService.privateChatIdFor(uid, otherUid);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, isGroup: false, otherUid: otherUid)));
            },
          );
        },
      ),
    );
  }
}