#!/bin/bash
set -e

echo "🔄 최신 이미지로 업데이트..."

GREEN='\033[0;32m'
NC='\033[0m'

if [ -n "$1" ]; then
    # 특정 서비스만
    echo "📦 $1 업데이트..."
    kubectl rollout restart deployment/$1 -n lxp
    kubectl rollout status deployment/$1 -n lxp
else
    # 전체 서비스 (인프라 제외)
    DEPLOYMENTS=$(kubectl get deployments -n lxp -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v -E '^(redis|rabbitmq|lxp-mysql)$' || true)

    if [ -z "$DEPLOYMENTS" ]; then
        echo "업데이트할 서비스가 없습니다"
        exit 0
    fi

    for DEPLOY in $DEPLOYMENTS; do
        echo "📦 $DEPLOY 재시작..."
        kubectl rollout restart deployment/$DEPLOY -n lxp
    done

    for DEPLOY in $DEPLOYMENTS; do
        kubectl rollout status deployment/$DEPLOY -n lxp
    done
fi

echo ""
echo -e "${GREEN}✅ 업데이트 완료!${NC}"
kubectl get pods -n lxp