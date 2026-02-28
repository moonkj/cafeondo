/**
 * src/utils.js
 * CafeOndo 공통 유틸리티 함수 모음
 *
 * Firestore 스키마 기준:
 *   NoiseCategory : quiet(< 40 dB) / moderate(40–60) / noisy(60–75) / loud(75+)
 *   UserLevel     : beginner(0) / intermediate(10) / advanced(50) / expert(200) / grandmaster(1000)
 */

// ---------------------------------------------------------------------------
// 소음 카테고리
// ---------------------------------------------------------------------------

/**
 * dB 값으로 소음 카테고리 문자열을 반환합니다.
 *
 * @param {number} db - 데시벨 수치
 * @returns {'quiet'|'moderate'|'noisy'|'loud'}
 */
function noiseCategoryFromDb(db) {
  if (db < 40) return "quiet";
  if (db < 60) return "moderate";
  if (db < 75) return "noisy";
  return "loud";
}

/**
 * 소음 카테고리 키를 한국어 레이블로 변환합니다.
 *
 * @param {'quiet'|'moderate'|'noisy'|'loud'} category
 * @returns {string}
 */
function noiseCategoryLabel(category) {
  const labels = {
    quiet: "조용함",
    moderate: "보통",
    noisy: "시끄러움",
    loud: "매우 시끄러움",
  };
  return labels[category] ?? "보통";
}

// ---------------------------------------------------------------------------
// 사용자 레벨 / 포인트
// ---------------------------------------------------------------------------

/**
 * 총 측정 횟수로 레벨 번호(1–5)를 계산합니다.
 * Flutter 모델의 UserLevel enum과 동기화:
 *   beginner=1(0+), intermediate=2(10+), advanced=3(50+), expert=4(200+), grandmaster=5(1000+)
 *
 * @param {number} totalMeasurements
 * @returns {number} 1–5
 */
function calculateLevel(totalMeasurements) {
  if (totalMeasurements >= 1000) return 5; // grandmaster
  if (totalMeasurements >= 200) return 4;  // expert
  if (totalMeasurements >= 50) return 3;   // advanced
  if (totalMeasurements >= 10) return 2;   // intermediate
  return 1;                                 // beginner
}

/**
 * 레벨 번호를 Firestore 저장용 문자열 키로 변환합니다.
 *
 * @param {number} level
 * @returns {string}
 */
function levelToKey(level) {
  const keys = {
    1: "beginner",
    2: "intermediate",
    3: "advanced",
    4: "expert",
    5: "grandmaster",
  };
  return keys[level] ?? "beginner";
}

/**
 * 레벨 키를 한국어 칭호로 변환합니다.
 *
 * @param {string} levelKey
 * @returns {string}
 */
function levelLabel(levelKey) {
  const labels = {
    beginner: "카페 탐험가",
    intermediate: "소음 감지사",
    advanced: "카페 고수",
    expert: "카페 마스터",
    grandmaster: "카페온도 레전드",
  };
  return labels[levelKey] ?? "카페 탐험가";
}

/**
 * 측정 1회에 획득하는 포인트를 반환합니다.
 * Flutter user_repository.dart 의 _calculatePointsForMeasurement 와 동일 로직.
 *
 * @param {number} newMeasurementCount - 이번 측정 후의 누적 횟수
 * @returns {number}
 */
function calculatePointsForMeasurement(newMeasurementCount) {
  if (newMeasurementCount >= 1000) return 50; // grandmaster
  if (newMeasurementCount >= 200) return 30;  // expert
  if (newMeasurementCount >= 50) return 20;   // advanced
  if (newMeasurementCount >= 10) return 15;   // intermediate
  return 10;                                   // beginner
}

/**
 * 총 측정 횟수로 누적 포인트를 추정합니다.
 * (레벨업 경계마다 정확한 값은 DB에서 관리하므로, 이 함수는 초기값 시딩 용도)
 *
 * @param {number} totalMeasurements
 * @param {number} level - 현재 레벨 번호 (1-5)
 * @returns {number}
 */
function calculatePoints(totalMeasurements, level) {
  // 간단 추정: 구간별 단가 × 횟수 합산
  let points = 0;
  const count = totalMeasurements;
  if (count <= 0) return 0;

  // beginner (0–9): 10점/회
  const beginner = Math.min(count, 9);
  points += beginner * 10;
  if (count <= 9) return points;

  // intermediate (10–49): 15점/회
  const intermediate = Math.min(count - 10, 40);
  points += intermediate * 15;
  if (count <= 49) return points;

  // advanced (50–199): 20점/회
  const advanced = Math.min(count - 50, 150);
  points += advanced * 20;
  if (count <= 199) return points;

  // expert (200–999): 30점/회
  const expert = Math.min(count - 200, 800);
  points += expert * 30;
  if (count <= 999) return points;

  // grandmaster (1000+): 50점/회
  points += (count - 1000) * 50;
  return points;
}

// ---------------------------------------------------------------------------
// 날짜 / 시간 유틸
// ---------------------------------------------------------------------------

/**
 * Date 객체를 한국어 형식 문자열로 포맷합니다.
 * 예: "2024년 6월 10일 오후 3:00"
 *
 * @param {Date} date
 * @returns {string}
 */
function formatKoreanDate(date) {
  return new Intl.DateTimeFormat("ko-KR", {
    timeZone: "Asia/Seoul",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}

/**
 * 오늘의 KST 기준 시작 시각(자정 00:00:00)을 UTC Date 로 반환합니다.
 *
 * @returns {Date}
 */
function todayStartKST() {
  const now = new Date();
  // KST = UTC+9 → 로컬 날짜를 KST 자정으로 맞춤
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstNow = new Date(now.getTime() + kstOffset);
  const kstMidnight = new Date(
    Date.UTC(kstNow.getUTCFullYear(), kstNow.getUTCMonth(), kstNow.getUTCDate()),
  );
  // UTC로 되돌림 (-9h)
  return new Date(kstMidnight.getTime() - kstOffset);
}

/**
 * 이번 주(월요일 00:00 KST) 시작 UTC Date 를 반환합니다.
 *
 * @returns {Date}
 */
function thisWeekStartKST() {
  const start = todayStartKST();
  const kstOffset = 9 * 60 * 60 * 1000;
  const kstDate = new Date(start.getTime() + kstOffset);
  // getUTCDay(): 0=일, 1=월 ... 6=토
  const dayOfWeek = kstDate.getUTCDay();
  const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  return new Date(start.getTime() - daysFromMonday * 24 * 60 * 60 * 1000);
}

// ---------------------------------------------------------------------------
// 측정 데이터 유효성 검증
// ---------------------------------------------------------------------------

/**
 * 측정 데이터 필드를 검증합니다.
 *
 * @param {object} data - Firestore measurement document data
 * @returns {{ valid: boolean, errors: string[] }}
 */
function validateMeasurement(data) {
  const errors = [];

  if (!data) {
    return { valid: false, errors: ["데이터가 없습니다."] };
  }

  // cafeId
  if (!data.cafeId || typeof data.cafeId !== "string" || data.cafeId.trim() === "") {
    errors.push("cafeId가 유효하지 않습니다.");
  }

  // userId
  if (!data.userId || typeof data.userId !== "string" || data.userId.trim() === "") {
    errors.push("userId가 유효하지 않습니다.");
  }

  // decibelLevel: 0 ~ 200 dB (현실적 범위)
  const db = typeof data.decibelLevel === "number" ? data.decibelLevel : null;
  if (db === null || isNaN(db) || db < 0 || db > 200) {
    errors.push("decibelLevel이 유효하지 않습니다 (0–200 dB).");
  }

  // noiseCategory
  const validCategories = ["quiet", "moderate", "noisy", "loud"];
  if (!data.noiseCategory || !validCategories.includes(data.noiseCategory)) {
    errors.push("noiseCategory가 유효하지 않습니다.");
  }

  // duration: 양수 정수 (초)
  const duration = typeof data.duration === "number" ? data.duration : null;
  if (duration === null || !Number.isInteger(duration) || duration <= 0) {
    errors.push("duration이 유효하지 않습니다 (양수 정수, 초 단위).");
  }

  // timestamp
  if (!data.timestamp) {
    errors.push("timestamp가 없습니다.");
  }

  return { valid: errors.length === 0, errors };
}

// ---------------------------------------------------------------------------
// 배열 청크 유틸 (Firestore 일괄 처리용)
// ---------------------------------------------------------------------------

/**
 * 배열을 지정 크기의 청크로 나눕니다.
 *
 * @param {Array} array
 * @param {number} size
 * @returns {Array[]}
 */
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

module.exports = {
  noiseCategoryFromDb,
  noiseCategoryLabel,
  calculateLevel,
  levelToKey,
  levelLabel,
  calculatePointsForMeasurement,
  calculatePoints,
  formatKoreanDate,
  todayStartKST,
  thisWeekStartKST,
  validateMeasurement,
  chunkArray,
};
