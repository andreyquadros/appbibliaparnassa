# Android Release Signing

Este projeto esta pronto para usar assinatura Android de producao em dois cenarios:

- localmente, com `android/key.properties`
- na Codemagic, com a referencia `parnassa_upload_keystore`

## Gerar a upload key

Rode este script na sua maquina:

```bash
./scripts/generate_android_upload_key.sh
```

Ele cria:

- `~/Documents/BibliaParnassa/android-signing/parnassa-upload-keystore.jks`
- `~/Documents/BibliaParnassa/android-signing/parnassa-upload-cert.pem`
- `~/Documents/BibliaParnassa/android-signing/keystore-secrets.txt`
- `android/key.properties`
- `android/keystore/upload-keystore.jks`

## Subir para a Codemagic

Segundo a documentacao oficial da Codemagic, o keystore deve ser enviado em:

- Team settings
- `codemagic.yaml settings`
- `Code signing identities`
- `Android keystores`

Use:

- Reference name: `parnassa_upload_keystore`

O `codemagic.yaml` ja referencia esse nome no campo `android_signing`.

## Importante

- Faca backup da pasta `~/Documents/BibliaParnassa/android-signing`
- Nao versione a keystore nem o `android/key.properties`
- A mesma upload key deve ser usada em todas as releases futuras para o Google Play
