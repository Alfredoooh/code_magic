import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../group_detail_screen.dart';

class GroupListItem extends StatelessWidget {
  final QueryDocumentSnapshot group;
  final bool isDark;

  const GroupListItem({
    Key? key,
    required this.group,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupData = group.data() as Map<String, dynamic>;
    final members = List.from(groupData['members'] ?? []);

    return Container(
      color: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: CupertinoListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF34C759), Color(0xFF30D158)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            CupertinoIcons.group_solid,
            color: CupertinoColors.white,
            size: 28,
          ),
        ),
        title: Text(
          groupData['name'] ?? 'Grupo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        subtitle: Text(
          '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 15,
          ),
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
}