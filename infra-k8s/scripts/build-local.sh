#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICE=$1
SERVICE_PATH=${2:-"../$SERVICE"}

if [ -z "$SERVICE" ]; then
    echo "사용법: ./scripts/build-local.sh <서비스명> [서비스경로]"
    echo "예시:   ./scripts/build-local.sh lxp-content ../lxp-content"
    exit 1
fi

echo "=== $SERVICE 로컬 빌드 & 배포 ==="
echo ""

# 1. Gradle 빌드
echo "[1/4] Gradle bootJar 빌드 중..."
(cd "$SERVICE_PATH" && ./gradlew bootJar -x test)

# 2. minikube Docker 환경에서 이미지 빌드
echo "[2/4] minikube Docker 환경 설정..."
eval $(minikube docker-env)

echo "[3/4] $SERVICE:local 이미지 빌드 중..."
docker build -f "$SERVICE_PATH/Dockerfile.local" -t "$SERVICE:local" "$SERVICE_PATH"

# 3. 해당 서비스만 로컬 이미지로 패치 (다른 서비스는 건드리지 않음)
echo "[4/4] $SERVICE 배포 중 (이 서비스만 교체)..."
kubectl set image deployment/$SERVICE $SERVICE=$SERVICE:local -n lxp
kubectl patch deployment/$SERVICE -n lxp -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"'"$SERVICE"'","imagePullPolicy":"Never"}]}}}}'

# 4. 롤아웃
kubectl rollout restart deployment/$SERVICE -n lxp

echo ""
echo -e "${GREEN}완료!${NC} $SERVICE만 로컬 이미지로 교체되었습니다."
echo ""
echo -e "${YELLOW}원래 stag 이미지로 되돌리려면:${NC}"
echo "  kubectl apply -k k8s/services/overlays/stag/"
echo "  kubectl rollout restart deployment/$SERVICE -n lxp"
echo ""
echo "로그 확인: kubectl logs -f deployment/$SERVICE -n lxp"
