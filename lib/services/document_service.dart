// lib/services/document_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_template_model.dart';

class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DocumentTemplate>> getTemplates() {
    return _firestore
        .collection('document_templates')
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentTemplate.fromFirestore(doc))
            .toList());
  }

  Stream<List<DocumentTemplate>> getTemplatesByCategory(DocumentCategory category) {
    return _firestore
        .collection('document_templates')
        .where('category', isEqualTo: category.toString())
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentTemplate.fromFirestore(doc))
            .toList());
  }

  Future<String> createTemplate(DocumentTemplate template) async {
    try {
      final docRef = await _firestore
          .collection('document_templates')
          .add(template.toFirestore());
      print('✅ Template criado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar template: $e');
      rethrow;
    }
  }

  Future<void> updateTemplate(DocumentTemplate template) async {
    try {
      await _firestore
          .collection('document_templates')
          .doc(template.id)
          .update(template.toFirestore());
      print('✅ Template atualizado: ${template.id}');
    } catch (e) {
      print('❌ Erro ao atualizar template: $e');
      rethrow;
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore
          .collection('document_templates')
          .doc(templateId)
          .update({'isActive': false});
      print('✅ Template desativado: $templateId');
    } catch (e) {
      print('❌ Erro ao desativar template: $e');
      rethrow;
    }
  }

  Future<void> incrementUsageCount(String templateId) async {
    try {
      await _firestore
          .collection('document_templates')
          .doc(templateId)
          .update({'usageCount': FieldValue.increment(1)});
    } catch (e) {
      print('❌ Erro ao incrementar contador: $e');
    }
  }

  Future<String> createRequest(DocumentRequest request) async {
    try {
      final docRef = await _firestore
          .collection('document_requests')
          .add(request.toFirestore());
      
      await incrementUsageCount(request.templateId);
      
      print('✅ Pedido criado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erro ao criar pedido: $e');
      rethrow;
    }
  }

  Stream<List<DocumentRequest>> getUserRequests(String userId) {
    return _firestore
        .collection('document_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<DocumentRequest>> getAllRequests() {
    return _firestore
        .collection('document_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<DocumentRequest>> getRequestsByStatus(String status) {
    return _firestore
        .collection('document_requests')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentRequest.fromFirestore(doc))
            .toList());
  }

  Stream<int> getUnreadRequestsCount(String userId) {
    return _firestore
        .collection('document_requests')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['in_progress', 'completed'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> updateRequestStatus(
    String requestId, 
    String status, 
    {String? adminNotes}
  ) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
      };
      
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }
      
      await _firestore
          .collection('document_requests')
          .doc(requestId)
          .update(updateData);
      print('✅ Status do pedido atualizado: $requestId');
    } catch (e) {
      print('❌ Erro ao atualizar status: $e');
      rethrow;
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection('document_requests')
          .doc(requestId)
          .delete();
      print('✅ Pedido deletado: $requestId');
    } catch (e) {
      print('❌ Erro ao deletar pedido: $e');
      rethrow;
    }
  }
}