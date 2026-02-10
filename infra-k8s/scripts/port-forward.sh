#!/bin/bash

echo "Port Forwarding 시작..."
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WSL 환경에서 브라우저 접근을 위한 포트포워딩${NC}"
echo ""
echo "접속 정보:"
echo "  Gateway:       http://localhost:8080"
echo "  lxp-user:      http://localhost:8081"
echo "  lxp-content:   http://localhost:8082"
echo "  lxp-recommend: http://localhost:8083"
echo "  lxp-enrollment:http://localhost:8084"
echo "  lxp-auth:      http://localhost:8085"
echo "  lxp-admin:     http://localhost:8086"
echo ""
echo "  RabbitMQ UI:   http://localhost:15672"
echo "  MinIO API:     http://localhost:9000"
echo "  MinIO Console: http://localhost:9001"
echo "  MySQL:         localhost:3306"
echo "  Redis:         localhost:6379"
echo ""
echo -e "${YELLOW}종료하려면 Ctrl+C${NC}"
echo ""

# 서비스 포트포워딩
kubectl port-forward service/lxp-gateway 8080:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-user 8081:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-content 8082:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-recommend 8083:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-enrollment 8084:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-auth 8085:8080 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-admin 8086:8080 -n lxp --address 0.0.0.0 &

# 인프라 포트포워딩
kubectl port-forward service/minio 9000:9000 -n lxp --address 0.0.0.0 &
kubectl port-forward service/minio 9001:9001 -n lxp --address 0.0.0.0 &
kubectl port-forward service/lxp-mysql 3306:3306 -n lxp --address 0.0.0.0 &
kubectl port-forward service/redis 6379:6379 -n lxp --address 0.0.0.0 &
kubectl port-forward service/rabbitmq 5672:5672 -n lxp --address 0.0.0.0 &
kubectl port-forward service/rabbitmq 15672:15672 -n lxp --address 0.0.0.0 &

echo ""
echo -e "${GREEN}포트포워딩 실행 중...${NC}"
echo ""

# 모든 백그라운드 프로세스 대기
wait
