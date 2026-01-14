#!/bin/bash
set -e

echo "🔐 Secret 생성 스크립트"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# .env 파일 로드
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo -e "${GREEN}✅ .env 파일 로드 완료${NC}"
else
    echo -e "${RED}❌ .env 파일이 없습니다!${NC}"
    exit 1
fi

# Namespace
kubectl create namespace lxp --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# Docker Hub
# -------------------------------------------------
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username="$DOCKERHUB_USERNAME" \
  --docker-password="$DOCKERHUB_TOKEN" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# Infra Secret
# -------------------------------------------------
kubectl create secret generic infra-secret \
  --from-literal=rabbitmq-username="$RABBITMQ_USER" \
  --from-literal=rabbitmq-password="$RABBITMQ_PASS" \
  --from-literal=redis-password="$REDIS_PASS" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# MySQL
# -------------------------------------------------
kubectl create secret generic lxp-mysql-secret \
  --from-literal=username="$MYSQL_USER" \
  --from-literal=password="$MYSQL_PASS" \
  --from-literal=root-password="$MYSQL_ROOT_PASS" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# Passport Keys (⭐ 핵심)
# -------------------------------------------------
echo "🔑 Passport key secrets 갱신..."

PASSPORT_PUBLIC_KEY=$(awk '!/BEGIN|END/ { printf "%s", $0 }' k8s/infra/keys/passport-public.pem)
PASSPORT_PRIVATE_KEY=$(awk '!/BEGIN|END/ { printf "%s", $0 }' k8s/infra/keys/passport-private.pem)

kubectl create secret generic lxp-passport-keys \
  --from-literal=PASSPORT_PUBLIC_KEY="$PASSPORT_PUBLIC_KEY" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic lxp-passport-private-key \
  --from-literal=PASSPORT_PRIVATE_KEY="$PASSPORT_PRIVATE_KEY" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# Auth Secret
# -------------------------------------------------
kubectl create secret generic lxp-auth-secret \
  --from-literal=JWT_SECRET_KEY="test-secret-key-for-unit-testing-purposes-only-minimum-32-characters-required" \
  --from-literal=INTERNAL_AUTH_TOKEN="auth-service-internal-token" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ 모든 Secret 생성/갱신 완료${NC}"
kubectl get secrets -n lxp
