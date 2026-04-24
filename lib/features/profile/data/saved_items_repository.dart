import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/saved_item.dart';

class SavedItemsRepository {
  SavedItemsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('savedItems');
  }

  Stream<List<SavedItem>> watchItems(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SavedItem(
                  id: doc.id,
                  title: _string(doc.data()['title'], 'Item salvo'),
                  reference: _string(doc.data()['reference'], ''),
                  excerpt: _string(doc.data()['excerpt'], ''),
                  category: _string(doc.data()['category'], 'geral'),
                  createdAt: _date(doc.data()['createdAt']) ?? DateTime.now(),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<bool> saveItem({
    required String userId,
    required String title,
    required String reference,
    required String excerpt,
    required String category,
  }) async {
    final id = _toDocId(category, reference, title);
    final ref = _collection(userId).doc(id);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return false;
    }

    await ref.set(<String, dynamic>{
      'title': title.trim(),
      'reference': reference.trim(),
      'excerpt': excerpt.trim(),
      'category': category.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<void> removeItem({required String userId, required String itemId}) {
    return _collection(userId).doc(itemId).delete();
  }

  String _toDocId(String category, String reference, String title) {
    return '${category}_$reference$title'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _string(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
