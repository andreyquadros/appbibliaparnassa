import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/community_post.dart';

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  Stream<List<CommunityPost>> watchFeed() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return CommunityPost(
                  id: doc.id,
                  author: _string(data['author'], 'Discípulo'),
                  verse: _string(data['verse'], 'Referência bíblica'),
                  comment: _string(data['comment'], ''),
                  amemCount: _int(data['amemCount']),
                  prayedCount: _int(data['prayedCount']),
                  edifiedCount: _int(data['edifiedCount']),
                  createdAt: _date(data['createdAt']) ?? DateTime.now(),
                );
              })
              .toList(growable: false);
        });
  }

  Future<void> publish({
    required String userId,
    required String author,
    required String verse,
    required String comment,
  }) async {
    await _posts.add(<String, dynamic>{
      'userId': userId,
      'author': author.trim(),
      'verse': verse.trim(),
      'comment': comment.trim(),
      'amemCount': 0,
      'prayedCount': 0,
      'edifiedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
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
