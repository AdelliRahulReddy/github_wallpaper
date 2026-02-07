/**
 * GitWall - Cloud Scheduler Function
 * Triggers a silent push notification to all subscribed devices.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Schedule: Every 15 minutes
// Timezone: UTC
exports.triggerDailyUpdate = functions.pubsub
    .schedule("every 15 minutes")
    .timeZone("UTC")
    .onRun(async (context) => {
        functions.logger.info("Daily update trigger started");

        // Build message payload (type must match app handler: "refresh" or "daily_refresh")
        const message = {
            data: {
                type: "refresh",
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: "high",
                ttl: 3600 * 1000, // 1 hour
            },
            topic: "daily-updates", // ✅ Correct placement
        };

        let attempts = 0;
        const maxAttempts = 3;
        let lastError;

        while (attempts < maxAttempts) {
            try {
                // Send to 'daily-updates' topic
                const response = await admin.messaging().send(message);
                functions.logger.info("Daily update push sent", {
                    attempt: attempts + 1,
                    response,
                });
                return null;
            } catch (error) {
                attempts++;
                lastError = error;
                functions.logger.warn("Daily update push attempt failed", {
                    attempt: attempts,
                    error: String(error),
                });
                if (attempts < maxAttempts) {
                    // Wait 500ms before retrying
                    await new Promise((resolve) => setTimeout(resolve, 500));
                }
            }
        }

        functions.logger.error("Daily update push failed after retries", {
            error: String(lastError),
        });
        return null;
    });
