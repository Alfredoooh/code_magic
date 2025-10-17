import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../group_detail_screen.dart';

class GroupListItem extends StatelessWidget {
  final QueryDocumentSnapshot group;
  final bool isDark;

  const GroupListItem({
    Key? key,
    required this.group,
    required this.isDark,
  }) : super(key: key);

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupData = group.data() as Map<String, dynamic>;
    final members = List.from(groupData['members'] ?? []);
    final lastMessage = groupData['lastMessage'] ?? '';
    final lastMessageTime = groupData['lastMessageTime'] as Timestamp?;
    final groupImage = groupData['groupImage'] ?? '';
    final hasUnread = groupData['hasUnread'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.black : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: _buildGroupAvatar(groupImage, groupData['name'] ?? 'G'),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupData['name'] ?? 'Grupo',
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 17,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
            if (lastMessageTime != null)
              Text(
                _formatTime(lastMessageTime),
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage.isEmpty 
                    ? '${members.length} ${members.length == 1 ? 'membro' : 'membros'}'
                    : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread 
                      ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                      : CupertinoColors.systemGrey,
                  fontSize: 15,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (hasUnread)
              Container(
                margin: EdgeInsets.only(left: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: group.id,
                groupName: groupData['name'] ?? 'Grupo',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupAvatar(String groupImage, String groupName) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30D158)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF34C759).withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: groupImage.isNotEmpty
          ? ClipOval(
              child: Image.network(
                groupImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildGroupIcon(groupName);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CupertinoActivityIndicator(radius: 10),
                  );
                },
              ),
            )
          : _buildGroupIcon(groupName),
    );
  }

  Widget _buildGroupIcon(String groupName) {
    // Se o nome do grupo tiver pelo menos uma letra, mostra a inicial
    if (groupName.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(groupName)) {
      return Center(
        child: Text(
          groupName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 22,
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Caso contrário, mostra o ícone de grupo
    return Icon(
      CupertinoIcons.group_solid,
      color: CupertinoColors.white,
      size: 28,
    );
  }
}