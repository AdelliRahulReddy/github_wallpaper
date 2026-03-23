const logger = require("firebase-functions/logger");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const GITHUB_CLIENT_ID = defineSecret("GITHUB_CLIENT_ID");
const GITHUB_CLIENT_SECRET = defineSecret("GITHUB_CLIENT_SECRET");
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const ADMIN_BROADCAST_TOPIC = "all_users_broadcast";
const GEMINI_MODEL = "gemini-2.0-flash-lite";
const GEMINI_GENERATE_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
const QUOTE_RETENTION_DAYS = 7;
const DAILY_QUOTES_COLLECTION = "daily_quotes";
const QUOTE_REQUEST_DELAY_MS = 450;
const QUOTE_REQUEST_MAX_ATTEMPTS = 5;
const QUOTE_MAX_WORDS = 20;
const QUOTE_PROFILE_DIMENSIONS = {
  streak: [
    { key: "0d", label: "0 days" },
    { key: "1_3d", label: "1-3 days" },
    { key: "4_7d", label: "4-7 days" },
    { key: "8_14d", label: "8-14 days" },
    { key: "15_30d", label: "15-30 days" },
    { key: "31_60d", label: "31-60 days" },
    { key: "61_100d", label: "61-100 days" },
    { key: "100pd", label: "100+ days" },
  ],
  tone: [
    { key: "Friendly", label: "Friendly" },
    { key: "Motivational", label: "Motivational" },
    { key: "Roast", label: "Roast" },
  ],
  level: [
    { key: "New", label: "New" },
    { key: "Beginner", label: "Beginner" },
    { key: "Regular", label: "Regular" },
    { key: "Hardcore", label: "Hardcore" },
  ],
  commits: [
    { key: "0c", label: "0" },
    { key: "1_2c", label: "1-2" },
    { key: "3_5c", label: "3-5" },
    { key: "6pc", label: "6+" },
  ],
};
const githubApiHeaders = {
  Accept: "application/vnd.github+json",
  "X-GitHub-Api-Version": "2022-11-28",
};

exports.ping = onRequest((req, res) => {
  logger.info("GitWall functions active");
  res.status(200).send("ok");
});

exports.generateDailyQuotes = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "Asia/Kolkata",
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: [GEMINI_API_KEY],
  },
  async () => {
    const apiKey = GEMINI_API_KEY.value().trim();
    if (!apiKey) {
      logger.error(
        "Daily quote generation skipped: GEMINI_API_KEY is not configured.",
      );
      return;
    }

    const db = getFirestore("default");
    const now = new Date();
    const docId = formatDateKey(now);
    const profiles = buildQuoteProfiles();
    const quotes = {};

    logger.info("Starting daily quote generation", {
      date: docId,
      profiles: profiles.length,
      model: GEMINI_MODEL,
      throttleMs: QUOTE_REQUEST_DELAY_MS,
    });

    for (const [index, profile] of profiles.entries()) {
      if (index > 0) {
        await sleep(QUOTE_REQUEST_DELAY_MS);
      }
      quotes[profile.key] = await generateQuoteForProfile(profile, apiKey);
    }

    await db
      .collection(DAILY_QUOTES_COLLECTION)
      .doc(docId)
      .set(
        {
          ...quotes,
          _meta: {
            profile_count: profiles.length,
            model: GEMINI_MODEL,
            quote_max_words: QUOTE_MAX_WORDS,
          },
          generated_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    await cleanupOldDailyQuotes(db, now);

    logger.info("Daily quote generation completed", {
      date: docId,
      profiles: profiles.length,
    });
  },
);

exports.exchangeGitHubCode = onRequest(
  {
    cors: true,
    secrets: [GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method not allowed" });
      return;
    }

    const body =
      typeof req.body === "object" && req.body !== null ? req.body : {};
    const authorizationCode = `${body.authorizationCode ?? ""}`.trim();
    const codeVerifier = `${body.codeVerifier ?? ""}`.trim();
    const accessTokenFromClient = `${body.accessToken ?? ""}`.trim();
    const redirectUri = `${body.redirectUri ?? ""}`.trim();
    const clientId = GITHUB_CLIENT_ID.value().trim();
    const clientSecret = GITHUB_CLIENT_SECRET.value().trim();

    if (!clientId || !clientSecret) {
      res.status(500).json({
        message: "GitHub OAuth secrets are not configured",
      });
      return;
    }

    if (
      !accessTokenFromClient &&
      (!authorizationCode || !codeVerifier || !redirectUri)
    ) {
      res.status(400).json({
        message:
          "authorizationCode, codeVerifier, and redirectUri are required",
      });
      return;
    }

    try {
      const accessToken =
        accessTokenFromClient ||
        (await exchangeAuthorizationCode({
          authorizationCode,
          codeVerifier,
          redirectUri,
          clientId,
          clientSecret,
        }));
      const session = await buildGitHubSession(accessToken);
      res.status(200).json(session);
    } catch (error) {
      logger.error("GitHub OAuth exchange failed", sanitizeForLogs(error));
      res.status(error.statusCode || 500).json({
        message: error.message || "GitHub OAuth exchange failed",
        details: error.details || null,
      });
    }
  },
);

exports.sendAdminBroadcast = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method not allowed" });
      return;
    }

    let notificationRef = null;

    try {
      const admin = await authenticateAdminRequest(req);
      const body =
        typeof req.body === "object" && req.body !== null ? req.body : {};
      const title = `${body.title ?? ""}`.trim();
      const message = `${body.body ?? ""}`.trim();

      if (!title) {
        res.status(400).json({ message: "title is required" });
        return;
      }

      if (!message) {
        res.status(400).json({ message: "body is required" });
        return;
      }

      if (title.length > 80) {
        res
          .status(400)
          .json({ message: "title must be 80 characters or fewer" });
        return;
      }

      if (message.length > 240) {
        res
          .status(400)
          .json({ message: "body must be 240 characters or fewer" });
        return;
      }

      const db = getFirestore("default");
      notificationRef = db.collection("admin_notifications").doc();
      await notificationRef.set({
        title,
        body: message,
        topic: ADMIN_BROADCAST_TOPIC,
        status: "pending",
        requested_by: admin.email,
        requested_by_role: admin.role,
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        accepted_at: null,
        failed_at: null,
        error_message: null,
        message_id: null,
        received_count: 0,
        displayed_count: 0,
        opened_count: 0,
        last_received_at: null,
        last_displayed_at: null,
        last_opened_at: null,
      });

      const response = await getMessaging().send({
        topic: ADMIN_BROADCAST_TOPIC,
        notification: {
          title,
          body: message,
        },
        data: {
          type: "admin_broadcast",
          broadcast_id: notificationRef.id,
          title,
          body: message,
          sent_by: admin.email,
          sent_at: new Date().toISOString(),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "admin_broadcast_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      await notificationRef.set(
        {
          status: "accepted",
          message_id: response,
          accepted_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          error_message: null,
        },
        { merge: true },
      );

      logger.info("Admin broadcast accepted by FCM", {
        by: admin.email,
        notificationId: notificationRef.id,
        messageId: response,
        title,
      });

      res.status(200).json({
        ok: true,
        status: "accepted",
        notificationId: notificationRef.id,
        messageId: response,
        sentBy: admin.email,
      });
    } catch (error) {
      if (notificationRef) {
        await notificationRef
          .set(
            {
              status: "failed",
              failed_at: FieldValue.serverTimestamp(),
              updated_at: FieldValue.serverTimestamp(),
              error_message: error.message || "Admin broadcast failed",
            },
            { merge: true },
          )
          .catch((writeError) => {
            logger.error(
              "Failed to persist admin broadcast failure",
              sanitizeForLogs(writeError),
            );
          });
      }

      logger.error("Admin broadcast failed", sanitizeForLogs(error));
      res.status(error.statusCode || 500).json({
        message: error.message || "Admin broadcast failed",
        details: error.details || null,
        notificationId: notificationRef?.id || null,
      });
    }
  },
);

exports.ackAdminBroadcastEvent = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method not allowed" });
      return;
    }

    try {
      const session = await authenticateAppRequest(req);
      const body =
        typeof req.body === "object" && req.body !== null ? req.body : {};
      const broadcastId = `${body.broadcastId ?? ""}`.trim();
      const event = `${body.event ?? ""}`.trim().toLowerCase();
      const messageId = `${body.messageId ?? ""}`.trim();
      const platform = `${body.platform ?? ""}`.trim().toLowerCase();
      const appVersion = `${body.appVersion ?? ""}`.trim();
      const buildNumber = `${body.buildNumber ?? ""}`.trim();
      const allowedEvents = new Set(["received", "displayed", "opened"]);

      if (!broadcastId) {
        res.status(400).json({ message: "broadcastId is required" });
        return;
      }

      if (!allowedEvents.has(event)) {
        res
          .status(400)
          .json({ message: "event must be received, displayed, or opened" });
        return;
      }

      const db = getFirestore("default");
      const notificationRef = db
        .collection("admin_notifications")
        .doc(broadcastId);
      const eventRef = notificationRef
        .collection("events")
        .doc(buildEventDocumentId(session.uid, event));

      const aggregateField = `${event}_count`;
      const aggregateTimestampField = `last_${event}_at`;

      await db.runTransaction(async (transaction) => {
        const [notificationSnapshot, eventSnapshot] = await Promise.all([
          transaction.get(notificationRef),
          transaction.get(eventRef),
        ]);

        if (!notificationSnapshot.exists) {
          const error = new Error("Broadcast notification was not found.");
          error.statusCode = 404;
          throw error;
        }

        if (eventSnapshot.exists) {
          return;
        }

        transaction.set(eventRef, {
          uid: session.uid,
          email: session.email || null,
          sign_in_provider: session.signInProvider || "unknown",
          platform: platform || "unknown",
          app_version: appVersion || "unknown",
          build_number: buildNumber || "unknown",
          event,
          message_id: messageId || null,
          created_at: FieldValue.serverTimestamp(),
        });
        transaction.set(
          notificationRef,
          {
            [aggregateField]: FieldValue.increment(1),
            [aggregateTimestampField]: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      res.status(200).json({
        ok: true,
        broadcastId,
        event,
      });
    } catch (error) {
      logger.error("Admin broadcast ack failed", sanitizeForLogs(error));
      res.status(error.statusCode || 500).json({
        message: error.message || "Admin broadcast ack failed",
        details: error.details || null,
      });
    }
  },
);

exports.ingestClientLog = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method not allowed" });
      return;
    }

    try {
      const session = await authenticateAppRequest(req);
      const body =
        typeof req.body === "object" && req.body !== null ? req.body : {};
      const type = sanitizeLogText(body.type, 64).toLowerCase();
      const errorMessage = sanitizeLogText(body.error, 4000);
      const stack = sanitizeLogText(body.stack, 16000);
      const username = sanitizeLogText(body.username, 80);
      const platform = sanitizeLogText(body.platform, 32).toLowerCase();
      const appVersion = sanitizeLogText(body.appVersion, 32);
      const buildNumber = sanitizeLogText(body.buildNumber, 32);
      const allowedTypes = new Set([
        "sync_failure",
        "wallpaper_failure",
        "background_job_failure",
        "client_error",
      ]);

      if (!allowedTypes.has(type)) {
        res.status(400).json({ message: "Unsupported log type" });
        return;
      }

      if (!errorMessage) {
        res.status(400).json({ message: "error is required" });
        return;
      }

      const db = getFirestore("default");
      const logPayload = {
        type,
        error: errorMessage,
        stack: stack || null,
        username: username || null,
        uid: session.uid,
        email: session.email || null,
        sign_in_provider: session.signInProvider || "unknown",
        platform: platform || "unknown",
        app_version: appVersion || "unknown",
        build_number: buildNumber || "unknown",
        timestamp: FieldValue.serverTimestamp(),
      };
      await db.collection("logs").add(logPayload);

      const writes = [
        db
          .collection("admin_metrics")
          .doc("summary")
          .set(
            {
              [`${type}_count`]: FieldValue.increment(1),
              latest_log_at: FieldValue.serverTimestamp(),
              updated_at: FieldValue.serverTimestamp(),
            },
            { merge: true },
          ),
      ];

      if (type === "client_error") {
        writes.push(
          db.collection("admin_crash_reports").add({
            ...logPayload,
            source: "client_runtime",
          }),
        );
      }

      await Promise.all(writes);

      res.status(200).json({ ok: true, type });
    } catch (error) {
      logger.error("Client log ingest failed", sanitizeForLogs(error));
      res.status(error.statusCode || 500).json({
        message: error.message || "Client log ingest failed",
        details: error.details || null,
      });
    }
  },
);

exports.redeemCouponCode = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method not allowed" });
      return;
    }

    try {
      const session = await authenticateAppRequest(req);
      const email = `${session.email ?? ""}`.trim().toLowerCase();
      if (!email) {
        res.status(403).json({
          message: "A verified email is required to redeem a coupon.",
        });
        return;
      }

      const code = `${req.body?.code ?? ""}`.trim().toUpperCase();
      if (!code) {
        res.status(400).json({ message: "code is required" });
        return;
      }

      const db = getFirestore("default");
      const userRef = db.collection("users").doc(email);
      const couponRef = db.collection("coupon_codes").doc(code);
      const appConfigRef = db.collection("config").doc("app_config");

      const result = await db.runTransaction(async (transaction) => {
        const [couponSnap, userSnap, appConfigSnap] = await Promise.all([
          transaction.get(couponRef),
          transaction.get(userRef),
          transaction.get(appConfigRef),
        ]);

        if (!couponSnap.exists) {
          const error = new Error("Coupon invalid or already used.");
          error.statusCode = 404;
          throw error;
        }

        const coupon = couponSnap.data() || {};
        if (coupon.enabled === false || coupon.invalidated === true) {
          const error = new Error("Coupon invalid or already used.");
          error.statusCode = 400;
          throw error;
        }
        if (coupon.used_at || coupon.usedByEmail) {
          const error = new Error("Coupon invalid or already used.");
          error.statusCode = 409;
          throw error;
        }

        const appConfig = appConfigSnap.exists
          ? appConfigSnap.data() || {}
          : {};
        const durationDays = Number(
          coupon.duration_days || appConfig.coupon_access_duration_days || 180,
        );
        const now = new Date();
        const expiresAt = new Date(
          now.getTime() + durationDays * 24 * 60 * 60 * 1000,
        );
        const userData = userSnap.exists ? userSnap.data() || {} : {};

        transaction.set(
          userRef,
          {
            email,
            username: userData.username || coupon.username_hint || null,
            plan: "coupon_pro",
            createdAt: userData.createdAt || FieldValue.serverTimestamp(),
            proAccessExpiresAt: expiresAt,
            couponCode: code,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        transaction.set(
          couponRef,
          {
            used_at: FieldValue.serverTimestamp(),
            usedByEmail: email,
            usedByUid: session.uid,
            updated_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        return {
          code,
          durationDays,
          expiresAt: expiresAt.toISOString(),
        };
      });

      res.status(200).json({
        ok: true,
        ...result,
      });
    } catch (error) {
      logger.error("Coupon redeem failed", sanitizeForLogs(error));
      res.status(error.statusCode || 500).json({
        message: error.message || "Coupon redeem failed",
        details: error.details || null,
      });
    }
  },
);

async function exchangeAuthorizationCode({
  authorizationCode,
  codeVerifier,
  redirectUri,
  clientId,
  clientSecret,
}) {
  const response = await fetch("https://github.com/login/oauth/access_token", {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      code: authorizationCode,
      redirect_uri: redirectUri,
      code_verifier: codeVerifier,
    }),
  });

  const payload = await safeJson(response);
  if (!response.ok || !payload.access_token) {
    const error = new Error(
      payload.error_description || "GitHub token exchange failed",
    );
    error.statusCode = response.status;
    error.details = JSON.stringify(payload);
    throw error;
  }

  return `${payload.access_token}`.trim();
}

async function fetchGitHubJson(url, accessToken) {
  const response = await fetch(url, {
    headers: {
      ...githubApiHeaders,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  const payload = await safeJson(response);
  if (!response.ok) {
    const error = new Error(`GitHub request failed (${response.status})`);
    error.statusCode = response.status;
    error.details = JSON.stringify(payload);
    throw error;
  }

  return payload;
}

async function buildGitHubSession(accessToken) {
  const profile = await fetchGitHubJson(
    "https://api.github.com/user",
    accessToken,
  );
  const emails = await fetchGitHubJson(
    "https://api.github.com/user/emails",
    accessToken,
  );

  const username = `${profile.login ?? ""}`.trim();
  if (!username) {
    const error = new Error("GitHub profile is missing login");
    error.statusCode = 502;
    throw error;
  }

  const email = selectVerifiedEmail(profile.email, emails);
  const uid = `github:${profile.id ?? username.toLowerCase()}`;
  const customClaims = {
    github_username: username,
    ...(email ? { github_email: email } : {}),
  };

  const firebaseCustomToken = await getAuth().createCustomToken(
    uid,
    customClaims,
  );
  return {
    accessToken,
    username,
    email,
    firebaseCustomToken,
  };
}

async function authenticateAdminRequest(req) {
  const authHeader = `${req.headers.authorization ?? ""}`.trim();
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    const error = new Error("Missing Firebase bearer token.");
    error.statusCode = 401;
    throw error;
  }

  let decodedToken;
  try {
    decodedToken = await getAuth().verifyIdToken(match[1]);
  } catch (verifyError) {
    const error = new Error("Invalid Firebase admin session.");
    error.statusCode = 401;
    error.details = verifyError?.message || null;
    throw error;
  }

  const email =
    typeof decodedToken.email === "string"
      ? decodedToken.email.trim().toLowerCase()
      : "";
  if (!email) {
    const error = new Error(
      "A verified Google email is required for admin actions.",
    );
    error.statusCode = 403;
    throw error;
  }

  const adminAccess = await assertAuthorizedAdminEmail(email);
  return {
    email,
    role: adminAccess.role,
    uid: decodedToken.uid,
  };
}

async function authenticateAppRequest(req) {
  const authHeader = `${req.headers.authorization ?? ""}`.trim();
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    const error = new Error("Missing Firebase bearer token.");
    error.statusCode = 401;
    throw error;
  }

  let decodedToken;
  try {
    decodedToken = await getAuth().verifyIdToken(match[1]);
  } catch (verifyError) {
    const error = new Error("Invalid Firebase app session.");
    error.statusCode = 401;
    error.details = verifyError?.message || null;
    throw error;
  }

  return {
    uid: decodedToken.uid,
    email: resolveAppEmail(decodedToken),
    signInProvider:
      typeof decodedToken.firebase?.sign_in_provider === "string"
        ? decodedToken.firebase.sign_in_provider
        : null,
  };
}

function resolveAppEmail(decodedToken) {
  const candidates = [
    decodedToken?.email,
    decodedToken?.github_email,
    decodedToken?.githubEmail,
  ];

  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim().toLowerCase();
    }
  }

  return null;
}

async function assertAuthorizedAdminEmail(email) {
  const normalizedEmail =
    typeof email === "string" ? email.trim().toLowerCase() : "";
  if (!normalizedEmail) {
    const error = new Error("A verified email is required for admin access.");
    error.statusCode = 403;
    throw error;
  }

  const snapshot = await getFirestore("default")
    .collection("admins")
    .doc(normalizedEmail)
    .get();
  if (!snapshot.exists || snapshot.data()?.enabled === false) {
    const error = new Error(
      "This account is not currently authorized as a web admin.",
    );
    error.statusCode = 403;
    throw error;
  }

  return {
    role: snapshot.data()?.role ?? "admin",
  };
}

function selectVerifiedEmail(profileEmail, emailsPayload) {
  const emails = Array.isArray(emailsPayload) ? emailsPayload : [];
  const normalizedProfileEmail =
    typeof profileEmail === "string" && profileEmail.trim()
      ? profileEmail.trim().toLowerCase()
      : null;

  const verifiedPrimary = emails.find(
    (entry) =>
      typeof entry?.email === "string" &&
      entry.email.trim() &&
      entry.primary === true &&
      entry.verified === true,
  );
  if (verifiedPrimary) {
    return verifiedPrimary.email.trim().toLowerCase();
  }

  const verifiedMatchingProfile = normalizedProfileEmail
    ? emails.find(
        (entry) =>
          typeof entry?.email === "string" &&
          entry.email.trim().toLowerCase() === normalizedProfileEmail &&
          entry.verified === true,
      )
    : null;
  if (verifiedMatchingProfile) {
    return verifiedMatchingProfile.email.trim().toLowerCase();
  }

  const verifiedAny = emails.find(
    (entry) =>
      typeof entry?.email === "string" &&
      entry.email.trim() &&
      entry.verified === true,
  );
  if (verifiedAny) {
    return verifiedAny.email.trim().toLowerCase();
  }

  return normalizedProfileEmail;
}

async function safeJson(response) {
  try {
    return await response.json();
  } catch (_) {
    return {};
  }
}

function buildEventDocumentId(uid, event) {
  const rawValue = `${uid}_${event}`;
  return rawValue.replace(/\//g, "_");
}

function sanitizeLogText(value, maxLength) {
  const text = `${value ?? ""}`.trim();
  if (!text) {
    return "";
  }
  return text.length > maxLength ? text.slice(0, maxLength) : text;
}

function sanitizeForLogs(error) {
  const message =
    typeof error?.message === "string"
      ? error.message.replace(/Bearer\s+\S+/gi, "Bearer [REDACTED]")
      : "unknown error";
  return {
    message,
    code: error?.code || null,
    details: typeof error?.details === "string" ? error.details : null,
    statusCode: error?.statusCode || null,
    stack:
      typeof error?.stack === "string"
        ? error.stack.split("\n").slice(0, 3).join("\n")
        : null,
  };
}

function buildQuoteProfiles() {
  const profiles = [];

  for (const streak of QUOTE_PROFILE_DIMENSIONS.streak) {
    for (const tone of QUOTE_PROFILE_DIMENSIONS.tone) {
      for (const level of QUOTE_PROFILE_DIMENSIONS.level) {
        for (const commits of QUOTE_PROFILE_DIMENSIONS.commits) {
          profiles.push({
            key: [streak.key, tone.key, level.key, commits.key].join("_"),
            streakKey: streak.key,
            streakLabel: streak.label,
            toneKey: tone.key,
            toneLabel: tone.label,
            levelKey: level.key,
            levelLabel: level.label,
            commitsKey: commits.key,
            commitsLabel: commits.label,
          });
        }
      }
    }
  }

  return profiles;
}

async function generateQuoteForProfile(profile, apiKey) {
  const prompt = [
    `Write one short quote (max ${QUOTE_MAX_WORDS} words) for a developer.`,
    `Streak: ${profile.streakLabel}. Tone: ${profile.toneLabel}. Level: ${profile.levelLabel}. Commits today: ${profile.commitsLabel}.`,
    "Only return the quote text. No quotation marks. No explanation.",
  ].join("\n");

  for (let attempt = 1; attempt <= QUOTE_REQUEST_MAX_ATTEMPTS; attempt += 1) {
    try {
      const response = await fetch(
        `${GEMINI_GENERATE_URL}?key=${encodeURIComponent(apiKey)}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            contents: [
              {
                role: "user",
                parts: [{ text: prompt }],
              },
            ],
            generationConfig: {
              temperature: 0.9,
              maxOutputTokens: 80,
            },
          }),
        },
      );

      const payload = await safeJson(response);
      if (!response.ok) {
        const retryable = response.status === 429 || response.status >= 500;
        if (retryable && attempt < QUOTE_REQUEST_MAX_ATTEMPTS) {
          const waitMs = quoteBackoffMs(attempt, payload);
          logger.warn("Retrying Gemini quote generation", {
            key: profile.key,
            attempt,
            status: response.status,
            waitMs,
          });
          await sleep(waitMs);
          continue;
        }

        throw buildGeminiError(response.status, payload);
      }

      const rawText = extractGeminiText(payload);
      if (rawText) {
        return sanitizeQuoteText(rawText);
      }

      throw new Error("Gemini returned an empty quote response.");
    } catch (error) {
      if (attempt < QUOTE_REQUEST_MAX_ATTEMPTS) {
        const waitMs = quoteBackoffMs(attempt);
        logger.warn("Retrying Gemini quote generation after error", {
          key: profile.key,
          attempt,
          waitMs,
          error: sanitizeForLogs(error),
        });
        await sleep(waitMs);
        continue;
      }

      logger.error("Falling back to deterministic quote", {
        key: profile.key,
        error: sanitizeForLogs(error),
      });
      return deterministicFallbackQuote(profile);
    }
  }

  return deterministicFallbackQuote(profile);
}

function extractGeminiText(payload) {
  const candidates = Array.isArray(payload?.candidates)
    ? payload.candidates
    : [];
  for (const candidate of candidates) {
    const parts = Array.isArray(candidate?.content?.parts)
      ? candidate.content.parts
      : [];
    for (const part of parts) {
      const text = `${part?.text ?? ""}`.trim();
      if (text) {
        return text;
      }
    }
  }
  return "";
}

function sanitizeQuoteText(rawText) {
  const cleaned = `${rawText ?? ""}`
    .replace(/\s+/g, " ")
    .replace(/^["'`]+|["'`]+$/g, "")
    .trim();

  if (!cleaned) {
    return "Keep building. Small honest progress still counts today.";
  }

  const words = cleaned.split(/\s+/).filter(Boolean);
  if (words.length <= QUOTE_MAX_WORDS) {
    return cleaned;
  }

  return words.slice(0, QUOTE_MAX_WORDS).join(" ");
}

function deterministicFallbackQuote(profile) {
  const tone = profile.toneKey;
  const commits = profile.commitsKey;

  if (tone === "Roast") {
    return commits === "0c"
      ? "Your graph called. It wants effort, not another dramatic planning session."
      : "Fine, you committed. Try making the next change useful too.";
  }

  if (tone === "Friendly") {
    return commits === "0c"
      ? "A small real improvement today is enough. Pick one task and move it forward."
      : "Nice work. You are safe today, so choose one meaningful next step.";
  }

  return commits === "0c"
    ? "Start with one real task today. Consistency grows from honest work."
    : "Momentum is already here. Push one meaningful improvement before you close today.";
}

function quoteBackoffMs(attempt, payload) {
  const headerRetry = Number(payload?.error?.details?.retryDelaySeconds);
  if (Number.isFinite(headerRetry) && headerRetry > 0) {
    return Math.max(Math.floor(headerRetry * 1000), QUOTE_REQUEST_DELAY_MS);
  }
  return Math.min(QUOTE_REQUEST_DELAY_MS * 2 ** attempt, 8000);
}

function buildGeminiError(statusCode, payload) {
  const error = new Error(
    payload?.error?.message || `Gemini request failed (${statusCode})`,
  );
  error.statusCode = statusCode;
  error.details = JSON.stringify(payload);
  return error;
}

async function cleanupOldDailyQuotes(db, now) {
  const cutoffDate = new Date(now);
  cutoffDate.setUTCDate(cutoffDate.getUTCDate() - QUOTE_RETENTION_DAYS);
  const cutoffKey = formatDateKey(cutoffDate);
  const snapshot = await db.collection(DAILY_QUOTES_COLLECTION).get();

  const deletions = snapshot.docs
    .filter((doc) => doc.id < cutoffKey)
    .map((doc) => doc.ref.delete());

  if (deletions.length > 0) {
    await Promise.all(deletions);
  }

  logger.info("Daily quote cleanup completed", {
    retainedFrom: cutoffKey,
    deletedCount: deletions.length,
  });
}

function formatDateKey(date) {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
