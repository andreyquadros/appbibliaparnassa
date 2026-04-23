const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();
const {FieldValue} = admin.firestore;

const REGION = "southamerica-east1";
const DEFAULT_TIMEZONE = "America/Sao_Paulo";
const XAI_API_URL = process.env.XAI_API_URL || "https://api.x.ai/v1/chat/completions";
const XAI_MODEL = process.env.XAI_MODEL || "grok-2-latest";
const XAI_MODEL_FALLBACKS = ["grok-2-latest", "grok-3-mini"];

const STUDY_THEMES = [
  "Identidade em Cristo",
  "Guerra Espiritual",
  "Salmos para a Alma",
  "Financas a Luz da Palavra",
  "Familia segundo Deus",
  "Como Estudar a Biblia",
  "Oracao e Intimidade",
  "Sabedoria em Proverbios",
];

const SEED_REWARDS = [
  {
    id: "tier1_commentary_matthew_henry",
    title: "Comentario Biblico Extendido",
    description: "Notas simplificadas de Matthew Henry para devocional diario.",
    tier: 1,
    manadasCost: 500,
    category: "Comentario",
    preview: "Panorama historico e aplicacao pratica por passagem.",
    sortOrder: 10,
  },
  {
    id: "tier1_biblical_timeline",
    title: "Linha do Tempo Biblica",
    description: "Do Genesis ao Apocalipse com marcos historicos essenciais.",
    tier: 1,
    manadasCost: 650,
    category: "Historia Biblica",
    preview: "Cronologia visual dos principais eventos das Escrituras.",
    sortOrder: 20,
  },
  {
    id: "tier2_hebrew_for_laypeople",
    title: "Hebraico Basico para Leigos",
    description: "50 termos-chave do AT com aplicacao no estudo pessoal.",
    tier: 2,
    manadasCost: 2000,
    category: "Idioma Biblico",
    preview: "Palavras centrais como shalom, hesed e emunah.",
    sortOrder: 30,
  },
  {
    id: "tier3_prophecies_end_times",
    title: "Profecias do Fim dos Tempos",
    description: "Estudo comparativo em Daniel, Ezequiel e Apocalipse.",
    tier: 3,
    manadasCost: 5000,
    category: "Escatologia",
    preview: "Visoes pre-milenista, amilenista e pos-milenista.",
    sortOrder: 40,
  },
];

const SEED_COMMUNITY_POSTS = [
  {
    userId: "seed-paul",
    author: "Equipe Bíblia Parnassá",
    verse: "Romanos 8:1",
    comment:
      "Nao ha condenacao para os que estao em Cristo Jesus. Caminhe hoje em liberdade.",
  },
  {
    userId: "seed-david",
    author: "Equipe Bíblia Parnassá",
    verse: "Salmos 23:1",
    comment:
      "O Senhor e meu pastor e nada me faltara. Confianca pratica para esta semana.",
  },
  {
    userId: "seed-joshua",
    author: "Equipe Bíblia Parnassá",
    verse: "Josue 1:9",
    comment:
      "Seja forte e corajoso. Deus permanece com voce em cada decisao.",
  },
];

function getDatePartsInTimeZone(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const find = (type) => parts.find((p) => p.type === type)?.value || "";
  return {
    year: find("year"),
    month: find("month"),
    day: find("day"),
  };
}

function getDateKeyInTimeZone(date, timeZone) {
  const d = getDatePartsInTimeZone(date, timeZone);
  return `${d.year}-${d.month}-${d.day}`;
}

function getHourInTimeZone(date, timeZone) {
  return Number(new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    hour12: false,
  }).format(date));
}

function getWeekKey(date) {
  const utc = new Date(Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth(),
      date.getUTCDate(),
  ));
  const day = (utc.getUTCDay() + 6) % 7;
  utc.setUTCDate(utc.getUTCDate() - day);
  return utc.toISOString().slice(0, 10);
}

function requireAuth(request) {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autenticacao obrigatoria.");
  }
  return request.auth.uid;
}

function simplifyText(text) {
  const clean = String(text || "").replace(/\s+/g, " ").trim();
  if (!clean) return "";

  const sentences = clean.split(/(?<=[.!?])\s+/).filter(Boolean);
  if (sentences.length <= 2) {
    return clean;
  }

  const base = sentences.slice(0, 2).join(" ");
  return `${base} Em resumo: foque na ideia central e aplique isso hoje.`;
}

function createPrayer(theme, tone) {
  return {
    theme,
    tone,
    steps: [
      "Respire fundo por 30 segundos e silencie o ambiente.",
      `Agradeca por 3 coisas relacionadas a ${theme}.`,
      `Apresente seu pedido principal sobre ${theme} com sinceridade.`,
      "Finalize com compromisso pratico para hoje.",
    ],
    prayer:
      `Senhor, eu coloco diante de Ti minha area de ${theme}. ` +
      "Guia meus pensamentos, fortalece meu coracao e me ajuda a obedecer " +
      "com fe em cada decisao de hoje. Amem.",
  };
}

function hasXaiKey() {
  return Boolean(process.env.XAI_API_KEY);
}

function sanitizeString(value, fallback = "") {
  if (typeof value !== "string") return fallback;
  const clean = value.trim();
  return clean || fallback;
}

function stripMarkdownCodeFence(text) {
  const raw = String(text || "").trim();
  if (raw.startsWith("```") && raw.endsWith("```")) {
    return raw.replace(/^```[a-zA-Z]*\n?/, "").replace(/```$/, "").trim();
  }
  return raw;
}

function extractFirstJsonBlock(text) {
  const cleaned = stripMarkdownCodeFence(text);
  const match = cleaned.match(/\{[\s\S]*\}/);
  if (!match) {
    throw new Error("Resposta de IA sem JSON valido.");
  }
  return JSON.parse(match[0]);
}

function pickChatContent(apiResponse) {
  const choice = apiResponse?.choices?.[0]?.message?.content;

  if (typeof choice === "string") {
    return choice;
  }

  if (Array.isArray(choice)) {
    return choice
        .map((part) => part?.text || "")
        .join("\n")
        .trim();
  }

  return "";
}

function xaiModelCandidates() {
  return [XAI_MODEL, ...XAI_MODEL_FALLBACKS]
      .map((m) => sanitizeString(m))
      .filter((m, index, list) => m && list.indexOf(m) === index);
}

async function callXai({systemPrompt, userPrompt, temperature = 0.2}) {
  if (!hasXaiKey()) {
    throw new Error("XAI_API_KEY nao configurada.");
  }

  let lastError = null;
  const candidates = xaiModelCandidates();
  for (const model of candidates) {
    try {
      const payload = {
        model,
        stream: false,
        temperature,
        messages: [
          {role: "system", content: systemPrompt},
          {role: "user", content: userPrompt},
        ],
      };

      const response = await fetch(XAI_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${process.env.XAI_API_KEY}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const body = await response.text();
        lastError = new Error(`xAI API error ${response.status} (${model}): ${body}`);
        continue;
      }

      const data = await response.json();
      const content = pickChatContent(data);
      if (content) {
        return content;
      }
      lastError = new Error(`xAI retornou resposta vazia (${model}).`);
    } catch (error) {
      lastError = error;
    }
  }

  throw new Error(String(lastError || "xAI indisponivel."));
}

async function callXaiForJson({systemPrompt, userPrompt, temperature = 0.2}) {
  const content = await callXai({systemPrompt, userPrompt, temperature});
  return extractFirstJsonBlock(content);
}

const FALLBACK_STUDIES = [
  {
    title: "Estudo Diario: Permanecer em Cristo",
    theme: "Permanecer em Cristo",
    passage: "Joao 15:1-8",
    context:
      "Jesus ensina os discipulos sobre permanecer nEle na noite anterior a crucificacao.",
    exegesis:
      "Permanecer aponta para continuidade de comunhao, obediencia e dependencia de Cristo.",
    application:
      "Separe hoje 15 minutos para leitura biblica, oracao e uma acao de obediencia pratica.",
    connection:
      "Israel falhou como vinha (Isaias 5), mas Cristo cumpre perfeitamente o papel da videira fiel.",
    meditation:
      "Sem Cristo, esforco vira cansaco; com Cristo, esforco vira fruto.",
    memoryVerse: "Joao 15:5",
    guidedPrayer:
      "Senhor, ajuda-me a permanecer em Ti hoje, para que minha vida produza fruto que glorifique teu nome.",
    reflectionQuestion:
      "Qual decisao concreta de obediencia voce vai praticar ainda hoje?",
    quiz: [
      {
        question: "Quem e a videira verdadeira em Joao 15?",
        options: ["Moisés", "Jesus", "Paulo", "Pedro"],
        answerIndex: 1,
        explanation: "Jesus afirma explicitamente: Eu sou a videira verdadeira.",
      },
      {
        question: "Qual e a condicao para frutificar segundo o texto?",
        options: ["Acumular conhecimento", "Permanecer em Cristo", "Jejuar sempre", "Nunca errar"],
        answerIndex: 1,
        explanation: "O fruto nasce da permanencia em Cristo, nao de autoesforco isolado.",
      },
    ],
  },
  {
    title: "Estudo Diario: Confianca no Senhor",
    theme: "Confianca no Senhor",
    passage: "Proverbios 3:5-6",
    context:
      "Proverbios reune instrucoes de sabedoria para uma vida guiada pelo temor do Senhor.",
    exegesis:
      "A confianca biblica envolve depender de Deus acima do proprio entendimento.",
    application:
      "Antes de uma decisao importante hoje, ore e entregue conscientemente o seu caminho ao Senhor.",
    connection:
      "Esse principio ecoa em Salmo 37:5 e Tiago 1:5.",
    meditation:
      "Nem tudo precisa estar claro para que Deus esteja conduzindo.",
    memoryVerse: "Proverbios 3:5",
    guidedPrayer:
      "Pai, ensina-me a confiar mais na tua direcao do que nas minhas proprias conclusoes.",
    reflectionQuestion:
      "Qual decisao voce precisa colocar diante de Deus com mais confianca?",
    quiz: [
      {
        question: "Em que o texto diz para nao nos apoiarmos?",
        options: ["Na tradicao", "No proprio entendimento", "Nos amigos", "No silencio"],
        answerIndex: 1,
        explanation: "Proverbios 3 ensina a nao se apoiar no proprio entendimento.",
      },
      {
        question: "O que Deus fara quando reconhecermos seus caminhos?",
        options: ["Retirara toda luta", "Endireitara as veredas", "Aumentara bens", "Evitará decisoes"],
        answerIndex: 1,
        explanation: "O texto promete que Deus endireitara as veredas.",
      },
    ],
  },
  {
    title: "Estudo Diario: Forca em tempos dificeis",
    theme: "Coragem e confianca",
    passage: "Isaias 41:10",
    context:
      "Isaias fala a um povo marcado por crise, exilio e necessidade de esperanca real.",
    exegesis:
      "A ordem para nao temer esta apoiada na presenca e no socorro de Deus, nao na forca humana.",
    application:
      "Leve hoje sua ansiedade a Deus e lembre-se de uma promessa antes de reagir ao medo.",
    connection:
      "A promessa da presenca de Deus aparece em toda a Escritura, de Josue a Mateus 28.",
    meditation:
      "O medo perde forca quando a presenca de Deus ocupa o centro.",
    memoryVerse: "Isaias 41:10",
    guidedPrayer:
      "Senhor, sustenta-me com tua mao forte e ensina-me a caminhar sem medo hoje.",
    reflectionQuestion:
      "Qual medo precisa ser entregue a Deus hoje?",
    quiz: [
      {
        question: "Por que o texto diz para nao temer?",
        options: ["Porque o dia sera facil", "Porque Deus esta presente", "Porque tudo dara certo rapido", "Porque a dor acaba logo"],
        answerIndex: 1,
        explanation: "A razao central e a presenca de Deus com seu povo.",
      },
      {
        question: "Com o que Deus promete sustentar seu povo?",
        options: ["Com a propria coragem", "Com riqueza", "Com a sua mao justa", "Com sinais imediatos"],
        answerIndex: 2,
        explanation: "Isaias 41:10 fala da mao justa do Senhor sustentando seu povo.",
      },
    ],
  },
  {
    title: "Estudo Diario: A Palavra ilumina o caminho",
    theme: "Direcao pela Palavra",
    passage: "Salmos 119:105",
    context:
      "O Salmo 119 celebra a beleza, a autoridade e a utilidade da lei do Senhor para o povo de Deus.",
    exegesis:
      "A metafora da lampada mostra que Deus oferece luz suficiente para o proximo passo.",
    application:
      "Escolha um versiculo hoje e leve-o com voce ao longo do dia antes das decisoes importantes.",
    connection:
      "Esse ensino se conecta com Josue 1:8 e 2 Timoteo 3:16-17.",
    meditation:
      "Quem caminha com a Palavra nao anda sem direcao, mesmo em dias de incerteza.",
    memoryVerse: "Salmos 119:105",
    guidedPrayer:
      "Senhor, acende tua luz sobre minhas decisoes e faz tua Palavra governar meus passos hoje.",
    reflectionQuestion:
      "Que decisao de hoje precisa ser iluminada pela Palavra de Deus?",
    quiz: [
      {
        question: "Segundo o salmo, a Palavra de Deus e comparada a que?",
        options: ["Uma muralha", "Uma lampada", "Uma coroa", "Uma espada sem fio"],
        answerIndex: 1,
        explanation: "O texto compara a Palavra a uma lampada para os pes e luz para o caminho.",
      },
      {
        question: "O que essa imagem ensina sobre a orientacao de Deus?",
        options: ["Deus revela tudo de uma so vez", "Deus ignora decisoes simples", "Deus ilumina a caminhada passo a passo", "Deus so fala em momentos extraordinarios"],
        answerIndex: 2,
        explanation: "A luz da Palavra mostra o caminho a medida que caminhamos com obediencia.",
      },
    ],
  },
  {
    title: "Estudo Diario: Ansiedade rendida em oracao",
    theme: "Paz e oracao",
    passage: "Filipenses 4:6-7",
    context:
      "Filipenses foi escrita em contexto de prisao, mostrando que a paz de Deus nao depende de circunstancias faceis.",
    exegesis:
      "A paz prometida nao e ausencia de luta, mas a presenca guardadora de Deus no coracao e na mente.",
    application:
      "Transforme hoje sua maior preocupacao em uma oracao objetiva, agradecendo a Deus antes mesmo da resposta.",
    connection:
      "Esse chamado ecoa em 1 Pedro 5:7, que nos convida a lancar sobre Deus toda ansiedade.",
    meditation:
      "Quando a ansiedade vira oracao, o coracao encontra lugar seguro para descansar.",
    memoryVerse: "Filipenses 4:6",
    guidedPrayer:
      "Pai, recebe minhas preocupacoes e guarda meu coracao com a tua paz que excede todo entendimento.",
    reflectionQuestion:
      "Qual preocupacao voce precisa entregar a Deus em oracao hoje?",
    quiz: [
      {
        question: "O que Paulo orienta fazer no lugar de permanecer ansioso?",
        options: ["Esconder a dor", "Buscar distracoes", "Apresentar tudo a Deus em oracao", "Esperar o tempo resolver sozinho"],
        answerIndex: 2,
        explanation: "O texto convida a levar tudo a Deus em oracao, suplica e gratidao.",
      },
      {
        question: "O que a paz de Deus fara segundo Filipenses 4?",
        options: ["Eliminar toda dificuldade", "Guardar coracao e mente", "Resolver financas imediatamente", "Afastar todas as pessoas dificeis"],
        answerIndex: 1,
        explanation: "A paz de Deus guarda o coracao e a mente em Cristo Jesus.",
      },
    ],
  },
  {
    title: "Estudo Diario: Mente renovada",
    theme: "Transformacao de vida",
    passage: "Romanos 12:1-2",
    context:
      "Depois de expor o evangelho, Romanos mostra como a graca alcanca a vida pratica e diaria.",
    exegesis:
      "A transformacao crista alcanca pensamentos, valores e criterios de discernimento.",
    application:
      "Observe hoje um padrao de pensamento que precisa ser alinhado a vontade de Deus.",
    connection:
      "Efesios 4:23 e Colossenses 3 reforcam a necessidade de uma mente renovada em Cristo.",
    meditation:
      "Uma mente rendida a Deus aprende a discernir o que realmente tem valor eterno.",
    memoryVerse: "Romanos 12:2",
    guidedPrayer:
      "Senhor, transforma meus pensamentos e ajusta meu coracao para que eu viva de modo agradavel a Ti.",
    reflectionQuestion:
      "Que habito mental Deus esta pedindo para voce renovar hoje?",
    quiz: [
      {
        question: "Como Paulo descreve a entrega da vida a Deus?",
        options: ["Sacrificio vivo", "Vitoria pessoal", "Conquista intelectual", "Disciplina ocasional"],
        answerIndex: 0,
        explanation: "Romanos 12:1 fala de apresentar o corpo como sacrificio vivo, santo e agradavel a Deus.",
      },
      {
        question: "Pelo que acontece a transformacao do cristao?",
        options: ["Pela pressao social", "Pela renovacao da mente", "Pelo medo do fracasso", "Por esforco emocional"],
        answerIndex: 1,
        explanation: "O texto destaca a renovacao da mente como caminho de transformacao.",
      },
    ],
  },
  {
    title: "Estudo Diario: Buscar primeiro o Reino",
    theme: "Prioridades do Reino",
    passage: "Mateus 6:33",
    context:
      "No Sermao do Monte, Jesus confronta a ansiedade e convida a uma confianca pratica no cuidado do Pai.",
    exegesis:
      "Buscar primeiro o Reino e reorganizar prioridades, desejos e escolhas a luz da vontade de Deus.",
    application:
      "Antes de planejar o resto do dia, pergunte se sua decisao honra primeiro o Reino de Deus.",
    connection:
      "Esse ensino conversa com Colossenses 3:1-2, que chama o cristao a pensar nas coisas do alto.",
    meditation:
      "Quando o Reino ocupa o primeiro lugar, o restante encontra sua medida correta.",
    memoryVerse: "Mateus 6:33",
    guidedPrayer:
      "Jesus, alinha minhas prioridades para que eu busque teu Reino antes das minhas proprias urgencias.",
    reflectionQuestion:
      "O que precisa sair do centro para que o Reino de Deus ocupe o primeiro lugar hoje?",
    quiz: [
      {
        question: "O que Jesus manda buscar em primeiro lugar?",
        options: ["Seguranca financeira", "Reconhecimento", "O Reino de Deus", "Conhecimento academico"],
        answerIndex: 2,
        explanation: "Mateus 6:33 coloca o Reino de Deus e sua justica como prioridade.",
      },
      {
        question: "Esse ensino aparece em qual contexto do Sermao do Monte?",
        options: ["Ansiedade com a vida", "Discussao politica", "Viagem missionaria", "Jejum coletivo"],
        answerIndex: 0,
        explanation: "Jesus fala sobre nao viver dominado pela ansiedade material.",
      },
    ],
  },
  {
    title: "Estudo Diario: Coragem para avancar",
    theme: "Coragem na missao",
    passage: "Josue 1:9",
    context:
      "Apos a morte de Moises, Josue assume uma responsabilidade enorme e precisa confiar na presenca de Deus.",
    exegesis:
      "A coragem biblica nasce da companhia de Deus, nao da autoconfianca ou da ausencia de oposicao.",
    application:
      "De hoje um passo de obediencia que voce vinha adiando por medo ou inseguranca.",
    connection:
      "Esse encorajamento reaparece em Deuteronomio 31 e Hebreus 13.",
    meditation:
      "Quem sabe que Deus esta presente pode avancar mesmo tremendo.",
    memoryVerse: "Josue 1:9",
    guidedPrayer:
      "Senhor, fortalece meu coracao e ajuda-me a obedecer com coragem onde hoje existe medo.",
    reflectionQuestion:
      "Em que area Deus esta chamando voce para agir com coragem hoje?",
    quiz: [
      {
        question: "Qual expressao se destaca em Josue 1:9?",
        options: ["Fica em silencio", "Se forte e corajoso", "Volta atras", "Busca aprovacao humana"],
        answerIndex: 1,
        explanation: "O chamado central do versiculo e para ser forte e corajoso.",
      },
      {
        question: "Por que Josue poderia avancar com coragem?",
        options: ["Porque nao teria inimigos", "Porque Deus estaria com ele", "Porque ja sabia tudo", "Porque era naturalmente confiante"],
        answerIndex: 1,
        explanation: "A presenca de Deus e a base da coragem dada a Josue.",
      },
    ],
  },
];

function fallbackStudySeedForDate(dateKey) {
  const hash = Array.from(String(dateKey))
      .reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return FALLBACK_STUDIES[hash % FALLBACK_STUDIES.length];
}

function fallbackStudy(theme, dateKey) {
  const preset = fallbackStudySeedForDate(dateKey);
  return {
    title: preset.title,
    theme: preset.theme || theme,
    passage: preset.passage,
    context: preset.context,
    exegesis: preset.exegesis,
    application: preset.application,
    connection: preset.connection,
    meditation: preset.meditation,
    memoryVerse: preset.memoryVerse,
    guidedPrayer: preset.guidedPrayer,
    reflectionQuestion: preset.reflectionQuestion,
    quiz: preset.quiz,
    dateKey,
    source: "fallback",
  };
}

function normalizeQuiz(rawQuiz) {
  const quizList = Array.isArray(rawQuiz) ? rawQuiz : [];
  return quizList
      .slice(0, 5)
      .map((item) => ({
        question: sanitizeString(item?.question, "Pergunta sem texto"),
        options: Array.isArray(item?.options) ? item.options.slice(0, 4).map((o) => sanitizeString(o, "")) : [],
        answerIndex: Number.isInteger(item?.answerIndex) ? item.answerIndex : 0,
        explanation: sanitizeString(item?.explanation, ""),
      }))
      .filter((item) => item.options.length >= 2);
}

function normalizeStudy(raw, theme, dateKey) {
  const safe = raw || {};
  const fallback = fallbackStudy(theme, dateKey);
  const quiz = normalizeQuiz(safe.quiz);

  return {
    title: sanitizeString(safe.title, fallback.title),
    theme: sanitizeString(safe.theme, fallback.theme),
    passage: sanitizeString(safe.passage, fallback.passage),
    context: sanitizeString(safe.context, fallback.context),
    exegesis: sanitizeString(safe.exegesis, fallback.exegesis),
    application: sanitizeString(safe.application, fallback.application),
    connection: sanitizeString(safe.connection, fallback.connection),
    meditation: sanitizeString(safe.meditation, fallback.meditation),
    memoryVerse: sanitizeString(safe.memoryVerse, fallback.memoryVerse),
    guidedPrayer: sanitizeString(safe.guidedPrayer, fallback.guidedPrayer),
    reflectionQuestion: sanitizeString(
        safe.reflectionQuestion,
        fallback.reflectionQuestion,
    ),
    quiz: quiz.length > 0 ? quiz : fallback.quiz,
    dateKey,
    source: "xai",
  };
}

async function generateDailyStudyWithXai(dateKey, theme) {
  if (!hasXaiKey()) {
    logger.warn("XAI_API_KEY ausente. Usando fallback para estudo diario.");
    return fallbackStudy(theme, dateKey);
  }

  const systemPrompt = [
    "Voce e um teologo protestante reformado.",
    "Crie um estudo biblico diario profundo, fiel as Escrituras e pastoral.",
    "Use somente o canon protestante de 66 livros.",
    "Retorne APENAS JSON valido, sem markdown.",
  ].join(" ");

  const userPrompt = `
Data do estudo: ${dateKey}
Tema: ${theme}
Idioma: portugues (pt-BR)

Retorne JSON no formato:
{
  "title": "...",
  "theme": "...",
  "passage": "...",
  "context": "...",
  "exegesis": "...",
  "application": "...",
  "connection": "...",
  "meditation": "...",
  "memoryVerse": "...",
  "guidedPrayer": "...",
  "reflectionQuestion": "...",
  "quiz": [
    {
      "question": "...",
      "options": ["...", "...", "...", "..."],
      "answerIndex": 0,
      "explanation": "..."
    }
  ]
}

Regras:
- Gere 5 perguntas no quiz.
- Traga referencias biblicas no texto quando adequado.
- Evite linguagem polemica desnecessaria.
`.trim();

  try {
    const raw = await callXaiForJson({
      systemPrompt,
      userPrompt,
      temperature: 0.35,
    });
    return normalizeStudy(raw, theme, dateKey);
  } catch (error) {
    logger.error("Falha ao gerar estudo com xAI. Usando fallback.", {
      error: String(error),
      dateKey,
      model: XAI_MODEL,
    });
    return fallbackStudy(theme, dateKey);
  }
}

async function rebuildWeeklyRanks(weekKey) {
  const rankingRef = db.collection("weeklyRankings").doc(weekKey);
  const snapshot = await rankingRef
      .collection("entries")
      .orderBy("score", "desc")
      .orderBy("updatedAt", "asc")
      .limit(300)
      .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  let rank = 1;
  snapshot.docs.forEach((doc) => {
    batch.set(doc.ref, {
      rank,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    rank += 1;
  });
  await batch.commit();
  return snapshot.size;
}

exports.generateDailyStudy = onSchedule(
    {
      region: REGION,
      schedule: "0 3 * * *",
      timeZone: "Etc/UTC",
      retryCount: 1,
    },
    async () => {
      const now = new Date();
      const dateKey = getDateKeyInTimeZone(now, DEFAULT_TIMEZONE);
      const studyRef = db.collection("dailyStudies").doc(dateKey);
      const theme = STUDY_THEMES[now.getDate() % STUDY_THEMES.length];
      const study = await generateDailyStudyWithXai(dateKey, theme);

      await studyRef.set({
        ...study,
        status: "published",
        generatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      logger.info("Daily study generated", {dateKey, source: study.source});
    },
);

exports.generateStudyNow = onCall({region: REGION}, async (request) => {
  requireAuth(request);

  const now = new Date();
  const requestedDate = String(request.data?.dateKey || "").trim();
  const dateKey = requestedDate || getDateKeyInTimeZone(now, DEFAULT_TIMEZONE);
  const themeInput = String(request.data?.theme || "").trim();
  const fallbackTheme = STUDY_THEMES[now.getDate() % STUDY_THEMES.length];
  const theme = themeInput || fallbackTheme;

  const study = await generateDailyStudyWithXai(dateKey, theme);
  await db.collection("dailyStudies").doc(dateKey).set({
    ...study,
    status: "published",
    generatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    dateKey,
    source: study.source,
    study,
  };
});

exports.seedInitialContent = onCall({region: REGION}, async (request) => {
  requireAuth(request);

  let rewardsSeeded = 0;
  let communitySeeded = 0;
  let studyCreated = false;

  const rewardsSnap = await db.collection("rewards").limit(1).get();
  if (rewardsSnap.empty) {
    const rewardBatch = db.batch();
    for (const reward of SEED_REWARDS) {
      const rewardRef = db.collection("rewards").doc(reward.id);
      rewardBatch.set(rewardRef, {
        ...reward,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      rewardsSeeded += 1;
    }
    await rewardBatch.commit();
  }

  const communitySnap = await db.collection("communityPosts").limit(1).get();
  if (communitySnap.empty) {
    const communityBatch = db.batch();
    for (const post of SEED_COMMUNITY_POSTS) {
      const postRef = db.collection("communityPosts").doc();
      communityBatch.set(postRef, {
        ...post,
        amemCount: 0,
        prayedCount: 0,
        edifiedCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      communitySeeded += 1;
    }
    await communityBatch.commit();
  }

  const now = new Date();
  const dateKey = getDateKeyInTimeZone(now, DEFAULT_TIMEZONE);
  const studyRef = db.collection("dailyStudies").doc(dateKey);
  const studySnap = await studyRef.get();
  if (!studySnap.exists) {
    const theme = STUDY_THEMES[now.getDate() % STUDY_THEMES.length];
    const study = await generateDailyStudyWithXai(dateKey, theme);
    await studyRef.set({
      ...study,
      status: "published",
      generatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    studyCreated = true;
  }

  return {
    ok: true,
    rewardsSeeded,
    communitySeeded,
    studyCreated,
  };
});

exports.updateWeeklyRankings = onSchedule(
    {
      region: REGION,
      schedule: "15 3 * * 1",
      timeZone: "Etc/UTC",
      retryCount: 1,
    },
    async () => {
      const weekKey = getWeekKey(new Date());
      const rankingRef = db.collection("weeklyRankings").doc(weekKey);
      const usersSnap = await db
          .collection("users")
          .orderBy("weekXp", "desc")
          .limit(300)
          .get();

      const batch = db.batch();
      let rank = 1;
      usersSnap.docs.forEach((userDoc) => {
        const data = userDoc.data() || {};
        const score = Number(data.weekXp || 0);
        const entryRef = rankingRef.collection("entries").doc(userDoc.id);
        batch.set(entryRef, {
          userId: userDoc.id,
          displayName: data.displayName || "Usuario",
          photoUrl: data.photoUrl || null,
          score,
          rank,
          weekKey,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
        rank += 1;
      });

      batch.set(rankingRef, {
        weekKey,
        generatedAt: FieldValue.serverTimestamp(),
        entryCount: usersSnap.size,
      }, {merge: true});

      await batch.commit();
      logger.info("Weekly ranking refreshed", {weekKey, count: usersSnap.size});
    },
);

exports.streakRiskNotification = onSchedule(
    {
      region: REGION,
      schedule: "0 * * * *",
      timeZone: "Etc/UTC",
      retryCount: 0,
    },
    async () => {
      const now = new Date();
      const usersSnap = await db
          .collection("users")
          .where("notificationsEnabled", "==", true)
          .limit(500)
          .get();

      let queued = 0;

      for (const userDoc of usersSnap.docs) {
        const user = userDoc.data() || {};
        const tz = user.timezone || DEFAULT_TIMEZONE;
        const localHour = getHourInTimeZone(now, tz);

        if (localHour !== 22) continue;

        const lastStudyDate = user.lastStudyAt?.toDate ?
          getDateKeyInTimeZone(user.lastStudyAt.toDate(), tz) :
          null;
        const todayDate = getDateKeyInTimeZone(now, tz);
        const alreadyStudiedToday = lastStudyDate === todayDate;

        if (alreadyStudiedToday) continue;

        const notificationId = `${todayDate}_streak_risk`;
        const notificationRef = db
            .collection("users")
            .doc(userDoc.id)
            .collection("notificationQueue")
            .doc(notificationId);

        await notificationRef.set({
          type: "streak_risk",
          title: "Sua sequencia esta em risco",
          body: "Faltam poucos minutos para manter seu streak ativo hoje.",
          localeDate: todayDate,
          timezone: tz,
          createdAt: FieldValue.serverTimestamp(),
        }, {merge: true});

        queued += 1;
      }

      logger.info("Streak risk notifications queued", {queued});
    },
);

exports.simplifyStudy = onCall({region: REGION}, async (request) => {
  requireAuth(request);
  const text = String(request.data?.text || "").trim();

  if (!text) {
    throw new HttpsError("invalid-argument", "Campo 'text' e obrigatorio.");
  }

  if (!hasXaiKey()) {
    return {
      simplifiedText: simplifyText(text),
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  try {
    const systemPrompt =
      "Resuma textos biblicos em portugues claro, sem perder fidelidade teologica.";
    const userPrompt = `Resuma o texto a seguir em ate 5 frases simples para novo convertido:\n\n${text}`;
    const simplifiedText = await callXai({
      systemPrompt,
      userPrompt,
      temperature: 0.15,
    });

    return {
      simplifiedText,
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI simplifyStudy", {error: String(error)});
    return {
      simplifiedText: simplifyText(text),
      source: "fallback",
      aiIntegration: "Falha no xAI; fallback local.",
    };
  }
});

exports.generateGuidedPrayer = onCall({region: REGION}, async (request) => {
  requireAuth(request);
  const theme = String(request.data?.theme || "sabedoria");
  const tone = String(request.data?.tone || "grato");

  if (!hasXaiKey()) {
    return {
      guidedPrayer: createPrayer(theme, tone),
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  const systemPrompt =
    "Voce escreve oracoes guiadas cristas, biblicas e pastorais em portugues.";
  const userPrompt = `
Tema: ${theme}
Tom: ${tone}
Retorne apenas JSON:
{
  "theme": "...",
  "tone": "...",
  "steps": ["...", "...", "...", "..."],
  "prayer": "..."
}
`.trim();

  try {
    const raw = await callXaiForJson({
      systemPrompt,
      userPrompt,
      temperature: 0.4,
    });

    return {
      guidedPrayer: {
        theme: sanitizeString(raw.theme, theme),
        tone: sanitizeString(raw.tone, tone),
        steps: Array.isArray(raw.steps) && raw.steps.length > 0 ?
          raw.steps.slice(0, 6).map((s) => sanitizeString(s, "")) :
          createPrayer(theme, tone).steps,
        prayer: sanitizeString(raw.prayer, createPrayer(theme, tone).prayer),
      },
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI generateGuidedPrayer", {error: String(error)});
    return {
      guidedPrayer: createPrayer(theme, tone),
      source: "fallback",
      aiIntegration: "Falha no xAI; fallback local.",
    };
  }
});

function fallbackExplanation(reference, selectedText) {
  return [
    `Texto: ${selectedText}`,
    `Referencia: ${reference}`,
    "Leitura guiada:",
    "1) Observe o que o texto revela sobre Deus.",
    "2) Identifique o principio central para a vida diaria.",
    "3) Transforme esse principio em uma pratica concreta hoje.",
  ].join("\n");
}

function sanitizeChatHistory(rawHistory) {
  if (!Array.isArray(rawHistory)) {
    return [];
  }

  return rawHistory
      .slice(-10)
      .map((item) => ({
        role: item?.role === "assistant" ? "assistant" : "user",
        content: sanitizeString(item?.content, "").slice(0, 1200),
      }))
      .filter((item) => item.content);
}

exports.explainScripture = onCall({region: REGION}, async (request) => {
  requireAuth(request);
  const reference = sanitizeString(request.data?.reference, "Referencia biblica");
  const selectedText = sanitizeString(request.data?.selectedText, "");
  const passageText = sanitizeString(request.data?.passageText, "");

  if (!selectedText) {
    throw new HttpsError(
        "invalid-argument",
        "Campo 'selectedText' e obrigatorio.",
    );
  }

  if (!hasXaiKey()) {
    return {
      explanation: fallbackExplanation(reference, selectedText),
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  const systemPrompt =
    "Voce e um tutor biblico protestante reformado em portugues. Explique texto com clareza, fidelidade e aplicacao.";
  const userPrompt = `
Referencia: ${reference}
Trecho clicado: ${selectedText}
Texto completo da passagem (se disponivel): ${passageText || "nao informado"}

Explique em 3 blocos curtos:
1) Significado do texto
2) Contexto biblico imediato
3) Aplicacao pratica para hoje
`.trim();

  try {
    const explanation = await callXai({
      systemPrompt,
      userPrompt,
      temperature: 0.2,
    });
    return {
      explanation,
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI explainScripture", {error: String(error)});
    return {
      explanation: fallbackExplanation(reference, selectedText),
      source: "fallback",
      aiIntegration: "Falha no xAI; fallback local.",
    };
  }
});

exports.chatScripture = onCall({region: REGION}, async (request) => {
  requireAuth(request);

  const reference = sanitizeString(request.data?.reference, "Referencia biblica");
  const passageText = sanitizeString(request.data?.passageText, "");
  const question = sanitizeString(request.data?.question, "");
  const history = sanitizeChatHistory(request.data?.history);

  if (!question) {
    throw new HttpsError("invalid-argument", "Campo 'question' e obrigatorio.");
  }

  if (!hasXaiKey()) {
    return {
      answer:
        "No momento estou sem acesso ao modelo externo, mas posso te guiar: " +
        "observe o contexto da passagem, identifique o ensino central e transforme em pratica hoje.",
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  const systemPrompt =
    "Voce e um tutor biblico em modo conversa. Ensine com fidelidade ao texto, linguagem simples e foco no discipulado.";
  const historyText = history
      .map((item) => `${item.role === "assistant" ? "Tutor" : "Aluno"}: ${item.content}`)
      .join("\n");

  const userPrompt = `
Passagem: ${reference}
Texto base: ${passageText || "nao informado"}

Historico recente:
${historyText || "sem historico"}

Pergunta atual do aluno:
${question}

Responda em portugues com objetividade, sem inventar referencias.
`.trim();

  try {
    const answer = await callXai({
      systemPrompt,
      userPrompt,
      temperature: 0.35,
    });
    return {
      answer,
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI chatScripture", {error: String(error)});
    return {
      answer:
        "Nao consegui responder agora por falha temporaria. Tente reformular a pergunta em uma frase curta.",
      source: "fallback",
      aiIntegration: "Falha no xAI; fallback local.",
    };
  }
});

exports.searchVerses = onCall({region: REGION}, async (request) => {
  const query = String(request.data?.query || "").trim();

  if (!query) {
    throw new HttpsError("invalid-argument", "Campo 'query' e obrigatorio.");
  }

  if (!hasXaiKey()) {
    const corpus = [
      {
        reference: "Filipenses 4:6",
        text: "Nao andem ansiosos por coisa alguma...",
        tags: ["ansiedade", "oracao", "paz"],
      },
      {
        reference: "Josue 1:9",
        text: "Seja forte e corajoso.",
        tags: ["coragem", "forca", "fe"],
      },
      {
        reference: "Mateus 6:33",
        text: "Busquem primeiro o Reino de Deus.",
        tags: ["prioridades", "reino", "disciplina"],
      },
      {
        reference: "Proverbios 3:5",
        text: "Confie no Senhor de todo o seu coracao.",
        tags: ["confianca", "direcao", "sabedoria"],
      },
    ];

    const queryLower = query.toLowerCase();
    const matches = corpus.filter((verse) =>
      verse.reference.toLowerCase().includes(queryLower) ||
      verse.text.toLowerCase().includes(queryLower) ||
      verse.tags.some((tag) => tag.includes(queryLower)),
    );

    return {
      query,
      total: matches.length,
      items: matches,
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  const systemPrompt =
    "Voce atua como assistente biblico protestante e retorna somente JSON valido.";
  const userPrompt = `
Consulta: ${query}
Retorne JSON no formato:
{
  "query": "${query}",
  "items": [
    {
      "reference": "Livro cap:verso",
      "text": "trecho curto do versiculo",
      "reason": "por que esse versiculo se aplica"
    }
  ]
}
Regras: inclua ate 7 itens, use linguagem objetiva.
`.trim();

  try {
    const raw = await callXaiForJson({
      systemPrompt,
      userPrompt,
      temperature: 0.2,
    });

    const items = Array.isArray(raw.items) ? raw.items.slice(0, 7).map((item) => ({
      reference: sanitizeString(item.reference, "Referencia nao informada"),
      text: sanitizeString(item.text, ""),
      reason: sanitizeString(item.reason, ""),
    })) : [];

    return {
      query,
      total: items.length,
      items,
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI searchVerses", {error: String(error)});
    throw new HttpsError("internal", "Falha ao buscar versiculos via IA.");
  }
});

exports.searchStrong = onCall({region: REGION}, async (request) => {
  requireAuth(request);
  const query = String(request.data?.query || "").trim();

  if (!query) {
    throw new HttpsError("invalid-argument", "Campo 'query' e obrigatorio.");
  }

  if (!hasXaiKey()) {
    return {
      query,
      entries: [
        {
          strongNumber: "H3899",
          lemma: "lechem",
          transliteration: "lekhem",
          language: "Hebraico",
          definition: "pao, alimento",
          verseReferences: ["Genesis 3:19", "Exodo 16:4"],
          notes: "Fallback local sem consulta externa.",
        },
      ],
      source: "fallback",
      aiIntegration: "XAI_API_KEY ausente; fallback local.",
    };
  }

  const systemPrompt =
    "Voce e especialista em concordancia Strong e hebraico/grego biblico. Retorne somente JSON valido.";
  const userPrompt = `
Consulta Strong: ${query}
Retorne JSON no formato:
{
  "query": "${query}",
  "entries": [
    {
      "strongNumber": "H0000 ou G0000",
      "lemma": "...",
      "transliteration": "...",
      "language": "Hebraico ou Grego",
      "definition": "...",
      "usageExamples": ["...", "..."],
      "verseReferences": ["Livro cap:verso", "..."],
      "notes": "..."
    }
  ]
}
Inclua ate 8 entradas relevantes.
`.trim();

  try {
    const raw = await callXaiForJson({
      systemPrompt,
      userPrompt,
      temperature: 0.15,
    });

    const entries = Array.isArray(raw.entries) ? raw.entries.slice(0, 8).map((item) => ({
      strongNumber: sanitizeString(item.strongNumber, ""),
      lemma: sanitizeString(item.lemma, ""),
      transliteration: sanitizeString(item.transliteration, ""),
      language: sanitizeString(item.language, ""),
      definition: sanitizeString(item.definition, ""),
      usageExamples: Array.isArray(item.usageExamples) ?
        item.usageExamples.slice(0, 5).map((x) => sanitizeString(x, "")) :
        [],
      verseReferences: Array.isArray(item.verseReferences) ?
        item.verseReferences.slice(0, 8).map((x) => sanitizeString(x, "")) :
        [],
      notes: sanitizeString(item.notes, ""),
    })) : [];

    return {
      query,
      entries,
      source: "xai",
      model: XAI_MODEL,
    };
  } catch (error) {
    logger.error("Erro xAI searchStrong", {error: String(error)});
    throw new HttpsError("internal", "Falha ao consultar Strong via IA.");
  }
});

exports.onXpUpdate = onDocumentUpdated(
    {
      region: REGION,
      document: "users/{userId}",
    },
    async (event) => {
      const before = event.data.before.data() || {};
      const after = event.data.after.data() || {};

      const beforeXp = Number(before.weekXp || 0);
      const afterXp = Number(after.weekXp || 0);
      if (beforeXp === afterXp) {
        return;
      }

      const userId = event.params.userId;
      const weekKey = getWeekKey(new Date());
      const entryRef = db
          .collection("weeklyRankings")
          .doc(weekKey)
          .collection("entries")
          .doc(userId);

      await entryRef.set({
        userId,
        displayName: after.displayName || "Usuario",
        photoUrl: after.photoUrl || null,
        score: afterXp,
        weekKey,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      const updatedCount = await rebuildWeeklyRanks(weekKey);
      logger.info("XP update applied to weekly ranking", {
        userId,
        weekKey,
        updatedCount,
      });
    },
);
