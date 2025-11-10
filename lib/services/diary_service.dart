// lib/services/diary_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DiaryEntry>> getUserEntries(String userId) {
    print('🔍 Buscando entradas para userId: $userId');
    
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ ERRO no stream getUserEntries: $error');
          print('   Tipo: ${error.runtimeType}');
          if (error is FirebaseException) {
            print('   Code: ${error.code}');
            print('   Message: ${error.message}');
          }
        })
        .map((snapshot) {
          print('✅ Snapshot recebido: ${snapshot.docs.length} documentos');
          return snapshot.docs.map((doc) {
            try {
              return DiaryEntry.fromFirestore(doc);
            } catch (e) {
              print('❌ Erro ao parsear documento ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  Stream<List<DiaryEntry>> getEntriesByTag(String userId, String tag) {
    print('🔍 Buscando entradas por tag: $tag para userId: $userId');
    
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: tag)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ ERRO no stream getEntriesByTag: $error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  Stream<List<DiaryEntry>> getFavoriteEntries(String userId) {
    print('🔍 Buscando favoritos para userId: $userId');
    
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ ERRO no stream getFavoriteEntries: $error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  Stream<List<DiaryEntry>> getEntriesByMood(String userId, DiaryMood mood) {
    print('🔍 Buscando entradas por mood: $mood para userId: $userId');
    
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('mood', isEqualTo: mood.toString())
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ ERRO no stream getEntriesByMood: $error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  Future<String> createEntry(DiaryEntry entry) async {
    try {
      print('📝 Criando entrada...');
      print('   userId: ${entry.userId}');
      print('   title: ${entry.title}');
      
      final data = entry.toFirestore();
      print('   Data a ser enviada: $data');
      
      final docRef = await _firestore
          .collection('diary_entries')
          .add(data);
      
      print('✅ Entrada criada com sucesso: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ ERRO ao criar entrada: $e');
      print('   Stack: $stackTrace');
      if (e is FirebaseException) {
        print('   Firebase Code: ${e.code}');
        print('   Firebase Message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      print('📝 Atualizando entrada: ${entry.id}');
      
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('diary_entries')
          .doc(entry.id)
          .update(updatedEntry.toFirestore());
      
      print('✅ Entrada atualizada: ${entry.id}');
    } catch (e, stackTrace) {
      print('❌ ERRO ao atualizar entrada: $e');
      print('   Stack: $stackTrace');
      if (e is FirebaseException) {
        print('   Firebase Code: ${e.code}');
        print('   Firebase Message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      print('🗑️ Deletando entrada: $entryId');
      
      await _firestore.collection('diary_entries').doc(entryId).delete();
      
      print('✅ Entrada deletada: $entryId');
    } catch (e, stackTrace) {
      print('❌ ERRO ao deletar entrada: $e');
      print('   Stack: $stackTrace');
      if (e is FirebaseException) {
        print('   Firebase Code: ${e.code}');
        print('   Firebase Message: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(String entryId, bool currentValue) async {
    try {
      print('⭐ Alternando favorito: $entryId (atual: $currentValue)');
      
      await _firestore
          .collection('diary_entries')
          .doc(entryId)
          .update({'isFavorite': !currentValue});
      
      print('✅ Favorito atualizado');
    } catch (e, stackTrace) {
      print('❌ ERRO ao favoritar: $e');
      print('   Stack: $stackTrace');
      rethrow;
    }
  }

  Future<DiaryEntry?> getEntry(String entryId) async {
    try {
      print('🔍 Buscando entrada: $entryId');
      
      final doc = await _firestore
          .collection('diary_entries')
          .doc(entryId)
          .get();
      
      if (doc.exists) {
        print('✅ Entrada encontrada: $entryId');
        return DiaryEntry.fromFirestore(doc);
      }
      
      print('⚠️ Entrada não encontrada: $entryId');
      return null;
    } catch (e, stackTrace) {
      print('❌ ERRO ao buscar entrada: $e');
      print('   Stack: $stackTrace');
      return null;
    }
  }

  Future<List<String>> getUserTags(String userId) async {
    try {
      print('🏷️ Buscando tags do usuário: $userId');
      
      final snapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .get();

      final Set<String> allTags = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['tags'] != null) {
          final tags = List<String>.from(data['tags']);
          allTags.addAll(tags);
        }
      }

      final tagList = allTags.toList()..sort();
      print('✅ ${tagList.length} tags encontradas');
      return tagList;
    } catch (e, stackTrace) {
      print('❌ ERRO ao buscar tags: $e');
      print('   Stack: $stackTrace');
      return [];
    }
  }

  Future<List<DiaryEntry>> searchEntries(String userId, String query) async {
    try {
      print('🔍 Buscando entradas com query: "$query" para userId: $userId');
      
      final snapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .get();

      final entries = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) {
            final titleMatch = entry.title.toLowerCase().contains(query.toLowerCase());
            final contentMatch = entry.content.toLowerCase().contains(query.toLowerCase());
            final tagMatch = entry.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
            return titleMatch || contentMatch || tagMatch;
          })
          .toList();

      entries.sort((a, b) => b.date.compareTo(a.date));
      
      print('✅ ${entries.length} entradas encontradas');
      return entries;
    } catch (e, stackTrace) {
      print('❌ ERRO na busca: $e');
      print('   Stack: $stackTrace');
      return [];
    }
  }
}