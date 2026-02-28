/// 카페온도 앱 문자열 상수 (한국어)
abstract class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────────────────────
  static const String appName = '카페온도';
  static const String appTagline = '지금 카페 분위기, 실시간으로';
  static const String appDescription = '카페의 소음 수준을 함께 측정하고 공유해요';

  // ── Navigation ───────────────────────────────────────────────────────────────
  static const String navHome = '지도';
  static const String navRanking = '랭킹';
  static const String navMeasure = '측정';
  static const String navProfile = '프로필';
  static const String navSettings = '설정';

  // ── Home Screen ──────────────────────────────────────────────────────────────
  static const String homeSearchHint = '카페 이름 또는 위치 검색';
  static const String homeNearbyTitle = '내 주변 카페';
  static const String homeFilterAll = '전체';
  static const String homeFilterQuiet = '조용한 곳';
  static const String homeFilterModerate = '적당한 곳';
  static const String homeFilterNoisy = '활기찬 곳';
  static const String homeCurrentLocation = '현재 위치';
  static const String homeNoCafes = '주변에 등록된 카페가 없어요';
  static const String homeAddCafe = '카페 추가하기';

  // ── Cafe Detail ───────────────────────────────────────────────────────────────
  static const String detailNoiseLevel = '소음 수준';
  static const String detailRecentMeasurements = '최근 측정';
  static const String detailAverageDecibel = '평균 데시벨';
  static const String detailTotalMeasurements = '총 측정 횟수';
  static const String detailAtmosphereChart = '시간대별 분위기';
  static const String detailMeasureNow = '지금 측정하기';
  static const String detailPhotos = '사진';
  static const String detailReviews = '리뷰';
  static const String detailNoMeasurements = '아직 측정 데이터가 없어요';
  static const String detailBeFirst = '첫 번째로 측정해보세요!';
  static const String detailOpenHours = '영업 시간';
  static const String detailTags = '태그';

  // ── Measurement ──────────────────────────────────────────────────────────────
  static const String measureTitle = '소음 측정';
  static const String measureStart = '측정 시작';
  static const String measureStop = '측정 완료';
  static const String measureSave = '저장하기';
  static const String measureCancel = '취소';
  static const String measureInProgress = '측정 중...';
  static const String measureComplete = '측정 완료!';
  static const String measurePermissionTitle = '마이크 권한 필요';
  static const String measurePermissionDesc = '소음 측정을 위해 마이크 접근 권한이 필요해요';
  static const String measurePermissionButton = '권한 허용';
  static const String measureDurationLabel = '측정 시간';
  static const String measureDecibelLabel = 'dB';
  static const String measureSeconds = '초';
  static const String measureResult = '측정 결과';
  static const String measureSaveSuccess = '측정이 저장되었어요!';
  static const String measureSaveError = '저장 중 오류가 발생했어요';
  static const String measureLocationTitle = '측정 위치';
  static const String measureSelectCafe = '카페 선택';

  // ── Noise Categories ─────────────────────────────────────────────────────────
  static const String noiseQuiet = '조용함';
  static const String noiseModerate = '보통';
  static const String noiseNoisy = '시끄러움';
  static const String noiseLoud = '매우 시끄러움';
  static const String noiseQuietDesc = '0–40dB · 독서, 집중 작업에 적합';
  static const String noiseModerateDesc = '40–60dB · 가벼운 대화에 적합';
  static const String noiseNoisyDesc = '60–75dB · 활기찬 분위기';
  static const String noiseLoudDesc = '75dB 이상 · 매우 활기찬 분위기';

  // ── Ranking ──────────────────────────────────────────────────────────────────
  static const String rankingTitle = '랭킹';
  static const String rankingQuietest = '가장 조용한 카페';
  static const String rankingMostMeasured = '측정 많은 카페';
  static const String rankingTopContributors = '측정 기여자';
  static const String rankingThisWeek = '이번 주';
  static const String rankingAllTime = '전체';

  // ── Profile ──────────────────────────────────────────────────────────────────
  static const String profileTitle = '프로필';
  static const String profileTotalMeasurements = '총 측정';
  static const String profileLevel = '레벨';
  static const String profilePoints = '포인트';
  static const String profileJoinedAt = '가입일';
  static const String profileMyMeasurements = '내 측정 기록';
  static const String profileEditProfile = '프로필 수정';
  static const String profileSignOut = '로그아웃';
  static const String profileSignIn = '로그인';

  // ── User Levels ───────────────────────────────────────────────────────────────
  static const String levelBeginner = '카페 탐험가';
  static const String levelIntermediate = '소음 감지사';
  static const String levelAdvanced = '카페 고수';
  static const String levelExpert = '카페 마스터';
  static const String levelGrandmaster = '카페온도 레전드';

  // ── URLs ──────────────────────────────────────────────────────────────────
  // TODO: 도메인 구매 후 cafeondo.app 으로 교체하세요.
  static const String urlBase = 'https://moonkj.github.io/cafeondo';
  static const String urlPrivacy = '$urlBase/privacy.html';
  static const String urlTerms = '$urlBase/terms.html';
  static const String urlLocation = '$urlBase/location.html';
  static const String urlContact = 'support@cafeondo.app';
  static const String urlGithub = 'https://github.com/moonkj/cafeondo';

  // ── Settings ─────────────────────────────────────────────────────────────────
  static const String settingsTitle = '설정';
  static const String settingsNotifications = '알림';
  static const String settingsLanguage = '언어';
  static const String settingsPrivacy = '개인정보 처리방침';
  static const String settingsTerms = '이용약관';
  static const String settingsVersion = '버전 정보';
  static const String settingsContact = '문의하기';
  static const String settingsDeleteAccount = '계정 삭제';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static const String authSignInTitle = '로그인';
  static const String authSignInWithGoogle = 'Google로 로그인';
  static const String authSignInWithApple = 'Apple로 로그인';
  static const String authSignInDesc = '측정 기록을 저장하고\n커뮤니티와 공유해보세요';
  static const String authSkip = '나중에';
  static const String authSignedIn = '로그인되었어요';
  static const String authSignedOut = '로그아웃되었어요';
  static const String authError = '로그인 중 오류가 발생했어요';

  // ── Common Actions ────────────────────────────────────────────────────────────
  static const String actionClose = '닫기';
  static const String actionConfirm = '확인';
  static const String actionCancel = '취소';
  static const String actionRetry = '다시 시도';
  static const String actionBack = '뒤로';
  static const String actionNext = '다음';
  static const String actionDone = '완료';
  static const String actionShare = '공유';
  static const String actionReport = '신고';
  static const String actionDelete = '삭제';
  static const String actionEdit = '수정';
  static const String actionSave = '저장';

  // ── Errors ───────────────────────────────────────────────────────────────────
  static const String errorGeneral = '오류가 발생했어요. 다시 시도해주세요.';
  static const String errorNetwork = '인터넷 연결을 확인해주세요.';
  static const String errorLocation = '위치 정보를 가져올 수 없어요.';
  static const String errorPermission = '권한이 필요해요.';
  static const String errorNotFound = '정보를 찾을 수 없어요.';
  static const String errorLoading = '불러오는 중 오류가 발생했어요.';

  // ── Empty States ──────────────────────────────────────────────────────────────
  static const String emptyMeasurements = '측정 기록이 없어요';
  static const String emptyReviews = '리뷰가 없어요';
  static const String emptySearch = '검색 결과가 없어요';

  // ── Time Labels ───────────────────────────────────────────────────────────────
  static const String timeAgo = '전';
  static const String timeMinute = '분';
  static const String timeHour = '시간';
  static const String timeDay = '일';
  static const String timeJustNow = '방금 전';

  // ── Units ────────────────────────────────────────────────────────────────────
  static const String unitDecibel = 'dB';
  static const String unitMeters = 'm';
  static const String unitKilometers = 'km';
  static const String unitCount = '회';
  static const String unitPeople = '명';
}
