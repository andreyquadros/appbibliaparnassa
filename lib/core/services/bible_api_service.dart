import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/bible_passage.dart';
import 'local_cache_service.dart';

class BibleApiService {
  BibleApiService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;
  static const _cachePrefix = 'bible_api_cache:';
  static const _cacheTtl = Duration(days: 7);

  Future<BiblePassage> fetchPassage(
    String reference, {
    String translation = 'almeida',
  }) async {
    final normalizedReference = reference.trim();
    if (normalizedReference.isEmpty) {
      throw Exception('Referência bíblica inválida.');
    }

    final key = _cacheKey(normalizedReference, translation);
    final cached = _readCache(key);
    if (cached != null) {
      return cached;
    }

    final uri = Uri.parse(
      'https://bible-api.com/${Uri.encodeComponent(normalizedReference)}'
      '?translation=$translation',
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Falha ao consultar Bíblia API (status ${response.statusCode}).',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw Exception('Resposta inválida da Bíblia API.');
    }

    final parsed = _fromMap(raw);
    _writeCache(key, raw);
    return parsed;
  }

  BiblePassage? _readCache(String key) {
    final item = LocalCacheService.box.get(key);
    if (item is! Map) {
      return null;
    }

    final fetchedAtMillis = item['fetchedAt'] as int?;
    final payload = item['payload'];
    if (fetchedAtMillis == null || payload is! Map) {
      return null;
    }

    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedAtMillis);
    if (_now().difference(fetchedAt) > _cacheTtl) {
      LocalCacheService.box.delete(key);
      return null;
    }

    return _fromMap(Map<String, dynamic>.from(payload));
  }

  void _writeCache(String key, Map<String, dynamic> payload) {
    LocalCacheService.box.put(key, {
      'fetchedAt': _now().millisecondsSinceEpoch,
      'payload': payload,
    });
  }

  String _cacheKey(String reference, String translation) {
    return '$_cachePrefix${translation.toLowerCase()}:${reference.toLowerCase()}';
  }

  BiblePassage _fromMap(Map<String, dynamic> map) {
    final verses = ((map['verses'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => BibleVerse(
            bookName: (item['book_name'] as String?)?.trim() ?? '',
            chapter: _asInt(item['chapter']),
            verse: _asInt(item['verse']),
            text: ((item['text'] as String?) ?? '').trim(),
          ),
        )
        .where((verse) => verse.text.isNotEmpty)
        .toList(growable: false);

    final text = ((map['text'] as String?) ?? '').trim();
    final reference = ((map['reference'] as String?) ?? '').trim();
    final translationId = ((map['translation_id'] as String?) ?? '').trim();

    return BiblePassage(
      reference: reference.isNotEmpty ? reference : 'Referência não informada',
      text: text,
      translationId: translationId.isNotEmpty ? translationId : 'almeida',
      verses: verses,
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
