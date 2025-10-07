import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> init() async {
    // Listener para sincronizar dados quando usuário logar
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _syncUserData(user.uid);
      }
    });
  }

  static Future<void> _syncUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        // Sincronizar tema
        final theme = doc.data()?['theme'];
        if (theme != null) {
          // Aplicar tema salvo
        }
      }
    } catch (e) {
      print('Erro ao sincronizar dados: $e');
    }
  }

  static Future<void> updateLastActivity(String activity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('activities').add({
        'activity': activity,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao atualizar atividade: $e');
    }
  }

  static Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update(data);
    } catch (e) {
      print('Erro ao atualizar dados: $e');
    }
  }

  static Stream<DocumentSnapshot> getUserDataStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Erro ao obter dados: $e');
      return null;
    }
  }
}
