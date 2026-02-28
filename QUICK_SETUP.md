# 카페온도 - 5분 빠른 설정 가이드

> 아래 단계를 순서대로 따라하면 약 5~10분이면 모두 완료됩니다.

---

## 1단계: GitHub Pages 배포 (법적 페이지)

터미널에서 아래 명령어를 순서대로 실행하세요:

```bash
cd cafeondo
git add docs/
git commit -m "Add legal pages for GitHub Pages"
git push origin main
```

그 다음 GitHub에서:
1. https://github.com/moonkj/cafeondo/settings/pages 접속
2. Source: **Deploy from a branch** 선택
3. Branch: **main**, 폴더: **/docs** 선택
4. Save 클릭

> 약 1-2분 후 https://moonkj.github.io/cafeondo/ 에서 확인 가능

---

## 2단계: Firebase Blaze 플랜 업그레이드

1. https://console.firebase.google.com/project/cafeondo-dd418/usage 접속
2. 좌측 하단 **Spark** → **업그레이드** 클릭
3. 결제 계정 선택 또는 새로 생성
4. 예산 알림 설정 (권장: 월 $5)
5. **구매** 클릭

> Cloud Functions 배포에 필수. 무료 사용량이 넉넉해서 초기 비용 0원.

---

## 3단계: Authentication 활성화

1. https://console.firebase.google.com/project/cafeondo-dd418/authentication 접속
2. **시작하기** 버튼 클릭

### Google 로그인:
3. 제공업체 목록에서 **Google** 클릭
4. **사용 설정** 토글 활성화
5. 프로젝트 지원 이메일: 본인 이메일 선택
6. **저장** 클릭

### 익명 로그인:
7. 제공업체 목록에서 **익명** 클릭
8. **사용 설정** 토글 활성화
9. **저장** 클릭

### Apple 로그인 (나중에 해도 됨):
10. Apple Developer에서 Sign In with Apple 설정 완료 후 추가

---

## 4단계: Cloud Firestore 생성

1. https://console.firebase.google.com/project/cafeondo-dd418/firestore 접속
2. **데이터베이스 만들기** 클릭
3. 위치: **asia-northeast3 (서울)** 선택 ⚠️ 변경 불가, 반드시 서울!
4. 보안 규칙: **테스트 모드에서 시작** 선택 (나중에 규칙 배포)
5. **만들기** 클릭

---

## 5단계: Firebase Storage 활성화

1. https://console.firebase.google.com/project/cafeondo-dd418/storage 접속
2. **시작하기** 클릭
3. 보안 규칙: 기본값 유지
4. 위치: **asia-northeast3** 확인 (Firestore와 동일)
5. **완료** 클릭

---

## 6단계: Firebase CLI로 규칙/함수 배포

터미널에서:

```bash
# Firebase CLI 설치 (이미 설치되어 있으면 스킵)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 폴더로 이동
cd cafeondo

# Firestore 보안 규칙 + 인덱스 배포
firebase deploy --only firestore:rules,firestore:indexes

# Storage 보안 규칙 배포
firebase deploy --only storage

# Cloud Functions 배포 (functions 폴더에서 npm install 먼저)
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

## 완료 확인 체크리스트

- [ ] GitHub Pages: https://moonkj.github.io/cafeondo/ 접속 확인
- [ ] Firebase Auth: Google + 익명 로그인 활성화 확인
- [ ] Firestore: 데이터베이스 생성 확인 (asia-northeast3)
- [ ] Storage: 버킷 생성 확인
- [ ] Blaze 플랜: 업그레이드 확인
- [ ] 보안 규칙: 배포 확인
- [ ] Cloud Functions: 배포 확인 (Firebase Console > Functions에서 확인)

---

**모든 설정 완료 후** → 코딩 담당자에게 코드를 전달하고 빌드를 시작하시면 됩니다!
