/**
 * src/admin.js
 * 관리자 유틸리티 Cloud Functions
 *
 * Functions:
 *   - seedInitialCafes        : HTTPS Callable (관리자 전용) – 서울 인기 카페 20개 시딩
 *   - cleanupOldMeasurements  : 매월 1일 04:00 KST (전월 말일 19:00 UTC) – 1년 초과 측정 삭제
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { chunkArray } = require("./utils");
const logger = require("firebase-functions/logger");

// ---------------------------------------------------------------------------
// 서울 인기 카페 시드 데이터 (20개)
// ---------------------------------------------------------------------------

const SEED_CAFES = [
  // ── 강남 ─────────────────────────────────────────────────────────────────
  {
    name: "블루보틀 커피 삼청점",
    address: "서울특별시 강남구 도산대로 9길 12",
    latitude: 37.5219,
    longitude: 127.0235,
    tags: ["강남", "브랜드카페", "조용한"],
  },
  {
    name: "스타벅스 강남대로점",
    address: "서울특별시 강남구 강남대로 390",
    latitude: 37.4980,
    longitude: 127.0276,
    tags: ["강남", "브랜드카페", "넓은"],
  },
  {
    name: "폴바셋 논현점",
    address: "서울특별시 강남구 논현로 508",
    latitude: 37.5103,
    longitude: 127.0385,
    tags: ["강남", "브랜드카페"],
  },
  {
    name: "커피빈 강남역점",
    address: "서울특별시 강남구 강남대로 358",
    latitude: 37.4967,
    longitude: 127.0285,
    tags: ["강남", "브랜드카페"],
  },
  // ── 홍대 ─────────────────────────────────────────────────────────────────
  {
    name: "앤트러사이트 홍대점",
    address: "서울특별시 마포구 와우산로 21길 19-11",
    latitude: 37.5515,
    longitude: 126.9215,
    tags: ["홍대", "인디카페", "조용한", "감성"],
  },
  {
    name: "테일러커피 홍대점",
    address: "서울특별시 마포구 어울마당로 68",
    latitude: 37.5534,
    longitude: 126.9229,
    tags: ["홍대", "스페셜티"],
  },
  {
    name: "어반스페이스 홍대",
    address: "서울특별시 마포구 홍익로5길 20",
    latitude: 37.5541,
    longitude: 126.9238,
    tags: ["홍대", "작업하기좋은"],
  },
  {
    name: "히든트랙 홍대",
    address: "서울특별시 마포구 양화로 188",
    latitude: 37.5526,
    longitude: 126.9180,
    tags: ["홍대", "인디카페"],
  },
  // ── 이태원 ───────────────────────────────────────────────────────────────
  {
    name: "느린마을 양조장 이태원",
    address: "서울특별시 용산구 이태원로 179",
    latitude: 37.5341,
    longitude: 126.9949,
    tags: ["이태원", "복합문화공간"],
  },
  {
    name: "모노 이태원",
    address: "서울특별시 용산구 이태원동 130-14",
    latitude: 37.5345,
    longitude: 126.9937,
    tags: ["이태원", "조용한", "브런치"],
  },
  {
    name: "그라운드샷 이태원",
    address: "서울특별시 용산구 보광로 111",
    latitude: 37.5349,
    longitude: 126.9968,
    tags: ["이태원", "스페셜티"],
  },
  // ── 성수 ─────────────────────────────────────────────────────────────────
  {
    name: "대림창고 갤러리",
    address: "서울특별시 성동구 성수이로 78",
    latitude: 37.5445,
    longitude: 127.0561,
    tags: ["성수", "갤러리카페", "넓은", "감성"],
  },
  {
    name: "어니언 성수점",
    address: "서울특별시 성동구 아차산로 9길 8",
    latitude: 37.5437,
    longitude: 127.0560,
    tags: ["성수", "인기", "베이커리"],
  },
  {
    name: "자바커피 성수",
    address: "서울특별시 성동구 성수일로 9길 36",
    latitude: 37.5421,
    longitude: 127.0577,
    tags: ["성수", "스페셜티", "작업하기좋은"],
  },
  {
    name: "클로버 성수",
    address: "서울특별시 성동구 왕십리로 115",
    latitude: 37.5461,
    longitude: 127.0495,
    tags: ["성수", "조용한"],
  },
  // ── 연남동 ───────────────────────────────────────────────────────────────
  {
    name: "연남방앗간",
    address: "서울특별시 마포구 연남로 27",
    latitude: 37.5593,
    longitude: 126.9236,
    tags: ["연남동", "인디카페", "조용한", "감성"],
  },
  {
    name: "카페 경춘선",
    address: "서울특별시 마포구 동교로 240",
    latitude: 37.5591,
    longitude: 126.9228,
    tags: ["연남동", "넓은"],
  },
  {
    name: "로우키 커피 연남",
    address: "서울특별시 마포구 연남로 1길 36",
    latitude: 37.5601,
    longitude: 126.9241,
    tags: ["연남동", "스페셜티", "작업하기좋은"],
  },
  {
    name: "노머드 연남점",
    address: "서울특별시 마포구 동교로 46길 14",
    latitude: 37.5598,
    longitude: 126.9219,
    tags: ["연남동", "브런치"],
  },
  {
    name: "프릳츠 커피 컴퍼니",
    address: "서울특별시 마포구 도화길 29-29",
    latitude: 37.5465,
    longitude: 126.9421,
    tags: ["마포", "스페셜티", "로스터리", "인기"],
  },
];

// ---------------------------------------------------------------------------
// seedInitialCafes (Callable — 관리자 전용)
// ---------------------------------------------------------------------------

/**
 * 서울 인기 카페 20개의 초기 데이터를 Firestore 에 시딩합니다.
 *
 * - Firebase Auth 의 Custom Claim `admin: true` 가 있는 사용자만 호출 가능합니다.
 * - 이미 동일 이름의 카페가 존재하면 건너뜁니다.
 * - 반환값: { created: number, skipped: number, cafes: string[] }
 */
const seedInitialCafes = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const { auth } = request;

    // 1. 인증 확인
    if (!auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    // 2. 관리자 권한 확인 (Custom Claim)
    let userRecord;
    try {
      userRecord = await getAuth().getUser(auth.uid);
    } catch {
      throw new HttpsError("not-found", "사용자를 찾을 수 없습니다.");
    }

    const isAdmin = userRecord.customClaims?.admin === true;
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "관리자만 시드 데이터를 생성할 수 있습니다.");
    }

    const db = getFirestore();
    logger.info(`seedInitialCafes: 시작 (uid=${auth.uid})`);

    let created = 0;
    let skipped = 0;
    const createdNames = [];

    try {
      // 기존 카페 이름 목록 조회 (중복 방지)
      const existingSnap = await db.collection("cafes").select("name").get();
      const existingNames = new Set(existingSnap.docs.map((d) => d.data().name));

      // Firestore batch: 최대 500 writes, 20개라 단일 배치로 충분
      const batch = db.batch();

      for (const cafe of SEED_CAFES) {
        if (existingNames.has(cafe.name)) {
          skipped++;
          continue;
        }

        const ref = db.collection("cafes").doc(); // 자동 ID
        batch.set(ref, {
          name: cafe.name,
          address: cafe.address,
          latitude: cafe.latitude,
          longitude: cafe.longitude,
          averageNoiseLevel: 0.0,
          noiseCategory: "moderate",
          totalMeasurements: 0,
          recentMeasurements: [],
          hourlyNoise: {},
          photos: [],
          rating: 0.0,
          tags: cafe.tags ?? [],
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        created++;
        createdNames.push(cafe.name);
      }

      if (created > 0) {
        await batch.commit();
      }

      logger.info(`seedInitialCafes: 완료 (생성=${created}, 스킵=${skipped})`);
      return { created, skipped, cafes: createdNames };
    } catch (err) {
      logger.error("seedInitialCafes: 오류 발생", { err });
      throw new HttpsError("internal", "카페 시드 데이터 생성 중 오류가 발생했습니다.");
    }
  },
);

// ---------------------------------------------------------------------------
// cleanupOldMeasurements (Scheduled)
// ---------------------------------------------------------------------------

/**
 * 매월 1일 04:00 KST (전달 말일 19:00 UTC) 에 실행됩니다.
 *
 * 1년(365일)이 지난 측정 문서를 일괄 삭제하고 결과를 로그에 기록합니다.
 * Firestore 단건 삭제는 배치(500건)로 나누어 처리합니다.
 */
const cleanupOldMeasurements = onSchedule(
  {
    schedule: "0 4 1 * *", // 매월 1일 04:00 KST (timeZone: Asia/Seoul 기준)
    timeZone: "Asia/Seoul"
  },
  async () => {
    const db = getFirestore();

    const oneYearAgo = new Date();
    oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
    const cutoffTs = Timestamp.fromDate(oneYearAgo);

    logger.info("cleanupOldMeasurements: 시작", { cutoff: oneYearAgo.toISOString() });

    let totalDeleted = 0;
    let batchCount = 0;

    try {
      // Firestore 는 한 번에 최대 500건 삭제 → 루프로 처리
      while (true) {
        const snapshot = await db
          .collection("measurements")
          .where("timestamp", "<", cutoffTs)
          .limit(400) // 안전 마진 (400건씩)
          .get();

        if (snapshot.empty) break;

        // chunkArray 로 배치 분할 (혹시 400 > 500 방지)
        const chunks = chunkArray(snapshot.docs, 400);

        for (const chunk of chunks) {
          const batch = db.batch();
          for (const doc of chunk) {
            batch.delete(doc.ref);
          }
          await batch.commit();
          totalDeleted += chunk.length;
          batchCount++;
        }

        logger.info(`cleanupOldMeasurements: ${totalDeleted}건 삭제 완료 (배치 ${batchCount})`);

        // 더 이상 삭제할 문서 없으면 종료
        if (snapshot.size < 400) break;
      }

      logger.info("cleanupOldMeasurements: 완료", {
        totalDeleted,
        batchCount,
        cutoff: oneYearAgo.toISOString(),
      });
    } catch (err) {
      logger.error("cleanupOldMeasurements: 오류 발생", { totalDeleted, err });
      throw err;
    }
  },
);

module.exports = { seedInitialCafes, cleanupOldMeasurements };
