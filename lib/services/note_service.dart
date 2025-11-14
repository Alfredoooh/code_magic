// lib/services/note_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Note>> getUserNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Note>> getNotesByCategory(String userId, String category) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Note>> getPinnedNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('isPinned', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createNote(Note note) async {
    final docRef = await _firestore.collection('notes').add(note.toMap());
    print('✅ Anotação criada com ID: ${docRef.id}');
  }

  Future<void> updateNote(Note note) async {
    await _firestore.collection('notes').doc(note.id).update(note.toMap());
    print('✅ Anotação atualizada: ${note.id}');
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
    print('✅ Anotação deletada: $noteId');
  }

  Future<void> toggleNotePin(String noteId, bool isPinned) async {
    await _firestore.collection('notes').doc(noteId).update({
      'isPinned': isPinned,
      'updatedAt': Timestamp.now(),
    });
  }
}