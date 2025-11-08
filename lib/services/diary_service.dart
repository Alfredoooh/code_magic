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
    return _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromFirestore(doc))
            .toList());
  }

  Stream<List<DiaryEntry>> getEntriesByTag(String userId, String tag) {
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

  Stream<List<DiaryEntry>> getFavoriteEntries(String userId) {
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

  Stream<List<DiaryEntry>> getEntriesByMood(String userId, DiaryMood mood) {
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

  Future<String> createEntry(DiaryEntry entry) async {
    try {
      final docRef = await _firestore
          .collection('diary_entries')
          .add(entry.toFirestore());
      print('✅ Entrada criada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar entrada: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      await _firestore
          .collection('diary_entries')
          .doc(entry.id)
          .update(entry.copyWith(updatedAt: DateTime.now()).toFirestore());
      print('✅ Entrada atualizada: ${entry.id}');
    } catch (e) {
      print('❌ Erro ao atualizar entrada: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _firestore.collection('diary_entries').doc(entryId).delete();
      print('✅ Entrada deletada: $entryId');
    } catch (e) {
      print('❌ Erro ao deletar entrada: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String entryId, bool currentValue) async {
    try {
      await _firestore
          .collection('diary_entries')
          .doc(entryId)
          .update({'isFavorite': !currentValue});
    } catch (e) {
      print('❌ Erro ao favoritar: $e');
      rethrow;
    }
  }

  Future<DiaryEntry?> getEntry(String entryId) async {
    try {
      final doc = await _firestore
          .collection('diary_entries')
          .doc(entryId)
          .get();
      
      if (doc.exists) {
        return DiaryEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar entrada: $e');
      return null;
    }
  }

  Future<List<String>> getUserTags(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .get();

      final Set<String> allTags = {};
      for (var doc in snapshot.docs) {
        final tags = List<String>.from(doc.data()['tags'] ?? []);
        allTags.addAll(tags);
      }

      return allTags.toList()..sort();
    } catch (e) {
      print('❌ Erro ao buscar tags: $e');
      return [];
    }
  }

  Future<List<DiaryEntry>> searchEntries(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .get();

      final entries = snapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .where((entry) =>
              entry.title.toLowerCase().contains(query.toLowerCase()) ||
              entry.content.toLowerCase().contains(query.toLowerCase()) ||
              entry.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();

      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (e) {
      print('❌ Erro na busca: $e');
      return [];
    }
  }
}