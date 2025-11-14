// lib/screens/search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/diary_entry_model.dart';
import '../widgets/custom_icons.dart';
import 'chat_screen.dart';
import 'diary_detail_screen.dart';

enum SearchType { users, conversations, diary }

class SearchScreen extends StatefulWidget {
  final SearchType initialSearchType;

  const SearchScreen({
    super.key,
    this.initialSearchType = SearchType.users,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    switch (widget.initialSearchType) {
      case SearchType.users:
        initialIndex = 0;
        break;
      case SearchType.conversations:
        initialIndex = 1;
        break;
      case SearchType.diary:
        initialIndex = 2;
        break;
    }
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getMoodEmoji(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy:
        return '😊';
      case DiaryMood.sad:
        return '😔';
      case DiaryMood.motivated:
        return '💪';
      case DiaryMood.calm:
        return '😌';
      case DiaryMood.stressed:
        return '😰';
      case DiaryMood.excited:
        return '🤩';
      case DiaryMood.tired:
        return '😴';
      case DiaryMood.grateful:
        return '🙏';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Agora';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    return '${dateTime.day}/${dateTime.month}';
  }

  Widget _buildAllUsersTab(BuildContext context, bool isDark, Color cardColor,
      Color textColor, Color hintColor, String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erro ao carregar usuários: ${snapshot.error}');
          return _buildErrorState(isDark, hintColor, 'Erro ao carregar usuários');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          );
        }

        final allUsers = snapshot.data?.docs ?? [];
        
        // Filtrar usuários válidos
        final filteredUsers = allUsers.where((doc) {
          try {
            if (doc.id == currentUserId) return false;

            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return false;

            final name = (data['name'] as String? ?? '').toLowerCase();
            final nickname = (data['nickname'] as String? ?? '').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();

            if (_searchQuery.isEmpty) return true;

            return name.contains(_searchQuery) ||
                nickname.contains(_searchQuery) ||
                email.contains(_searchQuery);
          } catch (e) {
            print('Erro ao filtrar usuário: $e');
            return false;
          }
        }).toList();

        if (filteredUsers.isEmpty && _isSearching) {
          return _buildEmptyState(
            isDark,
            hintColor,
            CustomIcons.searchOff,
            'Nenhum usuário encontrado',
          );
        }

        if (filteredUsers.isEmpty && !_isSearching) {
          return _buildEmptyState(
            isDark,
            hintColor,
            CustomIcons.userCircle,
            'Nenhum usuário disponível',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredUsers.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
          ),
          itemBuilder: (context, index) {
            try {
              final userDoc = filteredUsers[index];
              final userData = userDoc.data() as Map<String, dynamic>? ?? {};
              final isOnline = userData['isOnline'] == true;
              final userType = userData['userType'] as String? ?? 'person';
              final photoBase64 = userData['photoBase64'];
              final photoURL = userData['photoURL'];
              final userName = userData['name'] as String? ?? 'Usuário';
              final nickname = userData['nickname'] as String?;

              String userTypeLabel = '';
              String userTypeIcon = '';

              switch (userType) {
                case 'student':
                  userTypeLabel = 'Estudante';
                  userTypeIcon = CustomIcons.academicCap;
                  break;
                case 'professional':
                  userTypeLabel = 'Profissional';
                  userTypeIcon = CustomIcons.briefcase;
                  break;
                case 'company':
                  userTypeLabel = 'Empresa';
                  userTypeIcon = CustomIcons.buildingLibrary;
                  break;
                default:
                  userTypeLabel = 'Pessoa';
                  userTypeIcon = CustomIcons.userCircle;
              }

              return Container(
                color: cardColor,
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          recipientId: userDoc.id,
                          recipientName: userName,
                          recipientPhotoURL: photoURL,
                          isOnline: isOnline,
                        ),
                      ),
                    );
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF1877F2),
                        backgroundImage: photoBase64 != null && photoBase64 is String
                            ? MemoryImage(base64Decode(photoBase64))
                            : (photoURL != null && photoURL is String
                                ? NetworkImage(photoURL)
                                : null),
                        child: photoBase64 == null && photoURL == null
                            ? Text(
                                userName.isNotEmpty
                                    ? userName.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF31A24C),
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.string(
                        userTypeIcon,
                        width: 14,
                        height: 14,
                        colorFilter: ColorFilter.mode(
                          hintColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userTypeLabel,
                        style: TextStyle(fontSize: 12, color: hintColor),
                      ),
                      if (nickname != null && nickname.isNotEmpty)
                        Text(
                          '@$nickname',
                          style: TextStyle(fontSize: 13, color: hintColor),
                        ),
                    ],
                  ),
                ),
              );
            } catch (e) {
              print('Erro ao construir item do usuário: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildConversationsTab(BuildContext context, bool isDark,
      Color cardColor, Color textColor, Color hintColor, String? currentUserId) {
    if (currentUserId == null) {
      return Center(
        child: Text(
          'Faça login para ver conversas',
          style: TextStyle(color: textColor),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erro ao carregar conversas: ${snapshot.error}');
          return _buildErrorState(isDark, hintColor, 'Erro ao carregar conversas');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          );
        }

        final allChats = snapshot.data?.docs ?? [];
        
        // Filtrar e ordenar chats válidos
        final validChats = <Map<String, dynamic>>[];
        
        for (var doc in allChats) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final lastMessage = (data['lastMessage'] as String? ?? '').toLowerCase();
            
            if (_isSearching && !lastMessage.contains(_searchQuery)) {
              continue;
            }

            validChats.add({
              'doc': doc,
              'data': data,
              'time': data['lastMessageTime'] as Timestamp?,
            });
          } catch (e) {
            print('Erro ao processar chat: $e');
            continue;
          }
        }

        // Ordenar por tempo
        validChats.sort((a, b) {
          final aTime = a['time'] as Timestamp?;
          final bTime = b['time'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (validChats.isEmpty) {
          return _buildEmptyState(
            isDark,
            hintColor,
            CustomIcons.chatBubble,
            _isSearching
                ? 'Nenhuma conversa encontrada'
                : 'Nenhuma conversa ainda',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: validChats.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
          ),
          itemBuilder: (context, index) {
            try {
              final chatItem = validChats[index];
              final chatDoc = chatItem['doc'] as QueryDocumentSnapshot;
              final chatData = chatItem['data'] as Map<String, dynamic>;
              
              final participants = List<String>.from(chatData['participants'] ?? []);
              final recipientId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (recipientId.isEmpty) return const SizedBox.shrink();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(recipientId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final isOnline = userData['isOnline'] == true;
                  final photoURL = userData['photoURL'];
                  final photoBase64 = userData['photoBase64'];
                  final userName = userData['name'] as String? ?? 'Usuário';
                  final lastMessage = chatData['lastMessage'] as String? ?? '';
                  final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

                  return Container(
                    color: cardColor,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              recipientId: recipientId,
                              recipientName: userName,
                              recipientPhotoURL: photoURL,
                              isOnline: isOnline,
                            ),
                          ),
                        );
                      },
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1877F2),
                            backgroundImage: photoBase64 != null && photoBase64 is String
                                ? MemoryImage(base64Decode(photoBase64))
                                : (photoURL != null && photoURL is String
                                    ? NetworkImage(photoURL)
                                    : null),
                            child: photoBase64 == null && photoURL == null
                                ? Text(
                                    userName.isNotEmpty
                                        ? userName.substring(0, 1).toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF31A24C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardColor, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage.isEmpty
                                  ? 'Toque para conversar'
                                  : lastMessage,
                              style: TextStyle(fontSize: 14, color: hintColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(lastMessageTime.toDate()),
                              style: TextStyle(fontSize: 12, color: hintColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              print('Erro ao construir item de conversa: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildDiaryTab(BuildContext context, bool isDark, Color cardColor,
      Color textColor, Color hintColor, String? currentUserId) {
    if (currentUserId == null) {
      return Center(
        child: Text(
          'Faça login para pesquisar no diário',
          style: TextStyle(color: textColor),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('diary_entries')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erro ao pesquisar diário: ${snapshot.error}');
          return _buildErrorState(isDark, hintColor, 'Erro ao pesquisar');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF1877F2) : const Color(0xFF1877F2),
              ),
            ),
          );
        }

        final allEntries = snapshot.data?.docs ?? [];
        final filteredEntries = allEntries.where((doc) {
          if (!_isSearching) return false;

          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return false;

            final title = (data['title'] as String? ?? '').toLowerCase();
            final content = (data['content'] as String? ?? '').toLowerCase();
            final tags = List<String>.from(data['tags'] ?? []);
            final tagsString = tags.join(' ').toLowerCase();

            return title.contains(_searchQuery) ||
                content.contains(_searchQuery) ||
                tagsString.contains(_searchQuery);
          } catch (e) {
            print('Erro ao filtrar entrada: $e');
            return false;
          }
        }).toList();

        if (filteredEntries.isEmpty) {
          return _buildEmptyState(
            isDark,
            hintColor,
            CustomIcons.searchOff,
            _isSearching
                ? 'Nenhuma entrada encontrada'
                : 'Digite para pesquisar',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: filteredEntries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            try {
              final entryDoc = filteredEntries[index];
              final data = entryDoc.data() as Map<String, dynamic>;

              final entry = DiaryEntry(
                id: entryDoc.id,
                userId: data['userId'] ?? '',
                title: data['title'] ?? '',
                content: data['content'] ?? '',
                date: (data['date'] as Timestamp).toDate(),
                mood: DiaryMood.values.firstWhere(
                  (m) => m.toString() == 'DiaryMood.${data['mood']}',
                  orElse: () => DiaryMood.calm,
                ),
                tags: List<String>.from(data['tags'] ?? []),
                isFavorite: data['isFavorite'] ?? false,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                updatedAt: data['updatedAt'] != null
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : null,
              );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryDetailScreen(entry: entry),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getMoodEmoji(entry.mood),
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(entry.date),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (entry.isFavorite)
                              Icon(
                                Icons.favorite,
                                color: isDark
                                    ? const Color(0xFF1877F2)
                                    : const Color(0xFF1877F2),
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: hintColor,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: entry.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF1877F2)
                                        : const Color(0xFF1877F2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            } catch (e) {
              print('Erro ao construir entrada do diário: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildErrorState(bool isDark, Color hintColor, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            CustomIcons.error,
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: hintColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      bool isDark, Color hintColor, String icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            icon,
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: hintColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowBack,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(fontSize: 16, color: textColor),
          decoration: InputDecoration(
            hintText: _tabController.index == 0
                ? 'Pesquisar usuários...'
                : (_tabController.index == 1
                    ? 'Pesquisar conversas...'
                    : 'Pesquisar no diário...'),
            hintStyle: TextStyle(color: hintColor, fontSize: 16),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: hintColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
              _isSearching = value.trim().isNotEmpty;
            });
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(57),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  dividerHeight: 0,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1877F2),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: textColor,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: (index) {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _isSearching = false;
                    });
                  },
                  tabs: const [
                    Tab(text: 'Usuários'),
                    Tab(text: 'Conversas'),
                    Tab(text: 'Diário'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllUsersTab(
              context, isDark, cardColor, textColor, hintColor, currentUserId),
          _buildConversationsTab(
              context, isDark, cardColor, textColor, hintColor, currentUserId),
          _buildDiaryTab(
              context, isDark, cardColor, textColor, hintColor, currentUserId),
        ],
      ),
    );
  }
}