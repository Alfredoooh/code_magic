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
          return _buildErrorState(isDark, hintColor, 'Erro ao carregar');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          );
        }

        final allUsers = snapshot.data?.docs ?? [];
        final filteredUsers = allUsers.where((doc) {
          if (doc.id == currentUserId) return false;

          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toLowerCase();
          final nickname = (data['nickname'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();

          if (_searchQuery.isEmpty) return true;

          return name.contains(_searchQuery) ||
              nickname.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();

        if (filteredUsers.isEmpty && _isSearching) {
          return _buildEmptyState(
            isDark,
            hintColor,
            CustomIcons.searchOff,
            'Nenhum usuário encontrado',
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
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final isOnline = userData['isOnline'] == true;
            final userType = userData['userType'] ?? 'person';
            final photoBase64 = userData['photoBase64'];
            final photoURL = userData['photoURL'];

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
                        recipientName: userData['name'] ?? 'Usuário',
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
                      backgroundImage: photoBase64 != null
                          ? MemoryImage(base64Decode(photoBase64 as String))
                              as ImageProvider
                          : (photoURL != null
                              ? NetworkImage(photoURL as String) as ImageProvider
                              : null),
                      child: photoBase64 == null && photoURL == null
                          ? Text(
                              userData['name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
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
                        userData['name'] ?? 'Usuário',
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
                    if (userData['nickname'] != null)
                      Text(
                        '@${userData['nickname']}',
                        style: TextStyle(fontSize: 13, color: hintColor),
                      ),
                  ],
                ),
              ),
            );
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
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(isDark, hintColor, 'Erro ao carregar');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
            ),
          );
        }

        final allChats = snapshot.data?.docs ?? [];
        final filteredChats = allChats.where((doc) {
          if (!_isSearching) return true;

          final data = doc.data() as Map<String, dynamic>;
          final lastMessage = (data['lastMessage'] ?? '').toLowerCase();
          return lastMessage.contains(_searchQuery);
        }).toList();

        if (filteredChats.isEmpty) {
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
          itemCount: filteredChats.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
          ),
          itemBuilder: (context, index) {
            final chatDoc = filteredChats[index];
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final participants =
                List<String>.from(chatData['participants'] ?? []);
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
                if (!userSnapshot.hasData) return const SizedBox.shrink();

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox.shrink();

                final isOnline = userData['isOnline'] == true;
                final photoURL = userData['photoURL'];
                final photoBase64 = userData['photoBase64'];
                final userName = userData['name'] ?? 'Usuário';
                final lastMessage = chatData['lastMessage'] ?? '';
                final lastMessageTime =
                    chatData['lastMessageTime'] as Timestamp?;

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
                          backgroundImage: photoBase64 != null
                              ? MemoryImage(
                                      base64Decode(photoBase64 as String))
                                  as ImageProvider
                              : (photoURL != null
                                  ? NetworkImage(photoURL as String)
                                      as ImageProvider
                                  : null),
                          child: photoBase64 == null && photoURL == null
                              ? Text(
                                  userName.substring(0, 1).toUpperCase(),
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
          return _buildErrorState(isDark, hintColor, 'Erro ao pesquisar');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
          );
        }

        final allEntries = snapshot.data?.docs ?? [];
        final filteredEntries = allEntries.where((doc) {
          if (!_isSearching) return false;

          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toLowerCase();
          final content = (data['content'] ?? '').toLowerCase();
          final tags = List<String>.from(data['tags'] ?? []);
          final tagsString = tags.join(' ').toLowerCase();

          return title.contains(_searchQuery) ||
              content.contains(_searchQuery) ||
              tagsString.contains(_searchQuery);
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
                            const Icon(Icons.favorite,
                                color: Color(0xFFE91E63), size: 20),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE91E63),
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
              // Tabs estilo Diary
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