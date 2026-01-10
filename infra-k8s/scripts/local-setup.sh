#!/bin/bash
set -e

echo "🚀 LXP Dev 환경 설정 시작..."
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 필수 도구 확인
echo "📋 필수 도구 확인..."
command -v minikube >/dev/null 2>&1 || { echo -e "${RED}❌ minikube 필요${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl 필요${NC}"; exit 1; }
echo -e "${GREEN}✅ 도구 확인 완료${NC}"
echo ""

# 2. minikube 시작
echo "📦 minikube 확인..."
if ! minikube status > /dev/null 2>&1; then
    echo "minikube 시작 중..."
    minikube start --memory=4096 --cpus=2
else
    echo -e "${GREEN}✅ minikube 실행 중${NC}"
fi
echo ""

# 3. Ingress addon 활성화
echo "🌐 Ingress 설정..."
minikube addons enable ingress
echo -e "${GREEN}✅ Ingress addon 활성화${NC}"
echo ""

# 4. Secret 생성
echo "🔐 Secret 설정..."
./scripts/create-secrets.sh
echo ""

# 5. 인프라 배포
echo "🏗️ 인프라 배포..."
kubectl apply -f k8s/infra/
echo ""

# 6. 인프라 준비 대기
echo "⏳ Pod 준비 대기..."
kubectl wait --for=condition=ready pod -l app=redis -n lxp --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=rabbitmq -n lxp --timeout=120s || true
echo ""

# 7. 서비스 배포 (있으면)
if ls k8s/services/*.yaml 1> /dev/null 2>&1; then
    echo "🚀 서비스 배포..."
    kubectl apply -f k8s/services/
fi
echo ""

# 8. Ingress IP 가져오기
MINIKUBE_IP=$(minikube ip)

# 9. 상태 확인
echo "=========================================="
echo -e "${GREEN}✅ 배포 완료!${NC}"
echo "=========================================="
echo ""
kubectl get pods -n lxp
echo ""
echo "=========================================="
echo "🌐 서비스 접속:"
echo "=========================================="
echo ""
echo "minikube service lxp-content -n lxp --url"
echo "minikube service lxp-recommend -n lxp --url"
echo "minikube service lxp-enrollment -n lxp --url"
echo "minikube service rabbitmq -n lxp --url  (ID: lxp / PW: lxp)"
echo ""
echo "또는 전체 목록:"
echo "minikube service list -n lxp"
