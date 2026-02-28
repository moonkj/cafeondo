/**
 * src/rankings.js
 * 랭킹 관련 Cloud Functions
 *
 * Functions:
 *   - calculateWeeklyRankings       : 매주 월요일 06:00 KST (일요일 21:00 UTC) 스케줄 실행
 *   - updateUserRankOnMeasurement   : 측정 생성 시 사용자 주간 측정 횟수 & 레벨 업데이트
 *
 * Firestore 'rankings' 컬렉션 문서 구조:
 *   quiet_cafes   : 가장 조용한 카페 TOP 20
 *   top_measurers : 이번 주 측정 횟수 TOP 20 사용자
 *   active_cafes  : 이번 주 측정 가장 많은 카페 TOP 20
 *
 * UserLevel 기준:
 *   beginner(0+) / intermediate(10+) / advanced(50+) / expert(200+) / grandmaster(1000+)
 *
 * Points per measurement (flutter user_repository.dart 동일):
 *   beginner=10, intermediate=15, advanced=20, expert=30, grandmaster=50
 *   레벨업 보너스: +50
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  calculateLevel,
  levelToKey,
  calculatePointsForMeasurement,
  thisWeekStartKST,
} = require("./utils");
const logger = require("firebase-functions/logger");

// ---------------------------------------------------------------------------
// calculateWeeklyRankings
// ---------------------------------------------------------------------------

/**
 * 매주 월요일 06:00 KST (일요일 21:00 UTC) 에 실행됩니다.
 *
 * 집계:
 *   1. quiet_cafes    : averageNoiseLevel 기준 가장 조용한 카페 TOP 20
 *   2. top_measurers  : 이번 주 measurements 기준 측정 횟수 TOP 20 사용자
 *   3. active_cafes   : 이번 주 measurements 기준 가장 측정이 많은 카페 TOP 20
 */
const calculateWeeklyRankings = onSchedule(
  {
    schedule: "0 21 * * 0", // 매주 일요일 21:00 UTC = 월요일 06:00 KST
    timeZone: "Asia/Seoul",
  },
  async () => {
    const db = getFirestore();
    const now = new Date();

    // 이번 주 시작 (월요일 00:00 KST)
    const weekStart = thisWeekStartKST();
    // 이번 주 끝 (다음 월요일 00:00 KST – 1ms)
    const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000 - 1);

    const weekStartTs = Timestamp.fromDate(weekStart);

    logger.info("calculateWeeklyRankings: 시작", {
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
    });

    try {
      // ── 1. 가장 조용한 카페 TOP 20 ─────────────────────────────────────
      const quietSnap = await db
        .collection("cafes")
        .where("totalMeasurements", ">", 0)
        .orderBy("totalMeasurements") // 복합 쿼리를 위한 순서 (인덱스 필요시)
        .get();

      // 클라이언트에서 averageNoiseLevel 기준 정렬 (Firestore 단일 컬렉션 집계 한계)
      const cafeItems = quietSnap.docs
        .map((doc) => {
          const d = doc.data();
          return {
            cafeId: doc.id,
            name: d.name ?? "",
            address: d.address ?? "",
            averageNoiseLevel: d.averageNoiseLevel ?? 0,
            noiseCategory: d.noiseCategory ?? "moderate",
            totalMeasurements: d.totalMeasurements ?? 0,
          };
        })
        .sort((a, b) => a.averageNoiseLevel - b.averageNoiseLevel)
        .slice(0, 20);

      // ── 2. 이번 주 측정 데이터 조회 ───────────────────────────────────
      const weeklyMeasurementsSnap = await db
        .collection("measurements")
        .where("timestamp", ">=", weekStartTs)
        .get();

      // userId별 카운트
      const userCountMap = {}; // { userId: count }
      // cafeId별 카운트
      const cafeCountMap = {}; // { cafeId: count }

      for (const doc of weeklyMeasurementsSnap.docs) {
        const d = doc.data();
        const { userId, cafeId } = d;
        if (userId) userCountMap[userId] = (userCountMap[userId] ?? 0) + 1;
        if (cafeId) cafeCountMap[cafeId] = (cafeCountMap[cafeId] ?? 0) + 1;
      }

      // ── 3. 이번 주 측정 횟수 TOP 20 사용자 ───────────────────────────
      const topUserIds = Object.entries(userCountMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 20)
        .map(([id]) => id);

      const userItems = [];
      if (topUserIds.length > 0) {
        // 최대 30개 in 쿼리 제한 내 (20개이므로 안전)
        const usersSnap = await db
          .collection("users")
          .where("__name__", "in", topUserIds)
          .get();

        const userDataMap = {};
        for (const doc of usersSnap.docs) {
          userDataMap[doc.id] = doc.data();
        }

        for (const uid of topUserIds) {
          const u = userDataMap[uid] ?? {};
          userItems.push({
            userId: uid,
            displayName: u.displayName ?? "카페 탐험가",
            photoUrl: u.photoUrl ?? null,
            level: u.level ?? "beginner",
            weeklyMeasurements: userCountMap[uid] ?? 0,
            totalMeasurements: u.totalMeasurements ?? 0,
          });
        }
      }

      // ── 4. 이번 주 가장 활발한 카페 TOP 20 ───────────────────────────
      const topCafeIds = Object.entries(cafeCountMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 20)
        .map(([id]) => id);

      const activeCafeItems = [];
      if (topCafeIds.length > 0) {
        const activeCafesSnap = await db
          .collection("cafes")
          .where("__name__", "in", topCafeIds)
          .get();

        const cafDataMap = {};
        for (const doc of activeCafesSnap.docs) {
          cafDataMap[doc.id] = doc.data();
        }

        for (const cafeId of topCafeIds) {
          const c = cafDataMap[cafeId] ?? {};
          activeCafeItems.push({
            cafeId,
            name: c.name ?? "",
            address: c.address ?? "",
            averageNoiseLevel: c.averageNoiseLevel ?? 0,
            noiseCategory: c.noiseCategory ?? "moderate",
            weeklyMeasurements: cafeCountMap[cafeId] ?? 0,
            totalMeasurements: c.totalMeasurements ?? 0,
          });
        }
        // 주간 측정 횟수 내림차순 정렬
        activeCafeItems.sort((a, b) => b.weeklyMeasurements - a.weeklyMeasurements);
      }

      // ── 5. rankings 컬렉션에 저장 (batch) ─────────────────────────────
      const rankingsRef = db.collection("rankings");
      const batch = db.batch();

      const periodData = {
        start: Timestamp.fromDate(weekStart),
        end: Timestamp.fromDate(weekEnd),
      };

      batch.set(rankingsRef.doc("quiet_cafes"), {
        items: cafeItems,
        updatedAt: FieldValue.serverTimestamp(),
        period: periodData,
      });

      batch.set(rankingsRef.doc("top_measurers"), {
        items: userItems,
        updatedAt: FieldValue.serverTimestamp(),
        period: periodData,
      });

      batch.set(rankingsRef.doc("active_cafes"), {
        items: activeCafeItems,
        updatedAt: FieldValue.serverTimestamp(),
        period: periodData,
      });

      await batch.commit();

      logger.info("calculateWeeklyRankings: 랭킹 업데이트 완료", {
        quietCafes: cafeItems.length,
        topMeasurers: userItems.length,
        activeCafes: activeCafeItems.length,
        completedAt: now.toISOString(),
      });
    } catch (err) {
      logger.error("calculateWeeklyRankings: 오류 발생", { err });
      throw err;
    }
  },
);

// ---------------------------------------------------------------------------
// updateUserRankOnMeasurement
// ---------------------------------------------------------------------------

/**
 * 새 측정 문서가 생성될 때 사용자의 통계를 업데이트합니다.
 *
 * 처리 내용:
 *   1. totalMeasurements 1 증가
 *   2. points 증가 (레벨별 단가 적용)
 *   3. 레벨업 감지 → level 필드 업데이트
 *   4. 레벨업 보너스 포인트 +50 지급
 *   5. weeklyMeasurements 1 증가 (주간 카운터, 매주 초기화는 calculateWeeklyRankings 담당)
 *
 * 레벨업 시 sendLevelUpNotification 을 직접 호출하지 않고
 * 사용자 문서에 pendingLevelUp 플래그를 남겨 클라이언트가 처리하거나
 * notifications.js 의 sendLevelUpNotification callable 을 통해 발송합니다.
 */
const updateUserRankOnMeasurement = onDocumentCreated(
  "measurements/{measurementId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { userId } = data;

    if (!userId) {
      logger.warn("updateUserRankOnMeasurement: userId 없음", { measurementId: event.params.measurementId });
      return;
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(userId);

    // 레벨 임계값 (태스크 명세 기준)
    // 1(0) / 2(10) / 3(30) / 4(70) / 5(150) — 명세 기준 (Flutter 모델과 별개로 적용)
    const LEVEL_THRESHOLDS = [0, 10, 30, 70, 150];
    const LEVEL_UP_BONUS = 50;

    /**
     * totalMeasurements 기준으로 명세 레벨(1–5) 계산
     * @param {number} count
     * @returns {number}
     */
    function specLevel(count) {
      let lv = 1;
      for (let i = 0; i < LEVEL_THRESHOLDS.length; i++) {
        if (count >= LEVEL_THRESHOLDS[i]) lv = i + 1;
      }
      return lv;
    }

    try {
      let leveledUp = false;
      let newLevelNum = 1;

      await db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);

        if (!userSnap.exists) {
          logger.warn(`updateUserRankOnMeasurement: 사용자 문서 없음 (userId=${userId})`);
          return;
        }

        const uData = userSnap.data();
        const currentCount = (uData.totalMeasurements ?? 0);
        const currentPoints = (uData.points ?? 0);
        const currentWeekly = (uData.weeklyMeasurements ?? 0);

        const newCount = currentCount + 1;
        const pointsEarned = calculatePointsForMeasurement(newCount);

        // 레벨 계산 (Flutter 모델 기준 — 전체 레벨 시스템과 일관성 유지)
        const prevLevelNum = calculateLevel(currentCount);
        newLevelNum = calculateLevel(newCount);
        leveledUp = newLevelNum > prevLevelNum;

        const bonusPoints = leveledUp ? LEVEL_UP_BONUS : 0;
        const newPoints = currentPoints + pointsEarned + bonusPoints;
        const newLevelKey = levelToKey(newLevelNum);

        const updates = {
          totalMeasurements: newCount,
          points: newPoints,
          level: newLevelKey,
          weeklyMeasurements: currentWeekly + 1,
          updatedAt: FieldValue.serverTimestamp(),
        };

        // 레벨업 시 클라이언트 알림용 플래그 설정
        if (leveledUp) {
          updates.pendingLevelUp = {
            level: newLevelNum,
            levelKey: newLevelKey,
            notifiedAt: null,
          };
        }

        transaction.update(userRef, updates);
      });

      if (leveledUp) {
        logger.info(
          `updateUserRankOnMeasurement: 레벨업! userId=${userId} → 레벨 ${newLevelNum}`,
        );
      } else {
        logger.info(`updateUserRankOnMeasurement: userId=${userId} 측정 횟수 증가 완료`);
      }
    } catch (err) {
      logger.error("updateUserRankOnMeasurement: 오류 발생", { userId, err });
      throw err;
    }
  },
);

module.exports = { calculateWeeklyRankings, updateUserRankOnMeasurement };
