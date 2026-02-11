/**
 * GitWall - Cloud Scheduler Function
 * Triggers a silent push notification to all subscribed devices.
 */

const logger = require("firebase-functions/logger");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const UPDATE_TOPIC = process.env.UPDATE_TOPIC || "daily-updates";
const SCHEDULE = process.env.UPDATE_SCHEDULE || "every 60 minutes";
exports.triggerDailyUpdateV2 = onSchedule(
    { schedule: SCHEDULE, timeZone: "UTC" },
    async () => {
        logger.info("Periodic update trigger started (v2)");

        const message = {
            data: {
                type: "refresh",
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: "normal",
                ttl: 15 * 60 * 1000,
            },
            topic: UPDATE_TOPIC,
        };

        let attempts = 0;
        const maxAttempts = 3;
        let lastError;

        while (attempts < maxAttempts) {
            try {
                const response = await admin.messaging().send(message);
                logger.info("Periodic update push sent (v2)", {
                    attempt: attempts + 1,
                    response,
                });
                return;
            } catch (error) {
                attempts++;
                lastError = error;
                logger.warn("Periodic update push attempt failed (v2)", {
                    attempt: attempts,
                    error: String(error),
                });
                if (attempts < maxAttempts) {
                    const baseDelayMs = 500;
                    const backoffMs = baseDelayMs * Math.pow(2, attempts - 1);
                    const jitterMs = Math.floor(Math.random() * 250);
                    await new Promise((resolve) => setTimeout(resolve, backoffMs + jitterMs));
                }
            }
        }

        logger.error("Periodic update push failed after retries (v2)", {
            error: String(lastError),
        });
    },
);
