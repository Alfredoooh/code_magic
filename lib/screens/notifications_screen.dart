// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 0 = Misto (tudo), 1 = Lidos
  int _selectedSegment = 0;

  static const Color _activeBlue = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final dividerColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    final notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Header fixo com segmento + botão Adicionar
          SliverPersistentHeader(
            pinned: true,
            delegate: _NotificationsHeaderDelegate(
              height: 92,
              backgroundColor: cardColor,
              dividerColor: dividerColor,
              iconColor: iconColor,
              textColor: textColor,
              selectedSegment: _selectedSegment,
              onSegmentChanged: (i) => setState(() => _selectedSegment = i),
              onAddPressed: () {
                // Reutiliza o comportamento do marketplace adicionar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                    backgroundColor: _activeBlue,
                  ),
                );
              },
            ),
          ),

          // StreamBuilder das notificações
          StreamBuilder<QuerySnapshot>(
            stream: notificationsQuery,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // usa o ícone de erro do custom icons
                        SvgIcon(svgString: CustomIcons.errorIcon, size: 72, color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA)),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar notificações',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_activeBlue),
                    ),
                  ),
                );
              }

              final notifications = snapshot.data?.docs ?? [];

              // Aplica filtro de segmento (Misto = tudo, Lidos = apenas isRead == true)
              final filtered = _selectedSegment == 0
                  ? notifications
                  : notifications.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['isRead'] ?? false) == true;
                    }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgIcon(svgString: CustomIcons.bell, size: 80, color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA)),
                        const SizedBox(height: 16),
                        Text(
                          'Sem notificações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Você receberá notificações sobre novas\npublicações, curtidas e comentários',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // SliverList sem divisões visíveis — itens ficam "flush" uns com os outros
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notificationDoc = filtered[index];
                    final data = notificationDoc.data() as Map<String, dynamic>;

                    final type = data['type'] as String? ?? '';
                    final senderName = data['senderName'] ?? 'Alguém';
                    final senderPhotoURL = data['senderPhotoURL'];
                    final isRead = data['isRead'] ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    String notificationText = '';
                    String notificationSemantic = '';
                    IconData fallbackIcon = Icons.notifications;
                    Color notificationColor = _activeBlue;

                    switch (type) {
                      case 'new_post':
                        notificationText = 'publicou algo novo';
                        fallbackIcon = Icons.article;
                        notificationColor = _activeBlue;
                        break;
                      case 'like':
                        notificationText = 'curtiu sua publicação';
                        fallbackIcon = Icons.favorite;
                        notificationColor = const Color(0xFFED4956);
                        break;
                      case 'comment':
                        notificationText = 'comentou sua publicação';
                        fallbackIcon = Icons.comment;
                        notificationColor = const Color(0xFF31A24C);
                        break;
                      case 'follow':
                        notificationText = 'começou a seguir você';
                        fallbackIcon = Icons.person_add;
                        notificationColor = _activeBlue;
                        break;
                      case 'follow_request':
                        notificationText = 'enviou um pedido de seguimento';
                        fallbackIcon = Icons.person_add;
                        notificationColor = _activeBlue;
                        break;
                      default:
                        notificationText = 'interagiu com você';
                    }

                    // Container sem bordas/divisões; apenas padding para separar visualmente
                    return Material(
                      color: isRead ? cardColor : (isDark ? const Color(0xFF2D3236) : const Color(0xFFEAF5FF)),
                      child: InkWell(
                        onTap: () async {
                          // Marca como lida
                          if (!isRead) {
                            await FirebaseFirestore.instance.collection('notifications').doc(notificationDoc.id).update({'isRead': true});
                          }
                          // TODO: Navegar para o conteúdo relevante
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar + small icon
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _activeBlue,
                                    backgroundImage: senderPhotoURL != null ? NetworkImage(senderPhotoURL) : null,
                                    child: senderPhotoURL == null
                                        ? Text(
                                            senderName.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: notificationColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardColor, width: 2),
                                      ),
                                      child: Icon(fallbackIcon, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              // Texto principal e subtítulo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 15, color: textColor),
                                        children: [
                                          TextSpan(text: senderName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          TextSpan(text: ' $notificationText'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (createdAt != null)
                                      Text(
                                        timeago.format(createdAt.toDate(), locale: 'pt_BR'),
                                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Actions:
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Se for pedido de follow, mostrar "Aprovar" que nunca muda de cor
                                  if (type == 'follow_request') ...[
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // exemplo de ação: aceitar follow (implementar lógica real)
                                          // mantém sempre mesma cor independente do tema
                                          await FirebaseFirestore.instance.collection('notifications').doc(notificationDoc.id).update({'isRead': true});
                                          // TODO: adicionar follow logic
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _activeBlue, // nunca muda
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                        child: const Text('Aprovar', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Indicador de não lido — pequeno ponto (se não lido)
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(color: _activeBlue, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Delegate para header fixo com segmentos e botão adicionar
class _NotificationsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color backgroundColor;
  final Color dividerColor;
  final Color iconColor;
  final Color textColor;
  final int selectedSegment;
  final ValueChanged<int> onSegmentChanged;
  final VoidCallback onAddPressed;

  const _NotificationsHeaderDelegate({
    required this.height,
    required this.backgroundColor,
    required this.dividerColor,
    required this.iconColor,
    required this.textColor,
    required this.selectedSegment,
    required this.onSegmentChanged,
    required this.onAddPressed,
  });

  static const Color _activeBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Segment buttons style (iOS-like)
    Widget _segmentButton(String label, int index) {
      final bool active = selectedSegment == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSegmentChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? _activeBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // linha 1: ícone + título
            Row(
              children: [
                SvgIcon(svgString: CustomIcons.bell, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Text('Notificações', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
              ],
            ),
            const SizedBox(height: 10),
            // linha 2: segmentos + botão adicionar
            Row(
              children: [
                // container background to emulate segmented control border
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dividerColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        _segmentButton('Misto', 0),
                        const SizedBox(width: 6),
                        _segmentButton('Lidos', 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // botão adicionar (igual ao marketplace)
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: onAddPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: _activeBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            // divider visual (fina)
            const SizedBox(height: 8),
            Container(height: 0.5, color: dividerColor),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _NotificationsHeaderDelegate oldDelegate) {
    return oldDelegate.selectedSegment != selectedSegment ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dividerColor != dividerColor;
  }
}