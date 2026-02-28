/**
 * src/notifications.js
 * 푸시 알림 관련 Cloud Functions
 *
 * Functions:
 *   - sendMeasurementReminder       : 매일 12:00 KST (03:00 UTC) – 3일 이상 미측정 사용자 리마인더
 *   - sendWeeklyRankingNotification : 매주 월요일 07:00 KST (일요일 22:00 UTC) – 주간 랭킹 알림
 *   - sendLevelUpNotification       : Callable – 레벨업 축하 알림
 *
 * Helper:
 *   - sendNotificationToUser(uid, title, body, data) – FCM 토큰 조회 후 단건 발송
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { levelLabel } = require("./utils");
const logger = require("firebase-functions/logger");

// ---------------------------------------------------------------------------
// Helper: sendNotificationToUser
// ---------------------------------------------------------------------------

/**
 * 특정 사용자에게 FCM 푸시 알림을 발송합니다.
 *
 * Firestore 'users/{uid}' 문서의 fcmToken 필드를 사용합니다.
 * 토큰이 없거나 비활성화된 경우 조용히 넘어갑니다.
 *
 * @param {string} uid           - Firebase Auth UID
 * @param {string} title         - 알림 제목
 * @param {string} body          - 알림 본문
 * @param {Object} [extraData]   - FCM data payload 추가 필드
 * @returns {Promise<boolean>}   - 발송 성공 여부
 */
async function sendNotificationToUser(uid, title, body, extraData = {}) {
  const db = getFirestore();

  try {
    const userSnap = await db.collection("users").doc(uid).get();
    if (!userSnap.exists) {
      logger.warn(`sendNotificationToUser: 사용자 문서 없음 (uid=${uid})`);
      return false;
    }

    const userData = userSnap.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      logger.info(`sendNotificationToUser: FCM 토큰 없음 (uid=${uid})`);
      return false;
    }

    // 알림 비활성화 여부 확인 (notificationsEnabled 필드, 없으면 기본 true)
    if (userData.notificationsEnabled === false) {
      logger.info(`sendNotificationToUser: 알림 비활성화 (uid=${uid})`);
      return false;
    }

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        ...extraData,
        // 모든 data 값은 문자열이어야 합니다
        sentAt: new Date().toISOString(),
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      android: {
        notification: {
          sound: "default",
          channelId: "cafeondo_default",
        },
      },
    };

    await getMessaging().send(message);
    logger.info(`sendNotificationToUser: 발송 성공 (uid=${uid})`);
    return true;
  } catch (err) {
    // 토큰 만료/무효 시 조용히 넘어감 (재시도 방지)
    if (
      err.code === "messaging/registration-token-not-registered" ||
      err.code === "messaging/invalid-registration-token"
    ) {
      logger.warn(`sendNotificationToUser: 토큰 무효 (uid=${uid}). FCM 토큰 삭제.`);
      // 만료된 토큰 정리
      await getFirestore()
        .collection("users")
        .doc(uid)
        .update({ fcmToken: null })
        .catch(() => {});
      return false;
    }
    logger.error(`sendNotificationToUser: 발송 실패 (uid=${uid})`, { err });
    return false;
  }
}

// ---------------------------------------------------------------------------
// sendMeasurementReminder
// ---------------------------------------------------------------------------

/**
 * 매일 12:00 KST (= 03:00 UTC) 에 실행됩니다.
 *
 * 최근 3일 이상 측정을 하지 않은 사용자에게 리마인더 알림을 발송합니다.
 * - 조건: lastMeasurementAt < (now - 3days) 이고 notificationsEnabled != false
 */
const sendMeasurementReminder = onSchedule(
  {
    schedule: "0 3 * * *", // 매일 03:00 UTC = 12:00 KST
    timeZone: "Asia/Seoul",
  },
  async () => {
    const db = getFirestore();

    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    const thresholdTs = Timestamp.fromDate(threeDaysAgo);

    logger.info("sendMeasurementReminder: 시작", { threshold: threeDaysAgo.toISOString() });

    try {
      // lastMeasurementAt 이 3일 전보다 이전인 사용자 조회
      // (lastMeasurementAt 필드가 없는 신규 사용자도 포함하기 위해 두 쿼리 실행)
      const [staleSnap, neverSnap] = await Promise.all([
        db
          .collection("users")
          .where("lastMeasurementAt", "<", thresholdTs)
          .where("fcmToken", "!=", null)
          .get(),
        db
          .collection("users")
          .where("fcmToken", "!=", null)
          .where("totalMeasurements", "==", 0)
          .get(),
      ]);

      // 중복 제거
      const targetUsers = new Map();
      for (const doc of [...staleSnap.docs, ...neverSnap.docs]) {
        targetUsers.set(doc.id, doc.data());
      }

      logger.info(`sendMeasurementReminder: 대상 사용자 ${targetUsers.size}명`);

      let successCount = 0;
      const sendPromises = [];

      for (const [uid, userData] of targetUsers.entries()) {
        // 알림 비활성화 사용자 제외
        if (userData.notificationsEnabled === false) continue;

        sendPromises.push(
          sendNotificationToUser(
            uid,
            "카페온도 ☕",
            "오늘 카페에서 소음을 측정해보세요! ☕",
            { type: "measurement_reminder" },
          ).then((sent) => { if (sent) successCount++; }),
        );
      }

      await Promise.allSettled(sendPromises);

      logger.info(`sendMeasurementReminder: 완료 (발송 성공 ${successCount}명)`);
    } catch (err) {
      logger.error("sendMeasurementReminder: 오류 발생", { err });
      throw err;
    }
  },
);

// ---------------------------------------------------------------------------
// sendWeeklyRankingNotification
// ---------------------------------------------------------------------------

/**
 * 매주 월요일 07:00 KST (= 일요일 22:00 UTC) 에 실행됩니다.
 *
 * 알림 수신 동의한 모든 사용자에게 주간 랭킹 업데이트 알림을 멀티캐스트로 발송합니다.
 */
const sendWeeklyRankingNotification = onSchedule(
  {
    schedule: "0 22 * * 0", // 매주 일요일 22:00 UTC = 월요일 07:00 KST
    timeZone: "Asia/Seoul",
  },
  async () => {
    const db = getFirestore();

    logger.info("sendWeeklyRankingNotification: 시작");

    try {
      // FCM 토큰을 보유한 사용자 전체 조회
      const usersSnap = await db
        .collection("users")
        .where("fcmToken", "!=", null)
        .get();

      const tokens = [];
      for (const doc of usersSnap.docs) {
        const d = doc.data();
        if (d.notificationsEnabled !== false && d.fcmToken) {
          tokens.push(d.fcmToken);
        }
      }

      if (tokens.length === 0) {
        logger.info("sendWeeklyRankingNotification: 발송 대상 없음");
        return;
      }

      logger.info(`sendWeeklyRankingNotification: ${tokens.length}개 토큰에 발송`);

      // FCM 멀티캐스트는 최대 500개 토큰 (배치 처리)
      const BATCH_SIZE = 500;
      let totalSuccess = 0;
      let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const tokenBatch = tokens.slice(i, i + BATCH_SIZE);

        const multicastMessage = {
          tokens: tokenBatch,
          notification: {
            title: "카페온도 ☕",
            body: "이번 주 조용한 카페 TOP 20이 업데이트되었어요!",
          },
          data: {
            type: "weekly_ranking",
            sentAt: new Date().toISOString(),
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
          android: {
            notification: { sound: "default", channelId: "cafeondo_default" },
          },
        };

        const response = await getMessaging().sendEachForMulticast(multicastMessage);
        totalSuccess += response.successCount;
        totalFailure += response.failureCount;

        // 실패한 토큰 정리 (만료된 토큰)
        const cleanupPromises = [];
        response.responses.forEach((resp, idx) => {
          if (
            !resp.success &&
            (resp.error?.code === "messaging/registration-token-not-registered" ||
              resp.error?.code === "messaging/invalid-registration-token")
          ) {
            const badToken = tokenBatch[idx];
            // 해당 토큰을 가진 사용자 문서에서 토큰 삭제
            cleanupPromises.push(
              db
                .collection("users")
                .where("fcmToken", "==", badToken)
                .limit(1)
                .get()
                .then((snap) => {
                  if (!snap.empty) {
                    return snap.docs[0].ref.update({ fcmToken: null });
                  }
                })
                .catch(() => {}),
            );
          }
        });

        await Promise.allSettled(cleanupPromises);
      }

      logger.info("sendWeeklyRankingNotification: 완료", {
        totalSuccess,
        totalFailure,
        totalTokens: tokens.length,
      });
    } catch (err) {
      logger.error("sendWeeklyRankingNotification: 오류 발생", { err });
      throw err;
    }
  },
);

// ---------------------------------------------------------------------------
// sendLevelUpNotification (Callable)
// ---------------------------------------------------------------------------

/**
 * 클라이언트에서 호출하는 레벨업 축하 알림 Callable Function.
 *
 * 호출 시 인증된 사용자에게만 동작합니다.
 * 요청 데이터:
 *   { level: number }  — 도달한 새 레벨 (1–5)
 *
 * 처리:
 *   1. 레벨 유효성 검증
 *   2. 해당 사용자에게 FCM 알림 발송
 *   3. pendingLevelUp 플래그 초기화
 */
const sendLevelUpNotification = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const { auth, data } = request;

    // 인증 확인
    if (!auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    const uid = auth.uid;
    const level = data?.level;

    // 레벨 유효성 검증
    if (!level || typeof level !== "number" || level < 1 || level > 5) {
      throw new HttpsError("invalid-argument", "올바른 레벨 값(1–5)을 제공해주세요.");
    }

    const levelKey = ["beginner", "intermediate", "advanced", "expert", "grandmaster"][level - 1];
    const label = levelLabel(levelKey);

    const title = "카페온도 🎉";
    const body = `축하해요! ${label} (레벨 ${level})로 올라갔어요! 🎉`;

    logger.info(`sendLevelUpNotification: uid=${uid}, level=${level}`);

    try {
      const sent = await sendNotificationToUser(uid, title, body, {
        type: "level_up",
        level: String(level),
        levelKey,
      });

      // pendingLevelUp 플래그 초기화
      await getFirestore()
        .collection("users")
        .doc(uid)
        .update({ pendingLevelUp: null })
        .catch(() => {});

      return { success: true, sent };
    } catch (err) {
      logger.error("sendLevelUpNotification: 오류 발생", { uid, level, err });
      throw new HttpsError("internal", "알림 발송 중 오류가 발생했습니다.");
    }
  },
);

module.exports = {
  sendMeasurementReminder,
  sendWeeklyRankingNotification,
  sendLevelUpNotification,
  // 다른 모듈에서 재사용 가능하도록 내보냄
  sendNotificationToUser,
};
