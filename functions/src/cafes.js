/**
 * src/cafes.js
 * 카페 관련 Cloud Functions
 *
 * Functions:
 *   - onMeasurementCreated  : Firestore onCreate 트리거 → 카페 집계 통계 업데이트
 *   - updateCafeHourlyStats : 매일 새벽 3시 KST (18:00 UTC) 스케줄 실행 → 시간대별 소음 재계산
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { noiseCategoryFromDb } = require("./utils");
const logger = require("firebase-functions/logger");

// ---------------------------------------------------------------------------
// onMeasurementCreated
// ---------------------------------------------------------------------------

/**
 * 새 측정 문서가 생성될 때 실행됩니다.
 *
 * 처리 내용:
 *   1. 카페 문서의 averageNoiseLevel, totalMeasurements, noiseCategory 를 점진적 평균으로 갱신
 *   2. recentMeasurements 배열에 새 항목 추가 (최대 5개 유지)
 *   3. hourlyNoise 맵의 해당 시간 슬롯 점진적 평균 업데이트
 *
 * 트랜잭션으로 원자적 처리합니다.
 */
const onMeasurementCreated = onDocumentCreated(
  "measurements/{measurementId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("onMeasurementCreated: 스냅샷이 없습니다.");
      return;
    }

    const measurementId = event.params.measurementId;
    const data = snap.data();

    // 필수 필드 확인
    const { cafeId, decibelLevel, noiseCategory, timestamp } = data;
    if (!cafeId || typeof decibelLevel !== "number") {
      logger.error("onMeasurementCreated: 필수 필드 누락", { measurementId, data });
      return;
    }

    const db = getFirestore();
    const cafeRef = db.collection("cafes").doc(cafeId);

    // 측정 시각에서 KST 시간(0–23)을 추출
    const measurementDate =
      timestamp instanceof Timestamp ? timestamp.toDate() : new Date(timestamp);
    const kstHour = (measurementDate.getUTCHours() + 9) % 24;
    const hourKey = String(kstHour); // "0" ~ "23"

    try {
      await db.runTransaction(async (transaction) => {
        const cafeSnap = await transaction.get(cafeRef);

        if (!cafeSnap.exists) {
          logger.warn(`onMeasurementCreated: 카페 문서 없음 (cafeId=${cafeId})`);
          return;
        }

        const cafeData = cafeSnap.data();

        // ── 1. 점진적 평균 계산 ──────────────────────────────────────────────
        const currentTotal = (cafeData.totalMeasurements ?? 0);
        const currentAvg = (cafeData.averageNoiseLevel ?? 0);

        const newTotal = currentTotal + 1;
        // newAvg = (oldAvg * n + newVal) / (n + 1)
        const newAvg = (currentAvg * currentTotal + decibelLevel) / newTotal;
        const newCategory = noiseCategoryFromDb(newAvg);

        // ── 2. recentMeasurements 배열 (최신 5개) ──────────────────────────
        const existing = Array.isArray(cafeData.recentMeasurements)
          ? cafeData.recentMeasurements
          : [];

        const newEntry = {
          measurementId,
          decibelLevel,
          noiseCategory,
          timestamp: timestamp instanceof Timestamp
            ? timestamp
            : Timestamp.fromDate(measurementDate),
        };

        // 앞에 삽입하고 5개 초과분 제거
        const updatedRecent = [newEntry, ...existing].slice(0, 5);

        // ── 3. hourlyNoise 업데이트 ────────────────────────────────────────
        // hourlyNoise 구조: { "0": { avg: number, count: number }, ... }
        const hourlyNoise = cafeData.hourlyNoise
          ? { ...cafeData.hourlyNoise }
          : {};

        const hourSlot = hourlyNoise[hourKey] ?? { avg: 0, count: 0 };
        const hCount = hourSlot.count ?? 0;
        const hAvg = hourSlot.avg ?? 0;
        const newHCount = hCount + 1;
        const newHAvg = (hAvg * hCount + decibelLevel) / newHCount;

        hourlyNoise[hourKey] = { avg: newHAvg, count: newHCount };

        // ── 4. 트랜잭션 쓰기 ──────────────────────────────────────────────
        transaction.update(cafeRef, {
          totalMeasurements: newTotal,
          averageNoiseLevel: newAvg,
          noiseCategory: newCategory,
          recentMeasurements: updatedRecent,
          hourlyNoise,
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      logger.info(
        `onMeasurementCreated: 카페 통계 업데이트 완료 (cafeId=${cafeId}, measurementId=${measurementId})`,
      );
    } catch (err) {
      logger.error("onMeasurementCreated: 트랜잭션 실패", { cafeId, measurementId, err });
      throw err; // Cloud Functions 재시도를 위해 에러 전파
    }
  },
);

// ---------------------------------------------------------------------------
// updateCafeHourlyStats
// ---------------------------------------------------------------------------

/**
 * 매일 새벽 3시 KST (= 18:00 UTC) 에 실행됩니다.
 *
 * 최근 30일간의 측정 데이터를 기준으로 모든 카페의
 * hourlyNoise 맵(시간대별 평균 dB)을 완전 재계산합니다.
 *
 * hourlyNoise 구조:
 *   {
 *     "0": { avg: 45.3, count: 12 },
 *     "1": { avg: 40.1, count:  5 },
 *     ...
 *     "23": { avg: 55.0, count: 20 }
 *   }
 */
const updateCafeHourlyStats = onSchedule(
  {
    schedule: "0 18 * * *", // 매일 18:00 UTC = 03:00 KST
    timeZone: "Asia/Seoul",
  },
  async () => {
    const db = getFirestore();

    // 최근 30일 기준 타임스탬프
    const since = new Date();
    since.setDate(since.getDate() - 30);
    const sinceTimestamp = Timestamp.fromDate(since);

    logger.info("updateCafeHourlyStats: 시작", { since: since.toISOString() });

    try {
      // 1. 모든 카페 ID 조회
      const cafesSnap = await db.collection("cafes").select().get();
      if (cafesSnap.empty) {
        logger.info("updateCafeHourlyStats: 카페 없음. 종료.");
        return;
      }

      const cafeIds = cafesSnap.docs.map((d) => d.id);
      logger.info(`updateCafeHourlyStats: 카페 ${cafeIds.length}개 처리 시작`);

      // 2. 카페별 hourlyNoise 재계산
      // Firestore in 쿼리는 최대 30개이므로 청크 처리
      const CHUNK_SIZE = 30;
      for (let i = 0; i < cafeIds.length; i += CHUNK_SIZE) {
        const chunk = cafeIds.slice(i, i + CHUNK_SIZE);

        const measurementsSnap = await db
          .collection("measurements")
          .where("cafeId", "in", chunk)
          .where("timestamp", ">=", sinceTimestamp)
          .get();

        // cafeId별로 시간대 버킷 집계
        const cafeHourBuckets = {}; // { cafeId: { "0": [db1, db2, ...], ... } }

        for (const doc of measurementsSnap.docs) {
          const d = doc.data();
          const { cafeId, decibelLevel, timestamp: ts } = d;

          if (!cafeId || typeof decibelLevel !== "number") continue;

          const date = ts instanceof Timestamp ? ts.toDate() : new Date(ts);
          const hour = String((date.getUTCHours() + 9) % 24);

          if (!cafeHourBuckets[cafeId]) cafeHourBuckets[cafeId] = {};
          if (!cafeHourBuckets[cafeId][hour]) cafeHourBuckets[cafeId][hour] = [];
          cafeHourBuckets[cafeId][hour].push(decibelLevel);
        }

        // 3. 각 카페 문서 batch 업데이트
        const batch = db.batch();

        for (const cafeId of chunk) {
          const buckets = cafeHourBuckets[cafeId] ?? {};
          const hourlyNoise = {};

          for (let h = 0; h < 24; h++) {
            const key = String(h);
            const readings = buckets[key] ?? [];
            if (readings.length === 0) continue;
            const avg = readings.reduce((sum, v) => sum + v, 0) / readings.length;
            hourlyNoise[key] = { avg: Math.round(avg * 10) / 10, count: readings.length };
          }

          if (Object.keys(hourlyNoise).length > 0) {
            const ref = db.collection("cafes").doc(cafeId);
            batch.update(ref, {
              hourlyNoise,
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
        }

        await batch.commit();
        logger.info(`updateCafeHourlyStats: chunk ${i / CHUNK_SIZE + 1} 완료`);
      }

      logger.info("updateCafeHourlyStats: 모든 카페 hourlyNoise 업데이트 완료");
    } catch (err) {
      logger.error("updateCafeHourlyStats: 오류 발생", { err });
      throw err;
    }
  },
);

module.exports = { onMeasurementCreated, updateCafeHourlyStats };
