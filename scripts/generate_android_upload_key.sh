#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIGNING_DIR="${HOME}/Documents/BibliaParnassa/android-signing"
KEYSTORE_PATH="${SIGNING_DIR}/parnassa-upload-keystore.jks"
CERT_PATH="${SIGNING_DIR}/parnassa-upload-cert.pem"
SECRETS_PATH="${SIGNING_DIR}/keystore-secrets.txt"
KEY_PROPERTIES_PATH="${ROOT_DIR}/android/key.properties"
KEYSTORE_COPY_PATH="${ROOT_DIR}/android/keystore/upload-keystore.jks"

ALIAS_NAME="${ALIAS_NAME:-parnassa_upload}"
STORE_PASSWORD="${STORE_PASSWORD:-$(openssl rand -hex 12)}"
KEY_PASSWORD="${KEY_PASSWORD:-$(openssl rand -hex 12)}"
DISTINGUISHED_NAME="${DISTINGUISHED_NAME:-CN=Andrey Quadros, OU=Mobile, O=App Biblia Parnassa, L=Porto Velho, ST=RO, C=BR}"

mkdir -p "${SIGNING_DIR}" "${ROOT_DIR}/android/keystore"

if [[ -f "${KEYSTORE_PATH}" ]]; then
  echo "Keystore ja existe em ${KEYSTORE_PATH}."
  echo "Se quiser gerar uma nova, remova os arquivos antigos primeiro."
  exit 1
fi

keytool -genkeypair -noprompt -v \
  -keystore "${KEYSTORE_PATH}" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "${ALIAS_NAME}" \
  -storepass "${STORE_PASSWORD}" \
  -keypass "${KEY_PASSWORD}" \
  -dname "${DISTINGUISHED_NAME}"

keytool -exportcert \
  -rfc \
  -keystore "${KEYSTORE_PATH}" \
  -storepass "${STORE_PASSWORD}" \
  -alias "${ALIAS_NAME}" \
  -file "${CERT_PATH}"

cp "${KEYSTORE_PATH}" "${KEYSTORE_COPY_PATH}"

cat > "${KEY_PROPERTIES_PATH}" <<EOF
storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${ALIAS_NAME}
storeFile=keystore/upload-keystore.jks
EOF

cat > "${SECRETS_PATH}" <<EOF
Keystore file: ${KEYSTORE_PATH}
Certificate file: ${CERT_PATH}
Key alias: ${ALIAS_NAME}
Store password: ${STORE_PASSWORD}
Key password: ${KEY_PASSWORD}
Reference name for Codemagic: parnassa_upload_keystore
Created at: $(date '+%Y-%m-%d %H:%M:%S %Z')
Important: Backup this folder in a safe place. Do not commit these files.
EOF

chmod 600 "${KEY_PROPERTIES_PATH}" "${SECRETS_PATH}"

cat <<EOF
Upload key criada com sucesso.

Arquivos:
- ${KEYSTORE_PATH}
- ${CERT_PATH}
- ${SECRETS_PATH}
- ${KEY_PROPERTIES_PATH}

Proximo passo na Codemagic:
1. Team settings > codemagic.yaml settings > Code signing identities > Android keystores
2. Upload do arquivo ${KEYSTORE_PATH}
3. Use a referencia: parnassa_upload_keystore
4. Preencha:
   - Keystore password: STORE_PASSWORD
   - Key alias: ALIAS_NAME
   - Key password: KEY_PASSWORD

Depois disso, rode um novo build na Codemagic.
EOF
