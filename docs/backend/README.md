# Backend Firebase - Palavra Viva

Projeto Firebase integrado via MCP:
- **Project ID:** `palavraviva-app-2026`
- **Project Number:** `650786366043`

Apps registrados:
- Android: `1:650786366043:android:8c00a75f15b4a4c189957e`
- iOS: `1:650786366043:ios:01b1c5adf18f761389957e`
- Web: `1:650786366043:web:bd0a149ce3d5d1db89957e`

## Estrutura

- `functions/index.js` (Cloud Functions v2)
- `functions/.env.example` (variaveis xAI)
- `firebase/firestore.rules`
- `firebase/firestore.indexes.json`
- `firebase/storage.rules`
- `firebase/firebase.json`
- `firebase/.firebaserc`

## Configuração Flutter aplicada

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `lib/core/services/firebase_service.dart` inicializando com `DefaultFirebaseOptions.currentPlatform`

## Auth e Firestore

- Auth (MCP init): `emailPassword` + `googleSignIn` configurados no `firebase.json`.
- Regras Firestore restauradas para modo seguro (sem regra aberta temporária).
- Índices de ranking/estudos/recompensas restaurados.
- Firebase CLI provisionada localmente em `firebase/node_modules/.bin/firebase`.
- Java 21 provisionado em modo user-space em:
  `/Users/andreyalencarquadros/.local/jdk/jdk-21.0.10+7/Contents/Home`.

## Integração xAI

- Variaveis carregadas via `functions/.env.local` quando os emuladores iniciam.
- Modelo padrao: `grok-4.20-reasoning` (configuravel por `XAI_MODEL`).
- Endpoints que usam xAI:
  - `generateDailyStudy` (scheduler)
  - `generateStudyNow` (callable sob demanda)
  - `seedInitialContent` (callable para seed de catalogo/comunidade/estudo)
  - `simplifyStudy` (callable)
  - `generateGuidedPrayer` (callable)
  - `searchVerses` (callable)
  - `searchStrong` (callable)

## Execução local pronta

Use os scripts:

```bash
./scripts/start-firebase-emulators.sh
./scripts/run-web-local.sh
```

## Observação de provisionamento cloud

No MCP, o `firebase_init` atualiza os arquivos locais de configuração. A API administrativa ainda retornou "database (default) does not exist" para consulta remota do Firestore neste ambiente MCP, então para deploy em produção pode ser necessário confirmar/provisionar o banco `(default)` diretamente no Console Firebase do projeto `palavraviva-app-2026`.
