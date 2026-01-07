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
    echo "   .env.example을 복사해서 .env 파일을 만들어주세요."
    echo "   cp .env.example .env"
    exit 1
fi

# 필수 값 체크
if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
    echo -e "${RED}❌ DOCKERHUB_USERNAME, DOCKERHUB_TOKEN을 .env에 설정해주세요${NC}"
    exit 1
fi

if [ -z "$RABBITMQ_PASS" ] || [ -z "$REDIS_PASS" ] || [ -z "$MYSQL_PASS" ]; then
    echo -e "${RED}❌ 비밀번호를 .env에 설정해주세요${NC}"
    exit 1
fi

# Namespace 생성
kubectl create namespace lxp --dry-run=client -o yaml | kubectl apply -f -

# ============================================
# 1. Docker Hub Secret
# ============================================
echo "📦 Docker Hub secret 생성..."

kubectl create secret docker-registry dockerhub-secret \
    --docker-server=docker.io \
    --docker-username="$DOCKERHUB_USERNAME" \
    --docker-password="$DOCKERHUB_TOKEN" \
    --namespace=lxp \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Docker Hub secret 생성 완료${NC}"

# ============================================
# 2. 인프라 Secret (RabbitMQ + Redis)
# ============================================
echo "🔧 인프라 secret 생성..."

kubectl create secret generic infra-secret \
    --from-literal=rabbitmq-username="$RABBITMQ_USER" \
    --from-literal=rabbitmq-password="$RABBITMQ_PASS" \
    --from-literal=redis-password="$REDIS_PASS" \
    --namespace=lxp \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ 인프라 secret 생성 완료${NC}"

# ============================================
# 3. MySQL Secret (공용)
# ============================================
echo "🗄️ MySQL secret 생성..."

kubectl create secret generic lxp-mysql-secret \
    --from-literal=username="$MYSQL_USER" \
    --from-literal=password="$MYSQL_PASS" \
    --from-literal=root-password="$MYSQL_ROOT_PASS" \
    --namespace=lxp \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ MySQL secret 생성 완료${NC}"
echo ""

# 확인
echo "📋 생성된 Secret 목록:"
kubectl get secrets -n lxp