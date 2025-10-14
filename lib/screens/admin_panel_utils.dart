import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelUtils {
  static DateTime? extractTimestamp(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = ['created_at', 'createdAt', 'timestamp', 'time', 'created'];
    for (final key in candidates) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) {
        try {
          if (value.toString().length == 10) {
            return DateTime.fromMillisecondsSinceEpoch(value * 1000);
          }
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {}
      }
    }
    return null;
  }

  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Agora';
      }
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}min';
      return 'Agora';
    } catch (e) {
      return 'Agora';
    }
  }

  static double calculateConversionRate(int totalUsers, int proUsers) {
    if (totalUsers == 0) return 0;
    return double.parse(((proUsers / totalUsers) * 100).toStringAsFixed(0));
  }

  static Future<void> editUser(
    BuildContext context, 
    String userId, 
    Map<String, dynamic> userData
  ) async {
    final tokensController = TextEditingController(text: '${userData['tokens'] ?? 0}');
    final usernameController = TextEditingController(text: userData['username'] ?? '');
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: const Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Nome de usuário',
                prefixIcon: Icon(Icons.person)
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokensController,
              decoration: const InputDecoration(
                labelText: 'Tokens',
                prefixIcon: Icon(Icons.monetization_on)
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'), 
            onPressed: () => Navigator.pop(context)
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'username': usernameController.text,
                'tokens': int.tryParse(tokensController.text) ?? 0,
              });
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário atualizado com sucesso'))
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  static Future<void> togglePro(BuildContext context, String userId, bool isPro) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'pro': !isPro
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPro ? 'PRO removido' : 'PRO ativado'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar PRO: $e'))
        );
      }
    }
  }

  static Future<void> toggleAdmin(BuildContext context, String userId, bool isAdmin) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'admin': !isAdmin
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAdmin ? 'Admin removido' : 'Admin ativado'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar admin: $e'))
        );
      }
    }
  }

  static Future<void> banOrUnbanUser(
    BuildContext context,
    String userId, 
    String username, 
    bool isCurrentlyBanned
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'banned': !isCurrentlyBanned,
        'isOnline': false,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isCurrentlyBanned ? '$username desbanido' : '$username foi banido'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao banir/desbanir usuário: $e'))
        );
      }
    }
  }

  static void confirmDeleteUser(
    BuildContext context, 
    String userId, 
    String username,
    Function()? onSuccess,
  ) {
    bool alsoDeleteContent = true;
    
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: const Text('Excluir Usuário'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Irás apagar o documento do utilizador em Firestore para "$username". '
                  'Isto NÃO remove a conta do Firebase Auth. Deseja continuar?'
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: alsoDeleteContent, 
                      onChanged: (v) => setStateSB(() => alsoDeleteContent = v ?? true)
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Remover também posts e mensagens deste usuário')
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'), 
                onPressed: () => Navigator.pop(context)
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteUser(context, userId, alsoDeleteContent);
                  onSuccess?.call();
                },
              ),
            ],
          );
        });
      },
    );
  }

  static Future<void> _deleteUser(BuildContext context, String userId, bool removeContent) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (removeContent) {
        await _deleteUserPostsAndMessages(userId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário excluído do Firestore'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir usuário: $e'))
        );
      }
    }
  }

  static Future<void> _deleteUserPostsAndMessages(String userId) async {
    try {
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var p in postsSnap.docs) {
        try {
          await FirebaseFirestore.instance.collection('posts').doc(p.id).delete();
        } catch (_) {}
      }

      final messagesSnap = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      
      for (var m in messagesSnap.docs) {
        try {
          await FirebaseFirestore.instance.collection('messages').doc(m.id).delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Erro ao apagar conteúdo do usuário: $e');
    }
  }

  static Future<void> deletePost(BuildContext context, String postId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'), 
            onPressed: () => Navigator.pop(c, false)
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deletado com sucesso'))
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar post: $e'))
          );
        }
      }
    }
  }
}