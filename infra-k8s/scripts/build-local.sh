#!/bin/bash

SERVICE=$1
SERVICE_PATH=${2:-"../$SERVICE"}

if [ -z "$SERVICE" ]; then
    echo "사용법: ./scripts/build-local.sh <서비스명> [서비스경로]"
    echo "예시: ./scripts/build-local.sh lxp-content ../lxp-content"
    exit 1
fi

echo "🔨 Gradle 빌드 중..."
cd $SERVICE_PATH
./gradlew build -x test
cd -

echo "🔧 minikube Docker 환경 설정..."
eval $(minikube docker-env)

echo "🏗️ $SERVICE 이미지 빌드 중..."
docker build -t $SERVICE:local $SERVICE_PATH

echo "🚀 배포 중..."
kubectl apply -f k8s/services/dev/$SERVICE.yaml

echo "⏳ 기존 Pod 삭제 후 재생성..."
kubectl rollout restart deployment/$SERVICE -n lxp

echo "✅ 완료!"
echo ""
echo "📋 로그 확인: kubectl logs -f deployment/$SERVICE -n lxp"