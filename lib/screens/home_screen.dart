import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentLanguage;

  const HomeScreen({
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showDrawer = false;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _showDrawer = !_showDrawer;
      if (_showDrawer) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _showUserModal() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF444F))),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                      ? NetworkImage(userData['profile_image'])
                      : null,
                  backgroundColor: Color(0xFFFF444F),
                  child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                      ? Text(
                          (userData['username'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                SizedBox(height: 16),
                Text(
                  userData['username'] ?? 'Usuário',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  userData['email'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: userData['is_pro'] == true ? Color(0xFFFF444F) : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userData['is_pro'] == true ? 'PRO' : 'FREEMIUM',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (userData['is_admin'] == true)
                        ListTile(
                          leading: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFF444F)),
                          title: Text('Painel Admin'),
                          trailing: Icon(Icons.chevron_right_rounded),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            Navigator.pop(context);
                            // Navegar para painel admin
                          },
                        ),
                      ListTile(
                        leading: Icon(Icons.settings_rounded, color: Color(0xFFFF444F)),
                        title: Text('Configurações'),
                        trailing: Icon(Icons.chevron_right_rounded),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          _showSettingsModal();
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.logout_rounded, color: Colors.red),
                        title: Text('Sair', style: TextStyle(color: Colors.red)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          FirebaseAuth.instance.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsModal() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF444F))),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isDark = userData['theme'] == 'dark';

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Configurações',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ListTile(
                        leading: Icon(Icons.palette_rounded, color: Color(0xFFFF444F)),
                        title: Text('Tema'),
                        subtitle: Text(isDark ? 'Escuro' : 'Claro'),
                        trailing: Switch(
                          value: isDark,
                          activeColor: Color(0xFFFF444F),
                          onChanged: (value) async {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'theme': value ? 'dark' : 'light',
                            });
                            widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.language_rounded, color: Color(0xFFFF444F)),
                        title: Text('Idioma'),
                        subtitle: Text(userData['language'] == 'pt' ? 'Português' : userData['language'] == 'en' ? 'English' : 'Español'),
                        trailing: Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Selecionar Idioma'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('Português'),
                                    leading: Radio(
                                      value: 'pt',
                                      groupValue: userData['language'],
                                      activeColor: Color(0xFFFF444F),
                                      onChanged: (val) async {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                          'language': 'pt',
                                        });
                                        widget.onLanguageChanged('pt');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                  ListTile(
                                    title: Text('English'),
                                    leading: Radio(
                                      value: 'en',
                                      groupValue: userData['language'],
                                      activeColor: Color(0xFFFF444F),
                                      onChanged: (val) async {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                          'language': 'en',
                                        });
                                        widget.onLanguageChanged('en');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                  ListTile(
                                    title: Text('Español'),
                                    leading: Radio(
                                      value: 'es',
                                      groupValue: userData['language'],
                                      activeColor: Color(0xFFFF444F),
                                      onChanged: (val) async {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                          'language': 'es',
                                        });
                                        widget.onLanguageChanged('es');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('K Paga', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded),
          onPressed: _toggleDrawer,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () {
              // Abrir tela de pesquisa
            },
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox(width: 40);

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _showUserModal,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: userData?['profile_image'] != null && userData!['profile_image'].isNotEmpty
                        ? NetworkImage(userData['profile_image'])
                        : null,
                    backgroundColor: Color(0xFFFF444F),
                    child: userData?['profile_image'] == null || userData!['profile_image'].isEmpty
                        ? Text(
                            (userData?['username'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card de Carteira
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF444F).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Minha Carteira',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Tokens Disponíveis',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${userData['tokens'] ?? 0}',
                            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          if (userData['is_pro'] == true && userData['pro_expiration'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PRO até ${_formatDate(userData['pro_expiration'])}',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Estatísticas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.message_rounded,
                            title: 'Mensagens',
                            value: '0',
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.group_rounded,
                            title: 'Grupos',
                            value: '0',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Publicações Recentes',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Nenhuma publicação ainda',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['title'] ?? '',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      post['content'] ?? '',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          if (_showDrawer)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          if (_showDrawer)
            SlideTransition(
              position: _drawerAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Opções',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded),
                              onPressed: _toggleDrawer,
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            ListTile(
                              leading: Icon(Icons.home_rounded, color: Color(0xFFFF444F)),
                              title: Text('Início'),
                              onTap: () => _toggleDrawer(),
                            ),
                            ListTile(
                              leading: Icon(Icons.upgrade_rounded, color: Color(0xFFFF444F)),
                              title: Text('Upgrade para PRO'),
                              onTap: () {
                                _toggleDrawer();
                                // Mostrar modal de upgrade
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.help_rounded, color: Color(0xFFFF444F)),
                              title: Text('Ajuda'),
                              onTap: () => _toggleDrawer(),
                            ),
                            ListTile(
                              leading: Icon(Icons.info_rounded, color: Color(0xFFFF444F)),
                              title: Text('Sobre'),
                              onTap: () => _toggleDrawer(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required bool isDark}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Color(0xFF2C2C2C) : Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFFFF444F), size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}