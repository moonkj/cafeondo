# 카페온도 개발 진행 일지

## 2026-03-01

### 빌드 & 배포
- [x] Flutter 3.41.2 + Xcode 26.2 beta 빌드 파이프라인 구축
- [x] `xcode_backend.dart:345` Xcode 26 beta null check 버그 패치
- [x] iOS 릴리즈 빌드 성공 (development 서명)
- [x] `xcrun devicectl` 로 실기기(Moon, iOS 26.4) 설치 자동화

### 버그 수정
- [x] **흰 화면 버그 #1** - `localizationsDelegates` 누락 추가 (`GlobalMaterialLocalizations` 등)
- [x] **흰 화면 버그 #2** - `NotificationService.initialize()` 가 `runApp()` 전에 blocking → `runApp()` 이후 fire-and-forget으로 변경
- [x] **흰 화면 버그 #3** - `Firebase.initializeApp()` 예외 처리 추가
- [x] **지도 마커 크래시** - `map_view.dart:133` `bytes!` null assertion → null check + defaultMarker fallback
- [x] `intl` 버전 `^0.20.2`로 업그레이드 (flutter_localizations 호환)
- [x] `pubspec.yaml` - `flutter_localizations` SDK 패키지 추가

### UI / UX 개선
- [x] **지도 엔진 교체** - Google Maps → `flutter_map` (OSM, API키 불필요)
  - 이유: Google Maps iOS API키 활성화 필요 없이 즉시 작동
  - OSM 타일에 민트 컬러 필터 적용해 앱 브랜드와 조화
- [x] **하단 네비게이션 재구성** (지도 / 탐색 / 랭킹 / 프로필)
  - 기존 측정(Measure) 탭 제거 → 탐색(Explore) 탭 추가
  - 측정은 카페 상세 화면에서만 진입 가능 (위치 기반 측정 컨셉 강화)
  - 선택된 탭에 민트 pill indicator 애니메이션 적용
- [x] **홈 화면 측정 FAB 제거** - 지도 화면에서 측정 버튼 제거
- [x] **앱 아이콘 교체** - `icon-1.png` (커피컵 + 소음파형) iOS/Android 전체 사이즈 적용

### 브랜드 언어 개편 (소음 레벨 → 카페 온도)
기존 부정적 표현 → 카페 분위기 온도 컨셉으로 전환 (카페 사장님 친화적)

| dB 범위 | 기존 | 새 표현 | 온도 태그 |
|---------|------|---------|---------|
| ~50 dB | 조용함 | **딥 포커스** | 몰입 온도 |
| 51-65 dB | 보통 | **소프트 바이브** | 여유 온도 |
| 66-75 dB | 시끄러움 | **소셜 버즈** | 활기 온도 |
| 76+ dB | 매우 시끄러움 | **라이브 에너지** | 열정 온도 |

적용 파일:
- `lib/providers/cafe_providers.dart` - NoiseLevel.label
- `lib/data/models/cafe.dart` - NoiseCategory.label + subtitle
- `lib/core/widgets/noise_indicator.dart` - 아이콘 + 설명 문구
- `lib/features/home/widgets/map_view.dart` - 범례
- `lib/features/explore/explore_screen.dart` - 필터 칩

---

## 2026-03-01 (세션 2)

### iOS 26 Beta 호환성 버그 수정

#### 문제 1: Nested Scaffold 렌더링 실패
- **증상**: 프로필/탐색/랭킹 탭이 아예 표시되지 않음
- **원인**: iOS 26 beta에서 `_MainShell` Scaffold 내부의 중첩 Scaffold가 렌더링되지 않는 버그
- **진단 방법**: ProfileScreen을 초록색 Container로 교체 → 네비게이션은 동작, Scaffold 내용만 미표시 확인
- **수정**:
  - `home_screen.dart` - Scaffold 제거 → Stack 직접 반환
  - `profile_screen.dart` - Scaffold 제거 → Container + Column (수동 AppBar)
  - `explore_screen.dart` - Scaffold 제거 → Container + Stack (FAB은 Positioned으로 처리)
  - `ranking_screen.dart` - Scaffold 제거 → Container + Column (수동 AppBar + TabBar + Expanded TabBarView)

#### 문제 2: flutter_animate 무한 opacity:0
- **증상**: flutter_animate의 `.animate().fadeIn()` 호출 시 위젯이 opacity 0으로 고정
- **원인**: iOS 26 beta CADisplayLink/Ticker 회귀 버그
- **수정**: `profile_screen.dart`, `ranking_screen.dart`, `settings_screen.dart` 에서 flutter_animate import 및 모든 `.animate()` 체인 제거

#### 문제 3: Google Maps PlatformView 미렌더링
- **증상**: 홈 탭 지도 영역이 표시되지 않음
- **원인**: iOS 26 beta에서 TLHC(Texture Layer Hybrid Composition) PlatformView 렌더링 실패
- **임시 조치**: `map_view.dart` - GoogleMap 위젯을 회색 Container placeholder로 대체

#### 문제 4: ProfileViewModel 무한 로딩
- **증상**: 프로필 탭이 렌더링은 되지만 로딩 스피너에서 멈춤
- **원인**: Riverpod 3.x에서 `Notifier.build()` 실행 중 `state` getter 접근 시 StateError 발생
  ```dart
  // build() 호출 시 _loadProfile()의 첫 줄이 동기 실행됨
  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true); // ← build() 완료 전 state 읽기 → StateError
    await Future.delayed(...);  // 여기까지 도달 불가 → 로딩 영구 유지
  ```
- **수정**: `profile_viewmodel.dart` - `_loadProfile()` 최초 라인 `state = state.copyWith(isLoading: true)` 제거 (build()가 이미 `isLoading: true` 반환)

### 현재 상태 (2026-03-01 세션 2 종료)
- 4개 탭 (홈/탐색/랭킹/프로필) 모두 iOS 26 beta에서 렌더링 정상
- 프로필 화면: Mock 유저 데이터 정상 표시
- 지도: 임시 placeholder (Google Maps 미복구)
- 카페 데이터: Mock 6개 (실제 API 미연동)

### 향후 계획 (Next Sprint)
- [ ] 지도 복구: flutter_map(OSM) 또는 Google Maps iOS 26 지원 버전으로 교체
- [ ] 카페 데이터 API 연동 (Kakao 장소 API 또는 Google Places API)
- [ ] 측정 화면: 현재 위치 ↔ 카페 위치 거리 비교 (50m 이내 측정 허용)
- [ ] Firebase Auth + Firestore 실제 연동 (현재 전부 Mock)
- [ ] 온보딩: 알림 권한 요청 플로우 UI 구현
- [ ] 즐겨찾기: 카페 저장 기능
- [ ] 카페 상세: 실시간 소음 업데이트 (Firestore 스트림 연동)
