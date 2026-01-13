#!/bin/bash
set -e

echo "🚀 LXP k3s 환경 설정 시작"

######################################
# 1. k3s 설치 (Traefik 비활성화)
######################################
if ! command -v k3s >/dev/null 2>&1; then
  echo "📦 k3s 설치 중..."
  curl -sfL https://get.k3s.io | sh -s - --disable traefik
else
  echo "✅ k3s 이미 설치됨"
fi

######################################
# 2. kubectl 설정
######################################
echo "🔧 kubectl 설정"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

######################################
# 3. nginx-ingress 설치
######################################
echo "🌐 nginx-ingress 설치"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

echo "⏳ ingress-nginx 준비 대기..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

######################################
# 4. Namespace 생성
######################################
echo "📁 Namespace 생성"
kubectl apply -f k8s/infra/00-namespace.yaml


echo "🔐 Secret 생성"
./scripts/create-secrets.sh

######################################
# 6. PVC 생성 (있다면 명시적으로)
######################################
echo "💾 PVC 생성"
kubectl apply -f k8s/infra/pvc/



######################################
# 5. Infra 서비스 기동
######################################
echo "🏗️ Infra 기동"
kubectl apply -f k8s/infra/

######################################
# 6. Infra 준비 대기
######################################
echo "⏳ Infra 준비 대기"
kubectl wait --for=condition=ready pod -l app=redis -n lxp --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=rabbitmq -n lxp --timeout=180s || true
kubectl wait --for=condition=ready pod -l app=lxp-mysql -n lxp --timeout=180s || true

######################################
# 7. 서비스(dev) 기동
######################################
echo "🚀 LXP 서비스(dev) 기동"
kubectl apply -f k8s/service/dev/

######################################
# 8. 상태 출력
######################################
echo "===================================="
echo "✅ LXP k3s 배포 완료"
echo "===================================="
kubectl get pods -n lxp
echo ""
kubectl get svc -n lxp
echo ""
kubectl get ingress -n lxp

echo ""
echo "🌐 접속 주소:"
echo "👉 http://$(curl -s ifconfig.me)"
