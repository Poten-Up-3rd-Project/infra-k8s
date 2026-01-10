# LXP Dev Environment (Kubernetes)

MSA 서비스 간 통신 테스트를 위한 개발 환경입니다.

## 📋 개요

- **용도**: 서비스 간 통신 테스트 (로컬 개발은 각자 `application-local.yaml` 사용)
- **환경**: minikube (로컬 Kubernetes)
- **포함 서비스**: Redis, RabbitMQ, 각 마이크로서비스 + MySQL

```
┌─────────────────────────────────────────────────────────────┐
│  minikube (Dev 환경)                                        │
│                                                             │
│  ┌─────────┐  ┌─────────────┐                              │
│  │  Redis  │  │  RabbitMQ   │   ← 공용 인프라               │
│  └────┬────┘  └──────┬──────┘                              │
│       │              │                                      │
│  ┌────┴──────────────┴────┐                                │
│  │                        │                                │
│  ▼                        ▼                                │
│  ┌──────────────┐   ┌──────────────┐                      │
│  │ lxp-content  │   │  lxp-user    │   ← 서비스들          │
│  │   + MySQL    │   │   + MySQL    │                      │
│  └──────────────┘   └──────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 시작하기

### 
env파일은 제가 직접 전달해드릴게요!


### ⚠️ Windows 사용자 주의

`.env` 파일 만들 때 **LF 형식**으로 저장하세요!

VSCode: 오른쪽 하단 `CRLF` → `LF` 변경 후 저장


### 1. 사전 요구사항 설치

| 도구 | 설치 링크 |
|------|----------|
| Docker Desktop | https://www.docker.com/products/docker-desktop |
| minikube | https://minikube.sigs.k8s.io/docs/start/ |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |

### 2. 저장소 클론

```bash
git clone https://github.com/Poten-Up-3rd-Project/infra-k8s.git
cd infra-k8s
```

### 3. 스크립트 실행 권한 (Mac/Linux)

```bash
chmod +x scripts/*.sh
```

### 4. 환경 설정 실행

```bash
./scripts/local-setup.sh
```


### 5. 상태 확인

```bash
kubectl get pods -n lxp
```

모든 Pod이 `Running` 상태면 성공!

## 🌐 서비스 접속

### 서비스 URL 확인

```bash
# 전체 서비스 URL 확인
minikube service list -n lxp
```

### 각 서비스 접속

```bash
# lxp-content
minikube service lxp-content -n lxp --url
# → http://192.168.49.2:30082


# RabbitMQ Management UI
minikube service rabbitmq -n lxp --url
# → http://192.168.49.2:30672 (ID: lxp / PW: lxp)
```

### 포트 정리

| 서비스            | NodePort | 용도             |
|----------------|----------|----------------|
| lxp-user       | 30081    | User 서비스       |
| lxp-content    | 30082    | Content 서비스    |
| lxp-recommend  | 30083    | Recommend 서비스  |    
| lxp-enrollment | 30684    | Enrollment 서비스 |    
| rabbitmq       | 30672    | RabbitMQ UI    |

## 📋 자주 쓰는 명령어

```bash
# Pod 상태 확인
kubectl get pods -n lxp

# 특정 Pod 로그 확인
kubectl logs -f deployment/lxp-content -n lxp

# 최신 이미지로 업데이트 (main merge 후)
./scripts/update-images.sh

# 특정 서비스만 업데이트
./scripts/update-images.sh lxp-content

# 특정 서비스 로그 실시간 확인
kubectl logs -f deployment/lxp-content -n lxp

# 전체 삭제
kubectl delete namespace lxp

# minikube 중지
minikube stop

# minikube 재시작
minikube start
```

## minikube 대시보드 열기

```bash
# 활성화
minikube addons enable dashboard

# 실행
minikube dashboard

````
## metrics-server 설치 (선택 사항)

```bash
minikube addons enable metrics-server
kubectl top pods -n lxp
kubectl top nodes
```

## 🔧 문제 해결

### kubectl 연결 안 될 때

```bash
# minikube 상태 확인
minikube status

# apiserver가 Stopped면 재시작
minikube stop
minikube start
```

### Pod이 ImagePullBackOff 상태일 때

Docker Hub 인증 문제입니다.
```bash
# Secret 재생성
./scripts/create-secrets.sh
```

### Pod이 계속 재시작될 때

```bash
# 로그 확인
kubectl logs deployment/lxp-content -n lxp --previous

# Pod 상세 정보
kubectl describe pod -l app=lxp-content -n lxp
```

## 📁 프로젝트 구조

```
infra-k8s/
├── k8s/
│   ├── infra/                    # 공용 인프라
│   │   ├── 00-namespace.yaml
│   │   ├── 01-redis.yaml
│   │   ├── 02-rabbitmq.yaml
│   │   └── 03-ingress.yaml
│   └── services/                 # 마이크로서비스
│       └── lxp-content.yaml
├── scripts/
│   ├── create-secrets.sh         # Secret 생성
│   ├── local-setup.sh            # 환경 설정
│   └── update-images.sh          # 이미지 업데이트
└── README.md
```

## 🔄 CI/CD 흐름

```
1. 각 서비스 repo에서 main에 merge
2. GitHub Actions가 Docker 이미지 빌드 → Docker Hub push
3. 팀원이 ./scripts/update-images.sh 실행
4. 최신 이미지로 Pod 재시작
```


