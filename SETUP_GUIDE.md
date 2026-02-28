# 카페온도 (CafeOndo) Firebase 설정 가이드

> **이 가이드는 코딩을 잘 모르는 분도 따라할 수 있도록 모든 과정을 단계별로 설명합니다.**
> 화면 설명과 함께 실제 코드 예제를 제공하므로, 화면을 보면서 그대로 따라하시면 됩니다.

---

## 목차

1. [Firebase 프로젝트 생성](#1-firebase-프로젝트-생성)
2. [Flutter 앱 등록](#2-flutter-앱-등록)
3. [Firebase 서비스 활성화](#3-firebase-서비스-활성화)
4. [Google Maps API 키 설정](#4-google-maps-api-키-설정)
5. [Cloud Functions 설정](#5-cloud-functions-설정)
6. [FCM (푸시 알림) 설정](#6-fcm-푸시-알림-설정)
7. [환경 변수 및 보안](#7-환경-변수-및-보안)
8. [빌드 및 실행 체크리스트](#8-빌드-및-실행-체크리스트)

---

## 사전 준비 사항

이 가이드를 시작하기 전에 아래 계정들이 준비되어 있어야 합니다.

| 필요 항목 | 용도 | 비고 |
|-----------|------|------|
| Google 계정 | Firebase, Google Cloud 사용 | 무료 |
| Apple Developer 계정 | Apple 로그인, iOS 앱 배포 | 연 $99 |
| Flutter 개발 환경 | 앱 빌드 및 실행 | 무료 |

---

## 1. Firebase 프로젝트 생성

Firebase는 앱의 백엔드(서버) 역할을 하는 서비스입니다. 카페온도 앱의 모든 데이터가 여기에 저장됩니다.

### 1-1. Firebase Console 접속

1. 브라우저에서 **[https://console.firebase.google.com](https://console.firebase.google.com)** 에 접속합니다.
2. Google 계정으로 로그인합니다.
3. 파란색 **"프로젝트 추가"** 버튼을 클릭합니다.

> 📸 **화면 설명:** 메인 화면에 기존 프로젝트 목록이 카드 형태로 보이고, 오른쪽 상단 또는 카드 목록 안에 **"+ 프로젝트 추가"** 버튼이 있습니다.

### 1-2. 프로젝트 이름 입력

1. **"프로젝트 이름 입력"** 필드에 `cafeondo` 를 입력합니다.
2. 프로젝트 ID가 자동으로 생성됩니다 (예: `cafeondo-12345`). 이 ID는 나중에 변경할 수 없으니 확인합니다.
3. **"계속"** 버튼을 클릭합니다.

> 📸 **화면 설명:** 회색 입력창에 프로젝트 이름을 입력하면, 아래에 "프로젝트 ID: cafeondo-xxxxx" 형태로 고유 ID가 자동 생성됩니다.

### 1-3. Google Analytics 활성화

1. **"이 프로젝트에서 Google 애널리틱스 사용 설정"** 토글이 **파란색(켜짐)** 상태인지 확인합니다.
2. **"계속"** 버튼을 클릭합니다.

> ⚠️ **중요:** Google Analytics는 반드시 켜두세요. 나중에 Firebase Remote Config, A/B 테스트 등 다양한 기능을 사용할 때 필요합니다.

### 1-4. Analytics 계정 선택

1. **"Google 애널리틱스 계정 선택"** 드롭다운에서 `Default Account for Firebase` 를 선택합니다. (처음 사용하는 경우 자동으로 선택됩니다.)
2. **"프로젝트 만들기"** 버튼을 클릭합니다.

> 📸 **화면 설명:** 약 30초~1분 정도 로딩 화면이 나타납니다. 완료되면 "새 프로젝트가 준비되었습니다" 메시지와 함께 **"계속"** 버튼이 나타납니다.

### 1-5. 프로젝트 생성 완료

**"계속"** 버튼을 클릭하면 Firebase 프로젝트 대시보드로 이동합니다.

> ✅ **확인:** 왼쪽 상단에 "cafeondo" 프로젝트 이름이 보이면 성공입니다.

---

## 2. Flutter 앱 등록

Firebase 프로젝트에 카페온도 앱(Android/iOS)을 각각 등록해야 합니다.

### Android 앱 추가

#### 2-1. Android 앱 등록 시작

1. Firebase 대시보드 중앙의 Android 아이콘(로봇 모양)을 클릭합니다.
2. 또는 왼쪽 사이드바 상단 "Project Overview" 옆 **⚙️ 설정 아이콘** → **"프로젝트 설정"** → **"일반"** 탭 → 하단 **"앱 추가"** 버튼 클릭 후 Android를 선택합니다.

> 📸 **화면 설명:** 프로젝트 대시보드 중앙에 iOS, Android, Web 아이콘이 크게 표시됩니다. Android 아이콘(초록색 로봇)을 클릭합니다.

#### 2-2. Android 앱 정보 입력

다음 정보를 각 필드에 입력합니다:

| 필드 | 값 |
|------|-----|
| Android 패키지 이름 | `com.cafeondo.app` |
| 앱 닉네임 (선택사항) | `카페온도 Android` |
| 디버그 서명 인증서 SHA-1 | (나중에 추가 가능, 지금은 비워도 됩니다) |

> ⚠️ **주의:** 패키지 이름은 **정확히** `com.cafeondo.app` 으로 입력해야 합니다. 대소문자도 일치해야 합니다. 나중에 변경하기 매우 어렵습니다.

**"앱 등록"** 버튼을 클릭합니다.

#### 2-3. google-services.json 다운로드

1. 파란색 **"google-services.json 다운로드"** 버튼을 클릭합니다.
2. 다운로드된 파일을 Flutter 프로젝트의 **`android/app/`** 폴더 안에 넣습니다.

> 📸 **화면 설명:** 다운로드 버튼 아래에 파일을 어디에 놓아야 하는지 경로가 표시됩니다: `android/app/google-services.json`

> ⚠️ **중요:** 이 파일은 `android/app/` 폴더에 직접 넣어야 합니다. `android/` 폴더가 아닙니다!

#### 2-4. android/build.gradle 설정

Flutter 프로젝트에서 `android/build.gradle` 파일을 열고, 아래 내용을 확인/추가합니다.

**파일 위치:** `[프로젝트 루트]/android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        // ✅ 아래 줄을 추가하세요
        classpath 'com.google.gms:google-services:4.4.1'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

> 📝 **설명:** `classpath 'com.google.gms:google-services:4.4.1'` 이 줄이 없으면 Firebase가 Android에서 작동하지 않습니다.

#### 2-5. android/app/build.gradle 설정

**파일 위치:** `[프로젝트 루트]/android/app/build.gradle`

파일 맨 위에 플러그인을 추가하고, 아래쪽 `dependencies` 섹션에 Firebase BoM을 추가합니다.

```gradle
// 파일 맨 위 (apply plugin 줄들 아래)에 추가
apply plugin: 'com.google.gms.google-services'

android {
    namespace "com.cafeondo.app"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.cafeondo.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true  // ✅ 이 줄을 추가하세요
    }

    // ... 나머지 android 설정 ...
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"

    // ✅ Firebase BoM (Bill of Materials) - 버전 충돌을 자동으로 방지해줍니다
    implementation platform('com.google.firebase:firebase-bom:32.7.0')

    // Firebase 서비스들 (버전 번호 없이 사용 가능)
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-storage'
    implementation 'com.google.firebase:firebase-messaging'

    // Google 로그인
    implementation 'com.google.android.gms:play-services-auth:21.0.0'

    // MultiDex 지원
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

> 📝 **BoM이란?** Bill of Materials의 약자로, Firebase 라이브러리들의 버전을 한 번에 관리해주는 도구입니다. 버전 충돌 없이 안정적으로 사용할 수 있습니다.

**"다음"** 버튼을 클릭합니다 (Firebase Console에서).

#### 2-6. Firebase SDK 추가 확인

Firebase Console에서 "앱에 Firebase SDK 추가" 단계는 Flutter 프로젝트의 `pubspec.yaml`에서 처리하므로, **"다음"** 버튼을 클릭하여 넘어갑니다.

#### 2-7. 설치 확인

Firebase Console에서 자동으로 앱 연결을 확인합니다. 앱을 한 번 실행하면 확인이 됩니다. 지금은 **"이 단계 건너뛰기"** 를 클릭해도 됩니다.

**"콘솔로 계속 진행"** 버튼을 클릭합니다.

---

### iOS 앱 추가

#### 2-8. iOS 앱 등록 시작

1. Firebase 대시보드에서 **"앱 추가"** 버튼을 클릭합니다.
2. Apple(iOS) 아이콘을 클릭합니다.

#### 2-9. iOS 앱 정보 입력

| 필드 | 값 |
|------|-----|
| Apple 번들 ID | `com.cafeondo.app` |
| 앱 닉네임 (선택사항) | `카페온도 iOS` |
| App Store ID (선택사항) | (앱 출시 후 입력 가능) |

**"앱 등록"** 버튼을 클릭합니다.

#### 2-10. GoogleService-Info.plist 다운로드

1. **"GoogleService-Info.plist 다운로드"** 버튼을 클릭합니다.
2. 다운로드된 파일을 Flutter 프로젝트의 **`ios/Runner/`** 폴더 안에 넣습니다.

> ⚠️ **중요:** 파일을 Finder(맥 파일 탐색기)로 `ios/Runner/` 폴더에 복사하는 것만으로는 부족합니다. 반드시 Xcode에서도 추가해야 합니다. (아래 2-11 참조)

#### 2-11. Xcode에서 파일 추가하기

> 이 단계는 Mac에서 Xcode를 열어 진행해야 합니다.

1. 터미널에서 프로젝트 루트로 이동 후 아래 명령어를 실행하여 Xcode를 엽니다:
   ```bash
   open ios/Runner.xcworkspace
   ```
   > ⚠️ `.xcodeproj`가 아니라 **`.xcworkspace`** 파일을 열어야 합니다.

2. Xcode 왼쪽 파일 트리에서 **"Runner"** 폴더를 찾습니다.

3. `GoogleService-Info.plist` 파일을 Finder에서 **Xcode의 Runner 폴더로 드래그 앤 드롭** 합니다.

4. 파일 추가 대화상자가 나타나면:
   - ✅ **"Copy items if needed"** 체크
   - ✅ **"Add to targets: Runner"** 체크
   - **"Finish"** 버튼 클릭

> 📸 **화면 설명:** Xcode 왼쪽 파일 트리에서 "Runner" 폴더 아래에 `AppDelegate.swift`, `Info.plist` 등의 파일이 보입니다. 이 위치에 `GoogleService-Info.plist`가 추가되면 됩니다.

#### 2-12. iOS Podfile 설정

`ios/Podfile` 파일을 열어 iOS 최소 버전이 설정되어 있는지 확인합니다.

**파일 위치:** `[프로젝트 루트]/ios/Podfile`

```ruby
# ios/Podfile
platform :ios, '13.0'  # ✅ 이 줄의 주석(#)을 제거하고 버전을 13.0으로 설정

# ... 나머지 내용 ...
```

> 📝 **설명:** Firebase 최신 버전은 iOS 13.0 이상을 요구합니다. 주석 처리된 경우 `#`을 삭제해야 합니다.

**"다음"**, **"다음"**, **"콘솔로 계속 진행"** 버튼을 순서대로 클릭합니다.

#### 2-13. pubspec.yaml에 Flutter Firebase 패키지 추가

Flutter 프로젝트의 `pubspec.yaml` 파일에 Firebase 패키지를 추가합니다.

**파일 위치:** `[프로젝트 루트]/pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ✅ Firebase 패키지들
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.15.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.19
  cloud_functions: ^4.6.0

  # ✅ 소셜 로그인
  google_sign_in: ^6.2.1

  # ✅ Google Maps
  google_maps_flutter: ^2.5.3
```

저장 후 터미널에서 아래 명령어를 실행합니다:
```bash
flutter pub get
```

---

## 3. Firebase 서비스 활성화

### Authentication (인증)

카페온도는 구글 로그인, 애플 로그인, 익명 로그인 3가지를 지원합니다.

#### 3-1. Authentication 활성화

1. Firebase Console 왼쪽 사이드바에서 **"빌드"** 메뉴를 펼칩니다.
2. **"Authentication"** 을 클릭합니다.
3. 파란색 **"시작하기"** 버튼을 클릭합니다.

> 📸 **화면 설명:** "Sign-in method", "Users", "Templates" 탭이 있는 화면으로 이동합니다.

#### 3-2. Google 로그인 활성화

1. **"Sign-in method"** 탭에서 **"Google"** 을 클릭합니다.
2. **"사용 설정"** 토글을 켭니다 (파란색으로 변경).
3. **"프로젝트의 공개용 이름"** 필드에 `카페온도` 를 입력합니다.
4. **"프로젝트 지원 이메일"** 드롭다운에서 본인 이메일을 선택합니다.
5. **"저장"** 버튼을 클릭합니다.

> ✅ **확인:** Google 로그인 옆에 초록색 점과 "사용 설정됨" 표시가 보이면 성공입니다.

#### 3-3. Apple 로그인 활성화

> ⚠️ **사전 요구사항:** Apple Developer 계정이 있어야 합니다. [https://developer.apple.com](https://developer.apple.com) 에서 가입 가능합니다. (연 $99)

**Apple Developer Console 설정 (먼저 진행):**

1. [https://developer.apple.com/account](https://developer.apple.com/account) 에 접속합니다.
2. **"Certificates, IDs & Profiles"** 를 클릭합니다.
3. 왼쪽 메뉴에서 **"Identifiers"** → **"App IDs"** 에서 `com.cafeondo.app` 앱을 찾습니다.
4. 앱을 클릭하고 **"Sign In with Apple"** 항목을 찾아 ✅ 체크합니다.
5. **"Save"** 를 클릭합니다.

**Firebase Console에서 Apple 로그인 설정:**

1. Firebase Console → Authentication → Sign-in method → **"Apple"** 을 클릭합니다.
2. **"사용 설정"** 토글을 켭니다.
3. 나머지 설정은 기본값으로 두고 **"저장"** 을 클릭합니다.

> 📝 **추가 설정 (iOS Xcode에서):**
> 1. Xcode에서 Runner 프로젝트를 열고, **"Runner" 타깃** 선택
> 2. **"Signing & Capabilities"** 탭으로 이동
> 3. **"+ Capability"** 버튼 클릭
> 4. **"Sign In with Apple"** 검색 후 더블클릭하여 추가

#### 3-4. 익명 로그인 활성화

1. Firebase Console → Authentication → Sign-in method → **"익명"** 을 클릭합니다.
2. **"사용 설정"** 토글을 켭니다.
3. **"저장"** 을 클릭합니다.

> 📝 **익명 로그인이란?** 회원가입 없이도 앱을 사용할 수 있게 해주는 기능입니다. 나중에 구글/애플 계정으로 연동할 수 있습니다.

---

### Cloud Firestore (데이터베이스)

Firestore는 카페온도의 모든 데이터(카페 정보, 온도 측정 데이터, 사용자 정보)가 저장되는 데이터베이스입니다.

#### 3-5. Firestore 데이터베이스 생성

1. Firebase Console 왼쪽 사이드바 → **"빌드"** → **"Firestore Database"** 를 클릭합니다.
2. **"데이터베이스 만들기"** 버튼을 클릭합니다.

#### 3-6. 데이터베이스 위치 설정

> 🇰🇷 **한국 서비스이므로 서울 리전을 선택합니다. 한 번 설정하면 변경 불가능하니 신중히 선택하세요!**

1. **"데이터베이스 ID"** 는 기본값 `(default)` 그대로 둡니다.
2. **"위치"** 드롭다운에서 **`asia-northeast3 (서울)`** 을 선택합니다.
3. **"다음"** 버튼을 클릭합니다.

> 📸 **화면 설명:** 드롭다운 목록에서 "asia-northeast3 (Seoul, South Korea)"를 선택합니다. 지역이 가까울수록 데이터 로딩 속도가 빨라집니다.

#### 3-7. 보안 규칙 초기 설정

**"테스트 모드로 시작"** 을 선택합니다.

> ⚠️ **주의:** 테스트 모드는 30일 동안만 열려 있습니다. 앱 출시 전에 반드시 프로덕션 규칙으로 변경해야 합니다.

**"만들기"** 버튼을 클릭합니다.

#### 3-8. 카페온도 전용 Firestore 보안 규칙

데이터베이스 생성 후, **"규칙"** 탭을 클릭하여 아래 규칙을 입력합니다.

**개발용 규칙 (테스트 중 사용):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 개발 중에는 인증된 사용자 모두 허용 (30일 후 프로덕션 규칙으로 변경)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**프로덕션용 규칙 (앱 출시 시 사용):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ===== cafes (카페 정보) =====
    // 누구나 읽기 가능, 관리자만 쓰기 가능
    match /cafes/{cafeId} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.token.admin == true;

      // measurements (온도 측정 데이터) - cafes 하위 컬렉션
      match /measurements/{measurementId} {
        allow read: if true;
        allow create: if request.auth != null;  // 로그인한 사용자만 온도 등록 가능
        allow update, delete: if request.auth != null
                              && request.auth.uid == resource.data.userId;
      }
    }

    // ===== users (사용자 정보) =====
    // 본인 데이터만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }

    // 그 외 모든 경로는 접근 거부
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

규칙을 입력한 후 **"게시"** 버튼을 클릭합니다.

> 📝 **규칙 설명:**
> - `cafes` 컬렉션: 모든 사람이 카페 정보를 볼 수 있지만, 관리자만 수정 가능
> - `measurements` 컬렉션: 로그인한 사용자라면 온도 데이터 등록 가능, 본인이 등록한 데이터만 수정/삭제 가능
> - `users` 컬렉션: 본인 정보만 접근 가능

---

### Firebase Storage (파일 저장소)

Storage는 카페 사진 등 이미지 파일을 저장하는 공간입니다.

#### 3-9. Storage 버킷 생성

1. Firebase Console 왼쪽 사이드바 → **"빌드"** → **"Storage"** 를 클릭합니다.
2. **"시작하기"** 버튼을 클릭합니다.
3. **"테스트 모드로 시작"** 을 선택하고 **"다음"** 클릭합니다.
4. 위치는 Firestore와 동일한 **`asia-northeast3 (서울)`** 을 선택합니다.
5. **"완료"** 버튼을 클릭합니다.

#### 3-10. Storage 보안 규칙 설정

Storage → **"규칙"** 탭에서 아래 규칙을 입력합니다.

**프로덕션용 Storage 보안 규칙:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ===== 카페 이미지 =====
    match /cafes/{cafeId}/{imageFile} {
      // 누구나 이미지 읽기 가능
      allow read: if true;
      // 로그인한 사용자만 업로드 가능 (이미지 파일만, 최대 5MB)
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    // ===== 사용자 프로필 이미지 =====
    match /users/{userId}/{imageFile} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 2 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    // 그 외 경로는 모두 접근 거부
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

**"게시"** 버튼을 클릭합니다.

> 📝 **규칙 설명:**
> - 카페 이미지: 누구나 볼 수 있지만, 업로드는 로그인 사용자만 가능 (최대 5MB, 이미지 파일만)
> - 프로필 이미지: 본인만 업로드 가능 (최대 2MB, 이미지 파일만)

---

## 4. Google Maps API 키 설정

카페온도는 지도에서 카페 위치를 보여주기 위해 Google Maps를 사용합니다.

### 4-1. Google Cloud Console 접속

1. [https://console.cloud.google.com](https://console.cloud.google.com) 에 접속합니다.
2. 상단의 프로젝트 선택 드롭다운에서 **"cafeondo"** 프로젝트를 선택합니다.

> 📝 **참고:** Firebase 프로젝트는 자동으로 Google Cloud 프로젝트와 연결됩니다. 동일한 Google 계정으로 로그인하면 자동으로 보입니다.

### 4-2. Maps SDK 활성화

1. 왼쪽 상단 **☰ 메뉴** → **"API 및 서비스"** → **"라이브러리"** 를 클릭합니다.
2. 검색창에 `Maps SDK for Android` 를 검색합니다.
3. 검색 결과에서 **"Maps SDK for Android"** 를 클릭합니다.
4. 파란색 **"사용"** 버튼을 클릭합니다.
5. 다시 라이브러리로 돌아와서 `Maps SDK for iOS` 를 검색합니다.
6. **"Maps SDK for iOS"** 를 클릭하고 **"사용"** 버튼을 클릭합니다.

> 📸 **화면 설명:** 각 SDK 페이지에서 파란색 "사용" 버튼이 보입니다. 이미 활성화된 경우에는 "API 관리" 버튼이 표시됩니다.

### 4-3. API 키 생성

1. **"API 및 서비스"** → **"사용자 인증 정보"** 를 클릭합니다.
2. 상단 **"+ 사용자 인증 정보 만들기"** 버튼 클릭 → **"API 키"** 선택합니다.
3. 생성된 API 키를 복사합니다 (예: `AIzaSyD1234567890abcdefghij`).

> ⚠️ **보안 주의:** API 키를 GitHub 등 공개 저장소에 절대 올리지 마세요!

### 4-4. API 키 제한 설정 (보안 강화)

> 📌 **이 단계는 매우 중요합니다.** API 키를 제한하지 않으면 다른 사람이 키를 훔쳐서 비용을 발생시킬 수 있습니다.

생성된 API 키를 클릭하여 편집 화면으로 이동합니다.

**Android용 API 키 설정:**

1. **"키 이름"** 을 `카페온도 Android Maps Key` 로 변경합니다.
2. **"애플리케이션 제한사항"** 에서 **"Android 앱"** 을 선택합니다.
3. **"Android 앱 추가"** 를 클릭하고:
   - 패키지 이름: `com.cafeondo.app`
   - SHA-1 서명 인증서 지문: (아래 명령어로 확인)
   ```bash
   # 터미널에서 실행
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. **"API 제한사항"** 에서 **"키 제한"** 선택 → **"Maps SDK for Android"** 체크
5. **"저장"** 클릭

**iOS용 API 키 설정 (별도 키 생성 권장):**

위와 동일하게 새 API 키를 만들고:
1. **"키 이름"** 을 `카페온도 iOS Maps Key` 로 변경합니다.
2. **"애플리케이션 제한사항"** 에서 **"iOS 앱"** 을 선택합니다.
3. **"번들 ID 추가"** 클릭 → `com.cafeondo.app` 입력
4. **"API 제한사항"** 에서 **"Maps SDK for iOS"** 체크
5. **"저장"** 클릭

### 4-5. Android: AndroidManifest.xml에 키 추가

**파일 위치:** `[프로젝트 루트]/android/app/src/main/AndroidManifest.xml`

`<application>` 태그 안에 아래 내용을 추가합니다:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="cafeondo"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- ✅ Google Maps API 키 추가 -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="여기에_Android_API_키를_입력하세요"/>

        <!-- 나머지 기존 내용... -->
        <activity
            android:name=".MainActivity"
            ...>
        </activity>
    </application>
</manifest>
```

> ⚠️ **주의:** `여기에_Android_API_키를_입력하세요` 부분을 실제 API 키로 교체해야 합니다.

### 4-6. iOS: AppDelegate.swift에 키 추가

**파일 위치:** `[프로젝트 루트]/ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import GoogleMaps  // ✅ 이 줄 추가

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ Google Maps 초기화 (iOS용 API 키 입력)
    GMSServices.provideAPIKey("여기에_iOS_API_키를_입력하세요")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

> ⚠️ **주의:** `여기에_iOS_API_키를_입력하세요` 부분을 실제 iOS용 API 키로 교체해야 합니다.

---

## 5. Cloud Functions 설정

Cloud Functions는 서버에서 실행되는 코드입니다. 예약 알림 발송, 데이터 처리 등에 사용됩니다.

### 5-1. Firebase CLI 설치

터미널을 열고 아래 명령어를 실행합니다:

```bash
# Node.js가 설치되어 있어야 합니다
# Node.js 설치 확인
node --version  # v18.0.0 이상이어야 함

# Firebase CLI 설치
npm install -g firebase-tools

# 설치 확인
firebase --version
```

> 📝 **Node.js가 없다면?**
> [https://nodejs.org](https://nodejs.org) 에서 LTS 버전을 다운로드하여 설치합니다.

### 5-2. Firebase 로그인

```bash
# Firebase 계정으로 로그인
firebase login
```

브라우저가 자동으로 열리면 Google 계정으로 로그인합니다.

```bash
# 로그인 확인
firebase projects:list
# cafeondo 프로젝트가 목록에 보이면 성공
```

### 5-3. Flutter 프로젝트에 Firebase 연결

```bash
# 프로젝트 루트 디렉토리에서 실행
cd [프로젝트 루트 경로]

# FlutterFire CLI 설치 (Flutter ↔ Firebase 자동 연결 도구)
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결 및 firebase_options.dart 자동 생성
flutterfire configure
```

> 📸 **화면 설명:** 터미널에 프로젝트 목록이 나타납니다. 방향키로 `cafeondo`를 선택하고 Enter를 누릅니다. 그다음 Android와 iOS 모두 선택합니다.

이 명령어가 완료되면 `lib/firebase_options.dart` 파일이 자동으로 생성됩니다.

### 5-4. Functions 디렉토리 초기화

```bash
# 프로젝트 루트에서 실행
firebase init functions
```

아래 선택지가 나타납니다:

```
? Please select an option: Use an existing project
? Select a default Firebase project for this directory: cafeondo (cafeondo)
? What language would you like to use to write Cloud Functions? JavaScript
? Do you want to use ESLint to catch probable bugs and enforce style? No
? Do you want to install dependencies with npm now? Yes
```

> 📝 **선택 안내:**
> - 기존 프로젝트 사용 (`Use an existing project`)
> - `cafeondo` 프로젝트 선택
> - 언어: **JavaScript** 선택
> - ESLint: **No** 선택 (처음에는 불필요)
> - 의존성 설치: **Yes** 선택

### 5-5. Node.js 20 설정

`functions/package.json` 파일을 열어 Node.js 버전을 설정합니다:

**파일 위치:** `[프로젝트 루트]/functions/package.json`

```json
{
  "name": "functions",
  "description": "카페온도 Cloud Functions",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "20"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^11.8.0",
    "firebase-functions": "^4.3.1"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0"
  },
  "private": true
}
```

### 5-6. 기본 Functions 코드 확인

`functions/index.js` 파일이 아래와 같이 설정되어 있는지 확인합니다:

```javascript
// functions/index.js
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// 예시: 새 카페 등록 시 알림 발송
exports.onNewCafe = onDocumentCreated("cafes/{cafeId}", async (event) => {
  const cafeData = event.data.data();
  console.log("새 카페 등록:", cafeData.name);
  // FCM 알림 로직 추가 가능
});
```

### 5-7. Functions 배포

```bash
# functions 폴더에서 실행
cd functions
npm install

# Firebase에 배포
firebase deploy --only functions
```

> 📝 **처음 배포 시 시간이 걸립니다.** 약 2~3분 소요됩니다.

---

## 6. FCM (푸시 알림) 설정

FCM(Firebase Cloud Messaging)은 앱 사용자에게 푸시 알림을 보내는 서비스입니다.

### Android: 추가 설정 불필요

Android는 `google-services.json` 파일에 FCM 설정이 이미 포함되어 있습니다. 별도 설정이 필요하지 않습니다.

> ✅ **확인 사항:** `android/app/build.gradle`에 `implementation 'com.google.firebase:firebase-messaging'` 이 있으면 됩니다. (2-5 단계에서 이미 추가했습니다.)

### iOS: APNs 키 업로드

iOS 푸시 알림은 Apple의 APNs(Apple Push Notification service)를 통해 전달됩니다. Firebase에 APNs 키를 등록해야 합니다.

#### 6-1. Apple Developer에서 APNs 키 생성

1. [https://developer.apple.com/account](https://developer.apple.com/account) 접속
2. **"Certificates, IDs & Profiles"** 클릭
3. 왼쪽 메뉴 **"Keys"** 클릭
4. **"+"** 버튼 클릭하여 새 키 생성
5. **"Key Name"** 에 `카페온도 APNs Key` 입력
6. **"Apple Push Notifications service (APNs)"** 체크
7. **"Continue"** → **"Register"** 클릭
8. **"Download"** 버튼 클릭 (⚠️ 이 파일은 한 번만 다운로드 가능합니다!)

> 📸 **화면 설명:** 다운로드되는 파일은 `.p8` 확장자입니다 (예: `AuthKey_XXXXXXXXXX.p8`). 안전한 곳에 보관하세요.

다운로드 페이지에서 아래 정보를 메모해둡니다:
- **Key ID:** 10자리 영문+숫자 (예: `ABC1234567`)

#### 6-2. Team ID 확인

1. Apple Developer Console 오른쪽 상단에 있는 계정 이름 클릭
2. 또는 **"Membership"** 메뉴에서 **Team ID** 확인 (10자리 영문+숫자)

#### 6-3. Firebase에 APNs 키 업로드

1. Firebase Console → **"프로젝트 설정"** (⚙️ 아이콘 클릭)
2. **"클라우드 메시징"** 탭 클릭
3. **"Apple 앱 구성"** 섹션에서 iOS 앱(`com.cafeondo.app`)을 찾습니다.
4. **"APNs 인증 키"** 옆의 **"업로드"** 버튼 클릭
5. 다운로드한 `.p8` 파일 선택
6. **"키 ID"** 와 **"팀 ID"** 를 각 필드에 입력
7. **"업로드"** 버튼 클릭

> ✅ **확인:** 업로드 완료 후 "APNs 인증 키: 업로드됨" 표시가 보이면 성공입니다.

#### 6-4. iOS Xcode에서 Push Notifications Capability 추가

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. 왼쪽 파일 트리에서 **"Runner"** 클릭
3. **"Signing & Capabilities"** 탭 선택
4. **"+ Capability"** 버튼 클릭
5. **"Push Notifications"** 검색 후 더블클릭
6. **"Background Modes"** 도 추가하고:
   - ✅ **"Background fetch"** 체크
   - ✅ **"Remote notifications"** 체크

#### 6-5. AppDelegate.swift에 FCM 설정 추가

```swift
import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps 초기화
    GMSServices.provideAPIKey("여기에_iOS_API_키를_입력하세요")

    // Firebase 초기화
    FirebaseApp.configure()

    // FCM 설정
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    // 푸시 알림 권한 요청
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound],
      completionHandler: { _, _ in }
    )
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // FCM 토큰 갱신 시 처리
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM 토큰: \(fcmToken ?? "없음")")
  }
}
```

---

## 7. 환경 변수 및 보안

### 7-1. API 키 관리 (.env 사용)

민감한 API 키들은 코드에 직접 넣지 않고 `.env` 파일로 관리합니다.

프로젝트 루트에 `.env` 파일을 생성합니다:

```
# .env 파일 (절대 GitHub에 올리면 안 됩니다!)
GOOGLE_MAPS_API_KEY_ANDROID=여기에_Android_API_키_입력
GOOGLE_MAPS_API_KEY_IOS=여기에_iOS_API_키_입력
```

`pubspec.yaml`에 `flutter_dotenv` 패키지를 추가합니다:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

`pubspec.yaml`의 `flutter` 섹션에 assets 추가:

```yaml
flutter:
  assets:
    - .env
```

Dart 코드에서 사용:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// main.dart
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  // ...
}

// 사용 시
final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
```

### 7-2. .gitignore 설정

프로젝트 루트의 `.gitignore` 파일에 아래 내용을 추가합니다:

```gitignore
# 환경 변수 파일 (절대 GitHub에 올리지 않음)
.env
.env.local
.env.production

# ✅ google-services.json과 GoogleService-Info.plist는
# Firebase 권장사항에 따라 .gitignore에 넣지 않습니다.
# 이 파일들 자체는 공개 정보이며, Firebase 보안 규칙으로 보호됩니다.
# 단, 팀 프로젝트가 아닌 개인 프로젝트의 경우 gitignore에 추가해도 됩니다.

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec

# Android
android/.gradle/
android/captures/

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
```

> 📝 **google-services.json에 대한 Firebase 권장사항:**
> Firebase 공식 문서에 따르면, `google-services.json`과 `GoogleService-Info.plist` 파일에는 API 키가 포함되어 있지만, 이 키들은 Firebase 보안 규칙과 앱 제한으로 보호됩니다. Firebase 팀은 이 파일들을 버전 관리에 포함하는 것을 권장합니다. 단, `.env` 파일에 있는 Google Maps API 키는 반드시 gitignore에 포함해야 합니다.

### 7-3. 프로덕션 vs 개발 환경 분리

Flutter에서 개발/프로덕션 환경을 구분하는 방법입니다.

`lib/config/app_config.dart` 파일 생성:

```dart
// lib/config/app_config.dart

enum AppEnvironment { development, production }

class AppConfig {
  final AppEnvironment environment;
  final String appName;

  const AppConfig({
    required this.environment,
    required this.appName,
  });

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  // 개발 환경 설정
  static const development = AppConfig(
    environment: AppEnvironment.development,
    appName: '카페온도 (개발)',
  );

  // 프로덕션 환경 설정
  static const production = AppConfig(
    environment: AppEnvironment.production,
    appName: '카페온도',
  );
}
```

`lib/main.dart`에서 환경 설정:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';

// 개발 모드로 실행할 때
void main() => mainWithConfig(AppConfig.development);

// 프로덕션 모드로 실행할 때 (배포 시 이 줄을 사용)
// void main() => mainWithConfig(AppConfig.production);

Future<void> mainWithConfig(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp(config: config));
}
```

---

## 8. 빌드 및 실행 체크리스트

### 8-1. 의존성 설치

```bash
# 프로젝트 루트에서 실행
flutter pub get
```

> 📝 오류 없이 완료되면 계속 진행합니다.

### 8-2. Android 빌드 확인

```bash
# Android 앱 디버그 빌드
flutter build apk --debug

# 또는 에뮬레이터/기기에서 직접 실행
flutter run
```

**Android 빌드 성공 확인:**
- `✓ Built build/app/outputs/flutter-apk/app-debug.apk` 메시지 확인

### 8-3. iOS 빌드 확인

```bash
# iOS용 CocoaPods 의존성 설치 (Mac에서만 가능)
cd ios
pod install
cd ..

# iOS 앱 디버그 빌드
flutter build ios --debug --no-codesign

# 시뮬레이터에서 실행
flutter run
```

**iOS pod install 성공 확인:**
- `Pod installation complete!` 메시지 확인

### 8-4. Firebase 연결 확인

앱 실행 후 Firebase Console → **"Authentication"** → **"Users"** 탭에서 테스트 계정이 생성되는지 확인합니다.

---

### 흔한 에러 및 해결 방법

#### ❌ 에러 1: `google-services.json` 파일을 찾을 수 없음

```
FAILURE: Build failed with an exception.
> File google-services.json is missing.
```

**해결 방법:**
- `google-services.json` 파일이 `android/app/` 폴더에 있는지 확인합니다.
- `android/` 폴더가 아니라 `android/app/` 폴더입니다!

---

#### ❌ 에러 2: iOS Pod 설치 오류

```
[!] CocoaPods could not find compatible versions for pod "Firebase/Core"
```

**해결 방법:**
```bash
cd ios
pod repo update
pod install --repo-update
```

---

#### ❌ 에러 3: Android minSdkVersion 오류

```
uses-sdk:minSdkVersion 16 cannot be smaller than version 21
```

**해결 방법:**
`android/app/build.gradle`에서 `minSdkVersion`을 `21`로 변경합니다:
```gradle
defaultConfig {
    minSdkVersion 21  // 16에서 21로 변경
}
```

---

#### ❌ 에러 4: FlutterFire CLI를 찾을 수 없음

```
bash: flutterfire: command not found
```

**해결 방법:**
```bash
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

`~/.zshrc` 또는 `~/.bashrc` 파일에 `export PATH="$PATH":"$HOME/.pub-cache/bin"` 줄을 추가합니다.

---

#### ❌ 에러 5: Google Sign-In 오류 (Android)

```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

**해결 방법:**
1. `android/app/build.gradle`에서 SHA-1 지문이 Firebase Console에 등록되어 있는지 확인합니다.
2. Firebase Console → 프로젝트 설정 → Android 앱 → **"디지털 지문 추가"** 에서 SHA-1을 추가합니다.
3. SHA-1 확인 명령어:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

---

#### ❌ 에러 6: iOS Google Sign-In 오류

**해결 방법:**
`ios/Runner/Info.plist` 파일에 URL Scheme이 추가되어 있는지 확인합니다.

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- GoogleService-Info.plist 파일에서 REVERSED_CLIENT_ID 값을 복사하세요 -->
            <string>com.googleusercontent.apps.여기에_REVERSED_CLIENT_ID_입력</string>
        </array>
    </dict>
</array>
```

`REVERSED_CLIENT_ID` 값은 `GoogleService-Info.plist` 파일을 열어서 찾을 수 있습니다.

---

#### ❌ 에러 7: Firestore 권한 거부

```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

**해결 방법:**
Firebase Console → Firestore → **"규칙"** 탭에서 보안 규칙이 올바르게 설정되어 있는지 확인합니다. 개발 중에는 아래 규칙을 임시로 사용합니다:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 최종 체크리스트

설정이 모두 완료되었는지 아래 목록을 확인하세요.

### Firebase 설정
- [ ] Firebase 프로젝트 생성 완료 (`cafeondo`)
- [ ] Android 앱 등록 (`com.cafeondo.app`)
- [ ] `google-services.json` → `android/app/` 폴더에 배치
- [ ] iOS 앱 등록 (`com.cafeondo.app`)
- [ ] `GoogleService-Info.plist` → `ios/Runner/` 폴더에 배치 + Xcode에 추가
- [ ] Authentication: Google 로그인 활성화
- [ ] Authentication: Apple 로그인 활성화
- [ ] Authentication: 익명 로그인 활성화
- [ ] Firestore 데이터베이스 생성 (서울 리전: `asia-northeast3`)
- [ ] Firestore 보안 규칙 설정
- [ ] Storage 버킷 생성 (서울 리전)
- [ ] Storage 보안 규칙 설정

### Google Maps 설정
- [ ] Maps SDK for Android 활성화
- [ ] Maps SDK for iOS 활성화
- [ ] Android API 키 생성 및 `AndroidManifest.xml`에 추가
- [ ] iOS API 키 생성 및 `AppDelegate.swift`에 추가

### Cloud Functions 설정
- [ ] Firebase CLI 설치
- [ ] `flutterfire configure` 실행 → `firebase_options.dart` 생성
- [ ] `functions/` 초기화 (Node.js 20)
- [ ] `package.json`에 `"node": "20"` 설정

### FCM (푸시 알림) 설정
- [ ] APNs 키 생성 (.p8 파일 보관)
- [ ] Firebase Console에 APNs 키 업로드
- [ ] Xcode에 Push Notifications Capability 추가
- [ ] `AppDelegate.swift`에 FCM 코드 추가

### 보안
- [ ] `.env` 파일 생성 (API 키 관리)
- [ ] `.gitignore`에 `.env` 추가
- [ ] API 키 애플리케이션 제한 설정 완료
- [ ] 프로덕션 배포 전 Firestore/Storage 보안 규칙 업데이트

---

## 참고 링크

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 공식 문서](https://firebase.flutter.dev)
- [Google Maps Flutter 플러그인](https://pub.dev/packages/google_maps_flutter)
- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Console](https://console.cloud.google.com)
- [Apple Developer Console](https://developer.apple.com/account)

---

> 📌 **도움이 필요하신가요?**
> 각 단계에서 문제가 발생하면 [Firebase 공식 커뮤니티](https://firebase.google.com/community) 또는 [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase+flutter)에서 검색해보세요. 대부분의 오류는 이미 해결 방법이 공유되어 있습니다.
