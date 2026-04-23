#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIGNING_DIR="${HOME}/Documents/BibliaParnassa/android-signing"
KEYSTORE_PATH="${SIGNING_DIR}/parnassa-upload-keystore.p12"
CERT_PATH="${SIGNING_DIR}/parnassa-upload-cert.pem"
SECRETS_PATH="${SIGNING_DIR}/keystore-secrets.txt"
KEY_PROPERTIES_PATH="${ROOT_DIR}/android/key.properties"
KEYSTORE_COPY_PATH="${ROOT_DIR}/android/keystore/upload-keystore.p12"

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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

ssh-keygen -t rsa -b 2048 -m PEM -N '' -f "${TMP_DIR}/upload_rsa" >/dev/null 2>&1

python3 - <<PY
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID
import datetime

keystore_path = Path(${KEYSTORE_PATH@Q})
cert_path = Path(${CERT_PATH@Q})
alias_name = ${ALIAS_NAME@Q}
store_password = ${STORE_PASSWORD@Q}.encode()
dname = ${DISTINGUISHED_NAME@Q}
private_key_path = Path(${TMP_DIR@Q}) / "upload_rsa"

parts = dict(
    item.strip().split("=", 1)
    for item in dname.split(",")
)

name = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, parts["CN"]),
    x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, parts["OU"]),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, parts["O"]),
    x509.NameAttribute(NameOID.LOCALITY_NAME, parts["L"]),
    x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, parts["ST"]),
    x509.NameAttribute(NameOID.COUNTRY_NAME, parts["C"]),
])

private_key = serialization.load_pem_private_key(private_key_path.read_bytes(), password=None)
certificate = (
    x509.CertificateBuilder()
    .subject_name(name)
    .issuer_name(name)
    .public_key(private_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(datetime.datetime.utcnow() - datetime.timedelta(days=1))
    .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=10000))
    .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
    .sign(private_key, hashes.SHA256())
)

p12 = pkcs12.serialize_key_and_certificates(
    name=alias_name.encode(),
    key=private_key,
    cert=certificate,
    cas=None,
    encryption_algorithm=serialization.BestAvailableEncryption(store_password),
)

keystore_path.write_bytes(p12)
cert_path.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
PY
cp "${KEYSTORE_PATH}" "${KEYSTORE_COPY_PATH}"

cat > "${KEY_PROPERTIES_PATH}" <<EOF
storeType=PKCS12
storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${ALIAS_NAME}
storeFile=keystore/upload-keystore.p12
EOF

cat > "${SECRETS_PATH}" <<EOF
Keystore file: ${KEYSTORE_PATH}
Certificate file: ${CERT_PATH}
Key alias: ${ALIAS_NAME}
Store password: ${STORE_PASSWORD}
Key password: ${KEY_PASSWORD}
Reference name for Codemagic: parnassa_upload_keystore
Store type: PKCS12
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
