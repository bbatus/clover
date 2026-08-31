#!/usr/bin/env bash
# =============================================================================
# clover-secret oluşturucu — gerçek parolaları REPOYA HİÇ YAZMADAN OpenShift
# Secret'ını oluşturur/günceller.
#
# Kullanım:
#   1) cp k8s/.env.secret.example k8s/.env.secret
#   2) k8s/.env.secret içini gerçek değerlerle doldur
#   3) oc login ... && oc project vepas-ai-am
#   4) ./k8s/create-secret.sh
#
# Idempotent: tekrar çalıştırmak mevcut Secret'ı günceller (apply).
# =============================================================================
set -euo pipefail

APP_NAME="clover"
SECRET_NAME="${APP_NAME}-secret"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env.secret}"

if [[ -f "${ENV_FILE}" ]]; then
  echo "→ Değerler okunuyor: ${ENV_FILE}"
  # shellcheck disable=SC1090
  set -a; source "${ENV_FILE}"; set +a
else
  echo "→ ${ENV_FILE} yok; değerler ortam değişkenlerinden alınacak."
fi

missing=()
for var in DATABASE_URI PAYLOAD_SECRET REVALIDATE_SECRET PREVIEW_SECRET CMS_ADMIN_PASSWORD; do
  [[ -z "${!var:-}" ]] && missing+=("$var")
done
if (( ${#missing[@]} > 0 )); then
  echo "HATA: şu değerler eksik: ${missing[*]}" >&2
  echo "      k8s/.env.secret dosyasını doldurun veya export edin." >&2
  exit 1
fi

gen() { openssl rand -base64 24 | tr -d '/+=' | cut -c1-24; }
MINIO_ROOT_USER="${MINIO_ROOT_USER:-payload}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-$(gen)}"
CMS_ADMIN_EMAIL="${CMS_ADMIN_EMAIL:-admin@vodafonepay.local}"

echo "→ Kullanılan üretilmiş değerler (Secret dışına kaydedilmez):"
echo "    MINIO_ROOT_PASSWORD : ${#MINIO_ROOT_PASSWORD} karakter"

NAMESPACE_ARG=()
[[ -n "${OCP_NAMESPACE:-}" ]] && NAMESPACE_ARG=(-n "${OCP_NAMESPACE}")

echo "→ Secret uygulanıyor: ${SECRET_NAME} (namespace: ${OCP_NAMESPACE:-<aktif proje>})"

oc create secret generic "${SECRET_NAME}" \
  --from-literal=DATABASE_URI="${DATABASE_URI}" \
  --from-literal=PAYLOAD_SECRET="${PAYLOAD_SECRET}" \
  --from-literal=REVALIDATE_SECRET="${REVALIDATE_SECRET}" \
  --from-literal=PREVIEW_SECRET="${PREVIEW_SECRET}" \
  --from-literal=MINIO_ROOT_USER="${MINIO_ROOT_USER}" \
  --from-literal=MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD}" \
  --from-literal=S3_ACCESS_KEY_ID="${MINIO_ROOT_USER}" \
  --from-literal=S3_SECRET_ACCESS_KEY="${MINIO_ROOT_PASSWORD}" \
  --from-literal=CMS_ADMIN_EMAIL="${CMS_ADMIN_EMAIL}" \
  --from-literal=CMS_ADMIN_PASSWORD="${CMS_ADMIN_PASSWORD}" \
  "${NAMESPACE_ARG[@]}" \
  --dry-run=client -o yaml \
  | oc label --local -f - app="${APP_NAME}" -o yaml \
  | oc apply "${NAMESPACE_ARG[@]}" -f -

echo "✓ Tamam. Doğrulama (yalnızca ANAHTARLAR görünür, değerler değil):"
echo "    oc get secret ${SECRET_NAME} -n ${OCP_NAMESPACE:-vepas-ai-am} -o jsonpath='{.data}' | tr ',' '\\n' | cut -d'\"' -f2"
echo ""
echo "Sonraki adımlar (sırasıyla):"
echo "    1) image pull secret'ının var olduğunu doğrulayın (bkz. k8s/serviceaccount.yaml)"
echo "    2) oc apply -f k8s/serviceaccount.yaml"
echo "    3) oc apply -f k8s/configmap.yaml"
echo "    4) oc apply -f k8s/minio.yaml   (Postgres harici, MinIO namespace-içi — bkz. dosyanın kendi notu)"
echo "    5) oc apply -f k8s/service.yaml -f k8s/route.yaml -f k8s/hpa.yaml"
echo "    6) IMAGE_REF=<imaj> envsubst < k8s/deployment.yaml | oc apply -f -"
