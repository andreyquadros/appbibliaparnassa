import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_service.dart';

class AiService {
  AiService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseService.functions;

  final FirebaseFunctions _functions;

  Future<String> simplifyStudy(String text) async {
    final callable = _functions.httpsCallable('simplifyStudy');
    final response = await callable.call(<String, dynamic>{'text': text});
    return (response.data as Map)['simplifiedText'] as String;
  }

  Future<String> generateGuidedPrayer({
    required String focus,
    required String verse,
  }) async {
    final callable = _functions.httpsCallable('generateGuidedPrayer');
    final response = await callable.call(<String, dynamic>{
      'theme': '$focus ($verse)',
      'tone': 'grato',
    });
    return (response.data as Map)['guidedPrayer']['prayer'] as String;
  }

  Future<List<Map<String, dynamic>>> searchStrong(String query) async {
    final callable = _functions.httpsCallable('searchStrong');
    final response = await callable.call(<String, dynamic>{'query': query});
    final data = response.data as Map;
    final entries = (data['entries'] as List?) ?? const [];
    return entries
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, String>>> searchVerses(String query) async {
    final callable = _functions.httpsCallable('searchVerses');
    final response = await callable.call(<String, dynamic>{'query': query});
    final data = response.data as Map;
    final items = (data['items'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map(
          (item) => <String, String>{
            'reference': (item['reference'] as String?)?.trim() ?? '',
            'text': (item['text'] as String?)?.trim() ?? '',
            'reason': (item['reason'] as String?)?.trim() ?? '',
          },
        )
        .where((item) => (item['reference'] ?? '').isNotEmpty)
        .toList(growable: false);
  }

  Future<String> explainScripture({
    required String reference,
    required String selectedText,
    String passageText = '',
  }) async {
    final callable = _functions.httpsCallable('explainScripture');
    final response = await callable.call(<String, dynamic>{
      'reference': reference,
      'selectedText': selectedText,
      'passageText': passageText,
    });
    final data = response.data as Map;
    return (data['explanation'] as String?)?.trim().isNotEmpty == true
        ? data['explanation'] as String
        : 'Não foi possível gerar explicação para este texto agora.';
  }

  Future<String> chatScripture({
    required String reference,
    required String passageText,
    required String question,
    List<Map<String, String>> history = const [],
  }) async {
    final callable = _functions.httpsCallable('chatScripture');
    final response = await callable.call(<String, dynamic>{
      'reference': reference,
      'passageText': passageText,
      'question': question,
      'history': history,
    });
    final data = response.data as Map;
    return (data['answer'] as String?)?.trim().isNotEmpty == true
        ? data['answer'] as String
        : 'Não consegui responder agora. Tente novamente.';
  }
}
