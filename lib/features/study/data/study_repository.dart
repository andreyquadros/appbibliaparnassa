import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../../../core/services/firebase_service.dart';
import '../../../models/daily_study.dart';
import '../../../models/quiz_question.dart';

class StudyRepository {
  StudyRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    DateTime Function()? now,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseService.functions,
       _now = now ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final DateTime Function() _now;

  Future<DailyStudy> fetchTodayStudy({bool forceGenerate = false}) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(_now());

    if (forceGenerate) {
      await _generateStudy(dateKey);
    }

    final firstSnapshot = await _firestore
        .collection('dailyStudies')
        .doc(dateKey)
        .get();

    if (!firstSnapshot.exists) {
      await _generateStudy(dateKey);
      final secondSnapshot = await _firestore
          .collection('dailyStudies')
          .doc(dateKey)
          .get();

      if (secondSnapshot.exists) {
        return _fromFirestore(dateKey, secondSnapshot.data() ?? {});
      }
      return _localFallback(dateKey);
    }

    return _fromFirestore(dateKey, firstSnapshot.data() ?? {});
  }

  Future<void> _generateStudy(String dateKey) async {
    try {
      final callable = _functions.httpsCallable('generateStudyNow');
      await callable.call(<String, dynamic>{'dateKey': dateKey});
    } catch (_) {
      // Falha silenciosa: a UI faz fallback local se nao houver documento.
    }
  }

  DailyStudy _fromFirestore(String dateKey, Map<String, dynamic> data) {
    final preset = _fallbackPresetFor(dateKey);
    final rawQuiz = (data['quiz'] as List?) ?? const [];
    final quiz = rawQuiz
        .whereType<Map>()
        .map(
          (item) => QuizQuestion(
            id: _string(item['id'], 'q'),
            question: _string(item['question'], 'Pergunta sem texto'),
            options: ((item['options'] as List?) ?? const [])
                .map((option) => _string(option, ''))
                .where((option) => option.isNotEmpty)
                .toList(growable: false),
            correctIndex: _int(item['answerIndex'], 0),
            explanation: _string(item['explanation'], ''),
          ),
        )
        .where((question) => question.options.length >= 2)
        .toList(growable: false);

    final generatedAt = switch (data['generatedAt']) {
      Timestamp ts => ts.toDate(),
      _ => _now(),
    };

    return DailyStudy(
      dateId: dateKey,
      title: _string(data['title'], preset.title),
      passage: _string(data['passage'], preset.passage),
      mainText: _string(
        data['mainText'],
        _string(data['context'], preset.mainText),
      ),
      historicalContext: _string(data['context'], preset.historicalContext),
      exegesis: _string(data['exegesis'], preset.exegesis),
      application: _string(data['application'], preset.application),
      connection: _string(data['connection'], preset.connection),
      meditation: _string(data['meditation'], preset.meditation),
      memoryVerse: _string(data['memoryVerse'], preset.memoryVerse),
      guidedPrayer: _string(data['guidedPrayer'], preset.guidedPrayer),
      quiz: quiz.isNotEmpty ? quiz : preset.quiz,
      reflectionQuestion: _string(
        data['reflectionQuestion'],
        preset.reflectionQuestion,
      ),
      theme: _string(data['theme'], preset.theme),
      generatedAt: generatedAt,
    );
  }

  String _string(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  int _int(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  DailyStudy _localFallback(String dateKey) {
    final preset = _fallbackPresetFor(dateKey);
    return DailyStudy(
      dateId: dateKey,
      title: preset.title,
      passage: preset.passage,
      mainText: preset.mainText,
      historicalContext: preset.historicalContext,
      exegesis: preset.exegesis,
      application: preset.application,
      connection: preset.connection,
      meditation: preset.meditation,
      memoryVerse: preset.memoryVerse,
      guidedPrayer: preset.guidedPrayer,
      quiz: preset.quiz,
      reflectionQuestion: preset.reflectionQuestion,
      theme: preset.theme,
      generatedAt: _now(),
    );
  }

  _FallbackStudyPreset _fallbackPresetFor(String dateKey) {
    final hash = dateKey.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return _fallbackPresets[hash % _fallbackPresets.length];
  }
}

class _FallbackStudyPreset {
  const _FallbackStudyPreset({
    required this.title,
    required this.passage,
    required this.mainText,
    required this.historicalContext,
    required this.exegesis,
    required this.application,
    required this.connection,
    required this.meditation,
    required this.memoryVerse,
    required this.guidedPrayer,
    required this.quiz,
    required this.reflectionQuestion,
    required this.theme,
  });

  final String title;
  final String passage;
  final String mainText;
  final String historicalContext;
  final String exegesis;
  final String application;
  final String connection;
  final String meditation;
  final String memoryVerse;
  final String guidedPrayer;
  final List<QuizQuestion> quiz;
  final String reflectionQuestion;
  final String theme;
}

const List<_FallbackStudyPreset> _fallbackPresets = <_FallbackStudyPreset>[
  _FallbackStudyPreset(
    title: 'Estudo diário: Permanecer em Cristo',
    passage: 'João 15:1-8',
    mainText:
        'Jesus é a videira verdadeira e convida seus discípulos a permanecerem nEle.',
    historicalContext:
        'Jesus ensina esse texto pouco antes da crucificação, fortalecendo os discípulos para os dias difíceis.',
    exegesis:
        'O fruto espiritual não nasce do esforço isolado, mas da permanência contínua em Cristo.',
    application:
        'Separe hoje alguns minutos para leitura, oração e um ato concreto de obediência.',
    connection:
        'A imagem da videira conversa com textos como Isaías 5, mostrando Cristo como a videira fiel.',
    meditation:
        'Quando permanecemos em Cristo, até o ordinário ganha fruto e direção.',
    memoryVerse: 'João 15:5',
    guidedPrayer:
        'Senhor, mantém meu coração firme em Ti para que minha vida produza fruto hoje.',
    reflectionQuestion:
        'Em que área da sua vida você precisa permanecer mais em Cristo hoje?',
    theme: 'Permanecer em Cristo',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-j15-1',
        question: 'Quem é a videira verdadeira segundo João 15?',
        options: ['Moisés', 'Jesus', 'Pedro', 'Paulo'],
        correctIndex: 1,
        explanation: 'Jesus se apresenta claramente como a videira verdadeira.',
      ),
      QuizQuestion(
        id: 'fallback-j15-2',
        question: 'O que os discípulos precisam fazer para frutificar?',
        options: [
          'Permanecer em Cristo',
          'Viajar mais',
          'Jejuar sem parar',
          'Evitar toda dificuldade',
        ],
        correctIndex: 0,
        explanation:
            'O texto ensina que o fruto nasce da permanência em Cristo.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Confiança no Senhor',
    passage: 'Provérbios 3:5-6',
    mainText:
        'Confiar em Deus envolve entregar o caminho a Ele acima do próprio entendimento.',
    historicalContext:
        'Provérbios reúne instruções de sabedoria para uma vida guiada pelo temor do Senhor.',
    exegesis:
        'A confiança bíblica não é passividade, mas dependência consciente de Deus em cada decisão.',
    application:
        'Antes de uma decisão importante hoje, ore e entregue seu caminho ao Senhor.',
    connection: 'Esse princípio ecoa em textos como Salmo 37:5 e Tiago 1:5.',
    meditation: 'Nem tudo precisa estar claro para que Deus esteja conduzindo.',
    memoryVerse: 'Provérbios 3:5',
    guidedPrayer:
        'Pai, ensina-me a confiar mais na tua direção do que nas minhas próprias conclusões.',
    reflectionQuestion:
        'Qual decisão você precisa colocar diante de Deus com mais confiança?',
    theme: 'Confiança no Senhor',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-pv3-1',
        question: 'Em que o texto diz para não nos apoiarmos?',
        options: [
          'Na tradição',
          'No próprio entendimento',
          'Nos amigos',
          'No silêncio',
        ],
        correctIndex: 1,
        explanation:
            'Provérbios 3 ensina a não se apoiar no próprio entendimento.',
      ),
      QuizQuestion(
        id: 'fallback-pv3-2',
        question: 'O que Deus fará quando reconhecermos seus caminhos?',
        options: [
          'Retirará toda luta',
          'Endireitará as veredas',
          'Aumentará bens',
          'Evitará decisões',
        ],
        correctIndex: 1,
        explanation: 'O texto promete que Deus endireitará as veredas.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Força em tempos difíceis',
    passage: 'Isaías 41:10',
    mainText:
        'Deus encoraja seu povo a não temer, lembrando que Sua presença sustenta em meio ao medo.',
    historicalContext:
        'Isaías fala a um povo marcado por crise, exílio e necessidade de esperança real.',
    exegesis:
        'A ordem para não temer está apoiada na presença e no socorro de Deus, não na força humana.',
    application:
        'Leve hoje sua ansiedade a Deus e lembre-se de uma promessa antes de reagir ao medo.',
    connection:
        'A promessa da presença de Deus aparece em toda a Escritura, de Josué a Mateus 28.',
    meditation: 'O medo perde força quando a presença de Deus ocupa o centro.',
    memoryVerse: 'Isaías 41:10',
    guidedPrayer:
        'Senhor, sustenta-me com tua mão forte e ensina-me a caminhar sem medo hoje.',
    reflectionQuestion: 'Qual medo precisa ser entregue a Deus hoje?',
    theme: 'Coragem e confiança',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-is41-1',
        question: 'Por que o texto diz para não temer?',
        options: [
          'Porque o dia será fácil',
          'Porque Deus está presente',
          'Porque tudo dará certo rápido',
          'Porque a dor acaba logo',
        ],
        correctIndex: 1,
        explanation: 'A razão central é a presença de Deus com seu povo.',
      ),
      QuizQuestion(
        id: 'fallback-is41-2',
        question: 'Com o que Deus promete sustentar seu povo?',
        options: [
          'Com a própria coragem',
          'Com riqueza',
          'Com a sua mão justa',
          'Com sinais imediatos',
        ],
        correctIndex: 2,
        explanation:
            'Isaías 41:10 fala da mão justa do Senhor sustentando seu povo.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: A Palavra ilumina o caminho',
    passage: 'Salmos 119:105',
    mainText:
        'A Palavra de Deus ilumina decisões, corrige rotas e sustenta o coração na caminhada.',
    historicalContext:
        'O Salmo 119 celebra a beleza, a autoridade e a utilidade da lei do Senhor para o povo de Deus.',
    exegesis:
        'A metáfora da lâmpada mostra que Deus nem sempre revela todo o caminho de uma vez, mas oferece luz suficiente para o próximo passo.',
    application:
        'Escolha um versículo hoje e leve-o com você ao longo do dia, consultando-o antes de decisões importantes.',
    connection:
        'Esse ensino se conecta com Josué 1:8 e 2 Timóteo 3:16-17, mostrando a Escritura como guia seguro.',
    meditation:
        'Quem caminha com a Palavra não anda sem direção, mesmo em dias de incerteza.',
    memoryVerse: 'Salmos 119:105',
    guidedPrayer:
        'Senhor, acende tua luz sobre minhas decisões e faz tua Palavra governar meus passos hoje.',
    reflectionQuestion:
        'Que decisão de hoje precisa ser iluminada pela Palavra de Deus?',
    theme: 'Direção pela Palavra',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-sl119-1',
        question: 'Segundo o salmo, a Palavra de Deus é comparada a quê?',
        options: [
          'Uma muralha',
          'Uma lâmpada',
          'Uma coroa',
          'Uma espada sem fio',
        ],
        correctIndex: 1,
        explanation:
            'O texto compara a Palavra a uma lâmpada para os pés e luz para o caminho.',
      ),
      QuizQuestion(
        id: 'fallback-sl119-2',
        question: 'O que essa imagem ensina sobre a orientação de Deus?',
        options: [
          'Deus revela tudo de uma só vez',
          'Deus ignora decisões simples',
          'Deus ilumina a caminhada passo a passo',
          'Deus só fala em momentos extraordinários',
        ],
        correctIndex: 2,
        explanation:
            'A luz da Palavra mostra o caminho à medida que caminhamos com obediência.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Ansiedade rendida em oração',
    passage: 'Filipenses 4:6-7',
    mainText:
        'Paulo ensina que a ansiedade pode ser levada a Deus em oração com súplicas e gratidão.',
    historicalContext:
        'Filipenses foi escrita em contexto de prisão, mostrando que a paz de Deus não depende de circunstâncias fáceis.',
    exegesis:
        'A paz prometida não é ausência de luta, mas a presença guardadora de Deus no coração e na mente.',
    application:
        'Transforme hoje sua maior preocupação em uma oração objetiva, agradecendo a Deus antes mesmo da resposta.',
    connection:
        'Esse chamado ecoa em 1 Pedro 5:7, que nos convida a lançar sobre Deus toda ansiedade.',
    meditation:
        'Quando a ansiedade vira oração, o coração encontra lugar seguro para descansar.',
    memoryVerse: 'Filipenses 4:6',
    guidedPrayer:
        'Pai, receba minhas preocupações e guarda meu coração com a tua paz que excede todo entendimento.',
    reflectionQuestion:
        'Qual preocupação você precisa entregar a Deus em oração hoje?',
    theme: 'Paz e oração',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-fp4-1',
        question: 'O que Paulo orienta fazer no lugar de permanecer ansioso?',
        options: [
          'Esconder a dor',
          'Buscar distrações',
          'Apresentar tudo a Deus em oração',
          'Esperar o tempo resolver sozinho',
        ],
        correctIndex: 2,
        explanation:
            'O texto convida a levar tudo a Deus em oração, súplica e gratidão.',
      ),
      QuizQuestion(
        id: 'fallback-fp4-2',
        question: 'O que a paz de Deus fará segundo Filipenses 4?',
        options: [
          'Eliminar toda dificuldade',
          'Guardar coração e mente',
          'Resolver finanças imediatamente',
          'Afastar todas as pessoas difíceis',
        ],
        correctIndex: 1,
        explanation:
            'A paz de Deus guarda o coração e a mente em Cristo Jesus.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Mente renovada',
    passage: 'Romanos 12:1-2',
    mainText:
        'Paulo chama os cristãos a uma vida de entrega a Deus e transformação pela renovação da mente.',
    historicalContext:
        'Depois de expor o evangelho, Romanos mostra como a graça alcança a vida prática e diária.',
    exegesis:
        'A transformação cristã não é apenas externa; ela alcança pensamentos, valores e critérios de discernimento.',
    application:
        'Observe hoje um padrão de pensamento que precisa ser alinhado à vontade de Deus e confronte-o com a Escritura.',
    connection:
        'Efésios 4:23 e Colossenses 3 reforçam a necessidade de uma mente renovada em Cristo.',
    meditation:
        'Uma mente rendida a Deus aprende a discernir o que realmente tem valor eterno.',
    memoryVerse: 'Romanos 12:2',
    guidedPrayer:
        'Senhor, transforma meus pensamentos e ajusta meu coração para que eu viva de modo agradável a Ti.',
    reflectionQuestion:
        'Que hábito mental Deus está pedindo para você renovar hoje?',
    theme: 'Transformação de vida',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-rm12-1',
        question: 'Como Paulo descreve a entrega da vida a Deus?',
        options: [
          'Sacrifício vivo',
          'Vitória pessoal',
          'Conquista intelectual',
          'Disciplina ocasional',
        ],
        correctIndex: 0,
        explanation:
            'Romanos 12:1 fala de apresentar o corpo como sacrifício vivo, santo e agradável a Deus.',
      ),
      QuizQuestion(
        id: 'fallback-rm12-2',
        question: 'Pelo que acontece a transformação do cristão?',
        options: [
          'Pela pressão social',
          'Pela renovação da mente',
          'Pelo medo do fracasso',
          'Por esforço emocional',
        ],
        correctIndex: 1,
        explanation:
            'O texto destaca a renovação da mente como caminho de transformação.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Buscar primeiro o Reino',
    passage: 'Mateus 6:33',
    mainText:
        'Jesus ensina a priorizar o Reino de Deus acima das preocupações materiais e imediatas.',
    historicalContext:
        'No Sermão do Monte, Jesus confronta a ansiedade e convida a uma confiança prática no cuidado do Pai.',
    exegesis:
        'Buscar primeiro o Reino é reorganizar prioridades, desejos e escolhas à luz da vontade de Deus.',
    application:
        'Antes de planejar o resto do dia, pergunte: esta decisão honra primeiro o Reino de Deus?',
    connection:
        'Esse ensino conversa com Colossenses 3:1-2, que chama o cristão a pensar nas coisas do alto.',
    meditation:
        'Quando o Reino ocupa o primeiro lugar, o restante encontra sua medida correta.',
    memoryVerse: 'Mateus 6:33',
    guidedPrayer:
        'Jesus, alinha minhas prioridades para que eu busque teu Reino antes das minhas próprias urgências.',
    reflectionQuestion:
        'O que precisa sair do centro para que o Reino de Deus ocupe o primeiro lugar hoje?',
    theme: 'Prioridades do Reino',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-mt6-1',
        question: 'O que Jesus manda buscar em primeiro lugar?',
        options: [
          'Segurança financeira',
          'Reconhecimento',
          'O Reino de Deus',
          'Conhecimento acadêmico',
        ],
        correctIndex: 2,
        explanation:
            'Mateus 6:33 coloca o Reino de Deus e sua justiça como prioridade.',
      ),
      QuizQuestion(
        id: 'fallback-mt6-2',
        question: 'Esse ensino aparece em qual contexto do Sermão do Monte?',
        options: [
          'Ansiedade com a vida',
          'Discussão política',
          'Viagem missionária',
          'Jejum coletivo',
        ],
        correctIndex: 0,
        explanation:
            'Jesus fala sobre não viver dominado pela ansiedade material.',
      ),
    ],
  ),
  _FallbackStudyPreset(
    title: 'Estudo diário: Coragem para avançar',
    passage: 'Josué 1:9',
    mainText:
        'Deus chama Josué à coragem lembrando que sua presença acompanha a missão.',
    historicalContext:
        'Após a morte de Moisés, Josué assume uma responsabilidade enorme e precisa confiar na presença de Deus.',
    exegesis:
        'A coragem bíblica nasce da companhia de Deus, não da autoconfiança ou da ausência de oposição.',
    application:
        'Dê hoje um passo de obediência que você vinha adiando por medo ou insegurança.',
    connection:
        'Esse encorajamento reaparece em passagens como Deuteronômio 31 e Hebreus 13.',
    meditation: 'Quem sabe que Deus está presente pode avançar mesmo tremendo.',
    memoryVerse: 'Josué 1:9',
    guidedPrayer:
        'Senhor, fortalece meu coração e ajuda-me a obedecer com coragem onde hoje existe medo.',
    reflectionQuestion:
        'Em que área Deus está chamando você para agir com coragem hoje?',
    theme: 'Coragem na missão',
    quiz: <QuizQuestion>[
      QuizQuestion(
        id: 'fallback-js1-1',
        question: 'Qual expressão se destaca em Josué 1:9?',
        options: [
          'Fica em silêncio',
          'Sê forte e corajoso',
          'Volta atrás',
          'Busca aprovação humana',
        ],
        correctIndex: 1,
        explanation:
            'O chamado central do versículo é para ser forte e corajoso.',
      ),
      QuizQuestion(
        id: 'fallback-js1-2',
        question: 'Por que Josué poderia avançar com coragem?',
        options: [
          'Porque não teria inimigos',
          'Porque Deus estaria com ele',
          'Porque já sabia tudo',
          'Porque era naturalmente confiante',
        ],
        correctIndex: 1,
        explanation: 'A presença de Deus é a base da coragem dada a Josué.',
      ),
    ],
  ),
];
