/**
 * index.js
 * CafeOndo Firebase Cloud Functions – 메인 진입점
 *
 * 모든 Cloud Functions 를 한 곳에서 내보냅니다.
 * Firebase Admin SDK 는 이 파일에서 단 한 번 초기화합니다.
 *
 * 배포된 Functions 목록:
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ cafes                                                                    │
 * │   onMeasurementCreated     – Firestore onCreate: measurements/{id}      │
 * │   updateCafeHourlyStats    – Schedule: 매일 03:00 KST                   │
 * │                                                                          │
 * │ rankings                                                                 │
 * │   calculateWeeklyRankings  – Schedule: 매주 월 06:00 KST                │
 * │   updateUserRankOnMeasurement – Firestore onCreate: measurements/{id}   │
 * │                                                                          │
 * │ notifications                                                            │
 * │   sendMeasurementReminder        – Schedule: 매일 12:00 KST             │
 * │   sendWeeklyRankingNotification  – Schedule: 매주 월 07:00 KST          │
 * │   sendLevelUpNotification        – HTTPS Callable                       │
 * │                                                                          │
 * │ admin                                                                    │
 * │   seedInitialCafes         – HTTPS Callable (관리자 전용)                │
 * │   cleanupOldMeasurements   – Schedule: 매월 1일 04:00 KST               │
 * └──────────────────────────────────────────────────────────────────────────┘
 */

const { initializeApp } = require("firebase-admin/app");

// Firebase Admin SDK 초기화 (Cloud Functions 환경에서는 자격증명 자동 감지)
initializeApp();

// ---------------------------------------------------------------------------
// 각 모듈에서 Functions 임포트
// ---------------------------------------------------------------------------

const { onMeasurementCreated, updateCafeHourlyStats } = require("./src/cafes");
const { calculateWeeklyRankings, updateUserRankOnMeasurement } = require("./src/rankings");
const {
  sendMeasurementReminder,
  sendWeeklyRankingNotification,
  sendLevelUpNotification,
} = require("./src/notifications");
const { seedInitialCafes, cleanupOldMeasurements } = require("./src/admin");

// ---------------------------------------------------------------------------
// Named exports (Firebase CLI 가 함수 이름으로 인식)
// ---------------------------------------------------------------------------

module.exports = {
  // ── 카페 ─────────────────────────────────────────────────────────────────
  onMeasurementCreated,
  updateCafeHourlyStats,

  // ── 랭킹 ─────────────────────────────────────────────────────────────────
  calculateWeeklyRankings,
  updateUserRankOnMeasurement,

  // ── 알림 ─────────────────────────────────────────────────────────────────
  sendMeasurementReminder,
  sendWeeklyRankingNotification,
  sendLevelUpNotification,

  // ── 관리자 ───────────────────────────────────────────────────────────────
  seedInitialCafes,
  cleanupOldMeasurements,
};
