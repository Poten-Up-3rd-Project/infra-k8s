#!/bin/bash
set -e

echo "🔑 키 생성 스크립트"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

KEYS_DIR="k8s/infra/keys"

# 키 디렉토리 생성
mkdir -p "$KEYS_DIR"

# -------------------------------------------------
# 1. AUTH 비대칭키 생성 (RSA 2048)
# -------------------------------------------------
echo -e "${YELLOW}📝 AUTH 비대칭키 쌍 생성 중...${NC}"

# 개인키 생성
openssl genrsa -out "$KEYS_DIR/auth-private.pem" 2048

# 공개키 추출
openssl rsa -in "$KEYS_DIR/auth-private.pem" -pubout -out "$KEYS_DIR/auth-public.pem"

echo -e "${GREEN}✅ AUTH 비대칭키 생성 완료${NC}"
echo "   - 개인키: $KEYS_DIR/auth-private.pem"
echo "   - 공개키: $KEYS_DIR/auth-public.pem"
echo ""

# -------------------------------------------------
# 2. PASSPORT 대칭키 생성 (256-bit random)
# -------------------------------------------------
echo -e "${YELLOW}📝 PASSPORT 대칭키 생성 중...${NC}"

# 안전한 랜덤 대칭키 생성 (base64 인코딩, 64자)
PASSPORT_SECRET=$(openssl rand -base64 48)

echo "$PASSPORT_SECRET" > "$KEYS_DIR/passport-secret.txt"

echo -e "${GREEN}✅ PASSPORT 대칭키 생성 완료${NC}"
echo "   - 키 파일: $KEYS_DIR/passport-secret.txt"
echo ""

# -------------------------------------------------
# 권한 설정
# -------------------------------------------------
chmod 600 "$KEYS_DIR"/*

echo -e "${GREEN}✅ 모든 키 생성 완료!${NC}"
