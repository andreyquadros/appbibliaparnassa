import 'package:cloud_firestore/cloud_firestore.dart';

class BibleLibraryEntry {
  const BibleLibraryEntry({
    required this.reference,
    required this.translation,
    required this.updatedAtMillis,
    this.displayReference,
    this.bookId,
    this.chapter,
  });

  final String reference;
  final String translation;
  final int updatedAtMillis;
  final String? displayReference;
  final String? bookId;
  final int? chapter;

  String get cacheKey =>
      '${translation.trim().toLowerCase()}|${reference.trim().toLowerCase()}';

  String get resolvedLabel {
    final label = displayReference?.trim() ?? '';
    return label.isNotEmpty ? label : reference.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reference': reference.trim(),
      'translation': translation.trim().toLowerCase(),
      'displayReference': displayReference?.trim(),
      'bookId': bookId?.trim(),
      'chapter': chapter,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  static BibleLibraryEntry? fromDynamic(
    Object? raw, {
    required String fallbackTranslation,
    required int fallbackUpdatedAtMillis,
  }) {
    if (raw is String) {
      final reference = raw.trim();
      if (reference.isEmpty) return null;
      return BibleLibraryEntry(
        reference: reference,
        displayReference: reference,
        translation: fallbackTranslation,
        updatedAtMillis: fallbackUpdatedAtMillis,
      );
    }

    if (raw is Map) {
      final map = raw.cast<Object?, Object?>();
      final reference = (map['reference'] as String? ?? '').trim();
      if (reference.isEmpty) return null;

      final translation =
          ((map['translation'] as String?) ?? fallbackTranslation)
              .trim()
              .toLowerCase();

      final displayReference = (map['displayReference'] as String?)?.trim();
      final bookId = (map['bookId'] as String?)?.trim();
      final chapter = switch (map['chapter']) {
        final int value => value,
        final num value => value.toInt(),
        _ => null,
      };
      final updatedAtMillis = switch (map['updatedAtMillis']) {
        final int value => value,
        final num value => value.toInt(),
        _ => fallbackUpdatedAtMillis,
      };

      return BibleLibraryEntry(
        reference: reference,
        translation: translation.isEmpty ? fallbackTranslation : translation,
        displayReference: displayReference,
        bookId: bookId,
        chapter: chapter,
        updatedAtMillis: updatedAtMillis,
      );
    }

    return null;
  }
}

class BibleLibrarySnapshot {
  const BibleLibrarySnapshot({
    required this.preferredTranslation,
    required this.favorites,
    required this.history,
  });

  final String preferredTranslation;
  final List<BibleLibraryEntry> favorites;
  final List<BibleLibraryEntry> history;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'preferredTranslation': preferredTranslation.trim().toLowerCase(),
      'favorites': favorites
          .map((item) => item.toMap())
          .toList(growable: false),
      'history': history.map((item) => item.toMap()).toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BibleLibraryRepository {
  BibleLibraryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bible')
        .doc('library');
  }

  Future<BibleLibrarySnapshot?> fetch(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    return _fromMap(snapshot.data() ?? const <String, dynamic>{});
  }

  Future<void> save(String uid, BibleLibrarySnapshot state) async {
    await _doc(uid).set(state.toMap(), SetOptions(merge: true));
  }

  BibleLibrarySnapshot _fromMap(Map<String, dynamic> data) {
    final preferredTranslation =
        ((data['preferredTranslation'] as String?) ?? 'almeida')
            .trim()
            .toLowerCase();

    return BibleLibrarySnapshot(
      preferredTranslation: preferredTranslation.isEmpty
          ? 'almeida'
          : preferredTranslation,
      favorites: _entryList(
        data['favorites'],
        fallbackTranslation: preferredTranslation,
      ),
      history: _entryList(
        data['history'],
        fallbackTranslation: preferredTranslation,
      ),
    );
  }

  List<BibleLibraryEntry> _entryList(
    Object? raw, {
    required String fallbackTranslation,
  }) {
    if (raw is! List) {
      return const <BibleLibraryEntry>[];
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final items = <BibleLibraryEntry>[];
    for (var index = 0; index < raw.length; index++) {
      final item = BibleLibraryEntry.fromDynamic(
        raw[index],
        fallbackTranslation: fallbackTranslation,
        fallbackUpdatedAtMillis: now - index,
      );
      if (item != null) {
        items.add(item);
      }
    }

    items.sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));
    return items;
  }
}
