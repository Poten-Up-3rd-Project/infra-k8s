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
# Auth Keys (⭐ 비대칭키)
# -------------------------------------------------
echo "🔑 Auth key secrets 갱신..."

AUTH_PUBLIC_KEY=$(grep -v '^-' k8s/infra/keys/auth-public.pem | tr -d '\n\r ')
AUTH_PRIVATE_KEY=$(grep -v '^-' k8s/infra/keys/auth-private.pem | tr -d '\n\r ')

kubectl create secret generic lxp-auth-keys \
  --from-literal=AUTH_PUBLIC_KEY="$AUTH_PUBLIC_KEY" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic lxp-auth-private-key \
  --from-literal=AUTH_PRIVATE_KEY="$AUTH_PRIVATE_KEY" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

# -------------------------------------------------
# Passport Secret (⭐ 대칭키)
# -------------------------------------------------
echo "🔑 Passport secret 갱신..."

PASSPORT_SECRET=$(cat k8s/infra/keys/passport-secret.txt | tr -d '\n\r ')

kubectl create secret generic lxp-passport-secret \
  --from-literal=PASSPORT_SECRET="$PASSPORT_SECRET" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -
# -------------------------------------------------
# Auth Secret (내부 토큰)
# -------------------------------------------------
kubectl create secret generic lxp-auth-internal \
  --from-literal=INTERNAL_AUTH_TOKEN="auth-service-internal-token" \
  -n lxp \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ 모든 Secret 생성/갱신 완료${NC}"
kubectl get secrets -n lxp
