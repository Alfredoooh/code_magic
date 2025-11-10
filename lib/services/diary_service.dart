// lib/services/diary_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna stream de entradas do usuário
  /// REQUER ÍNDICE: userId (Ascending) + date (Descending)
  Stream<List<DiaryEntry>> getUserEntries(String userId) {
    print('📔 getUserEntries: $userId');

    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('✅ ${snapshot.docs.length} entradas recebidas');
          return snapshot.docs
              .map((doc) => DiaryEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Busca entradas por tag
  /// REQUER ÍNDICE: userId (Ascending) + tags (Arrays) + date (Descending)
  Stream<List<DiaryEntry>> getEntriesByTag(String userId, String tag) {
    print('🏷️ getEntriesByTag: $tag');

    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: tag)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  /// Busca entradas favoritas
  /// REQUER ÍNDICE: userId (Ascending) + isFavorite (Ascending) + date (Descending)
  Stream<List<DiaryEntry>> getFavoriteEntries(String userId) {
    print('⭐ getFavoriteEntries');

    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  /// Busca entradas por humor
  /// REQUER ÍNDICE: userId (Ascending) + mood (Ascending) + date (Descending)
  Stream<List<DiaryEntry>> getEntriesByMood(String userId, DiaryMood mood) {
    print('😊 getEntriesByMood: $mood');

    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('mood', isEqualTo: mood.toString())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  /// Cria nova entrada
  Future<String> createEntry(DiaryEntry entry) async {
    print('📝 Criando entrada: ${entry.title}');

    final data = entry.toFirestore();
    final docRef = await _firestore.collection('diary_entries').add(data);

    print('✅ Entrada criada: ${docRef.id}');
    return docRef.id;
  }

  /// Atualiza entrada existente
  Future<void> updateEntry(DiaryEntry entry) async {
    print('📝 Atualizando entrada: ${entry.id}');

    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('diary_entries')
        .doc(entry.id)
        .update(updatedEntry.toFirestore());

    print('✅ Entrada atualizada');
  }

  /// Deleta entrada
  Future<void> deleteEntry(String entryId) async {
    print('🗑️ Deletando entrada: $entryId');

    await _firestore.collection('diary_entries').doc(entryId).delete();

    print('✅ Entrada deletada');
  }

  /// Alterna status de favorito
  Future<void> toggleFavorite(String entryId, bool currentValue) async {
    print('⭐ Alternando favorito: $entryId');

    await _firestore
        .collection('diary_entries')
        .doc(entryId)
        .update({'isFavorite': !currentValue});

    print('✅ Favorito atualizado');
  }

  /// Busca entrada específica
  Future<DiaryEntry?> getEntry(String entryId) async {
    print('🔍 Buscando entrada: $entryId');

    final doc = await _firestore
        .collection('diary_entries')
        .doc(entryId)
        .get();

    if (doc.exists) {
      return DiaryEntry.fromFirestore(doc);
    }
    return null;
  }

  /// Busca todas as tags do usuário
  Future<List<String>> getUserTags(String userId) async {
    print('🏷️ Buscando tags do usuário');

    final snapshot = await _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final Set<String> allTags = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['tags'] != null) {
        allTags.addAll(List<String>.from(data['tags']));
      }
    }

    return allTags.toList()..sort();
  }

  /// Busca entradas (sem query complexa, ordena no cliente)
  Future<List<DiaryEntry>> searchEntries(String userId, String query) async {
    print('🔍 Buscando: "$query"');

    final snapshot = await _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .get();

    final entries = snapshot.docs
        .map((doc) => DiaryEntry.fromFirestore(doc))
        .where((entry) {
          final titleMatch = entry.title.toLowerCase().contains(query.toLowerCase());
          final contentMatch = entry.content.toLowerCase().contains(query.toLowerCase());
          final tagMatch = entry.tags.any((tag) => 
              tag.toLowerCase().contains(query.toLowerCase()));
          return titleMatch || contentMatch || tagMatch;
        })
        .toList();

    entries.sort((a, b) => b.date.compareTo(a.date));

    print('✅ ${entries.length} resultados');
    return entries;
  }
}