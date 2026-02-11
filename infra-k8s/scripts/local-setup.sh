#!/bin/bash
set -e

echo "LXP Dev 환경 설정 시작..."
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 환경 선택 (기본: stag)
ENV=${1:-stag}

if [ "$ENV" != "dev" ] && [ "$ENV" != "stag" ]; then
    echo -e "${RED}환경은 'dev' 또는 'stag'만 가능합니다${NC}"
    echo "사용법: ./scripts/local-setup.sh [dev|stag]"
    exit 1
fi

echo "환경: $ENV"
echo ""

# 1. 필수 도구 확인
echo "필수 도구 확인..."
command -v minikube >/dev/null 2>&1 || { echo -e "${RED}minikube 필요${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl 필요${NC}"; exit 1; }
echo -e "${GREEN}도구 확인 완료${NC}"
echo ""

# 2. minikube 시작
echo "minikube 확인..."
if ! minikube status > /dev/null 2>&1; then
    echo "minikube 시작 중..."
    minikube start --memory=6144 --cpus=2
else
    echo -e "${GREEN}minikube 실행 중${NC}"
fi
echo ""

# 3. Ingress addon 활성화
echo "Ingress 설정..."
minikube addons enable ingress
echo -e "${GREEN}Ingress addon 활성화${NC}"
echo ""

# 4. Secret 생성
echo "Secret 설정..."
./scripts/create-secrets.sh
echo ""

# 5. PVC 생성
echo "PVC 생성..."
kubectl apply -f k8s/infra/pvc/
echo ""

# 6. Redis init ConfigMap 생성 및 갱신
echo "Redis init ConfigMap 생성/갱신..."
kubectl create configmap lxp-redis-init \
  -n lxp \
  --from-file=init-tags.redis=k8s/infra/init-scripts/init-tags.redis \
  --dry-run=client -o yaml | kubectl apply -f -
echo ""

# 7. 인프라 배포
echo "인프라 배포..."
kubectl apply -f k8s/infra/
echo ""

# 8. 인프라 준비 대기
echo "Pod 준비 대기..."
kubectl wait --for=condition=ready pod -l app=redis -n lxp --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=rabbitmq -n lxp --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=lxp-mysql -n lxp --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=minio -n lxp --timeout=120s || true
echo ""

# 9. 서비스 배포 (Kustomize)
echo "서비스 배포 ($ENV)..."
kubectl apply -k k8s/services/overlays/$ENV/
echo ""

# 10. 상태 확인
MINIKUBE_IP=$(minikube ip)
DRIVER=$(minikube profile list -o json 2>/dev/null | grep -o '"Driver":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "=========================================="
echo -e "${GREEN}배포 완료! (환경: $ENV)${NC}"
echo "=========================================="
echo ""
kubectl get pods -n lxp
echo ""
echo "=========================================="
echo "서비스 접속 (NodePort):"
echo "=========================================="
echo ""
echo "API Gateway:    http://$MINIKUBE_IP:30080"
echo "lxp-user:       http://$MINIKUBE_IP:30081"
echo "lxp-content:    http://$MINIKUBE_IP:30082"
echo "lxp-recommend:  http://$MINIKUBE_IP:30083"
echo "lxp-enrollment: http://$MINIKUBE_IP:30084"
echo "lxp-auth:       http://$MINIKUBE_IP:30085"
echo "lxp-admin:         http://$MINIKUBE_IP:30086"
echo "lxp-recomm-engine: http://$MINIKUBE_IP:30090"
echo "lxp-qna-engine:    http://$MINIKUBE_IP:30091"
echo ""
echo "RabbitMQ UI:    http://$MINIKUBE_IP:30672"
echo "MinIO API:      http://$MINIKUBE_IP:30900"
echo "MinIO Console:  http://$MINIKUBE_IP:30901"
echo "MySQL:          $MINIKUBE_IP:30306"
echo "Redis:          $MINIKUBE_IP:30379"
echo ""

if [ "$DRIVER" = "docker" ]; then
    echo "=========================================="
    echo -e "${YELLOW}Docker 드라이버 감지!${NC}"
    echo "=========================================="
    echo ""
    echo "Windows 브라우저에서 접근하려면 포트포워딩이 필요합니다."
    echo "Pod이 모두 Running 상태가 되면 새 터미널에서 실행:"
    echo ""
    echo -e "  ${GREEN}./scripts/port-forward.sh${NC}"
    echo ""
    echo "포트포워딩 후 접속 주소:"
    echo "  Gateway:        http://localhost:8080"
    echo "  lxp-user:       http://localhost:8081"
    echo "  lxp-content:    http://localhost:8082"
    echo "  lxp-recommend:  http://localhost:8083"
    echo "  lxp-enrollment: http://localhost:8084"
    echo "  lxp-auth:       http://localhost:8085"
    echo "  lxp-admin:         http://localhost:8086"
    echo "  lxp-recomm-engine: http://localhost:8090"
    echo "  lxp-qna-engine:   http://localhost:8091"
    echo "  RabbitMQ UI:      http://localhost:15672"
    echo "  MinIO Console:  http://localhost:9001"
    echo ""
fi
