export const firebaseConfig = {
  apiKey: "AIzaSyDUOseD3NbhJ8N-QP5l6MGHUxO9iom7F_Q",
  appId: "1:826591895293:web:16c61e38e4818f165d6894",
  messagingSenderId: "826591895293",
  projectId: "gitwall-d63cc",
  authDomain: "gitwall-d63cc.firebaseapp.com",
  storageBucket: "gitwall-d63cc.firebasestorage.app",
  measurementId: "G-9TFBGFEV03",
};

export const constants = {
  functionsBase: "https://us-central1-gitwall-d63cc.cloudfunctions.net",
  firestoreDatabaseId: "default",
};

export const schemas = {
  app_config: [
    { key: "maintenance_mode", label: "Maintenance mode", type: "boolean" },
    {
      key: "maintenance_message",
      label: "Maintenance message",
      type: "string",
    },
    { key: "force_update_enabled", label: "Force update", type: "boolean" },
    {
      key: "force_update_min_version",
      label: "Min supported version",
      type: "string",
    },
    {
      key: "force_update_message",
      label: "Force update message",
      type: "string",
    },
    { key: "ai_quotes_enabled", label: "AI quotes enabled", type: "boolean" },
    {
      key: "ai_quotes_quota_exceeded",
      label: "AI quota exceeded",
      type: "boolean",
    },
    { key: "debug_mode_enabled", label: "Debug mode enabled", type: "boolean" },
    { key: "onboarding_version", label: "Onboarding version", type: "number" },
    {
      key: "coupon_access_duration_days",
      label: "Coupon access duration days",
      type: "number",
    },
  ],
};

export const defaults = {
  app_config: {
    maintenance_mode: false,
    maintenance_message: "We'll be back soon",
    force_update_enabled: false,
    force_update_min_version: "1.0.0",
    force_update_message: "Please update GitWall",
    ai_quotes_enabled: true,
    ai_quotes_quota_exceeded: false,
    debug_mode_enabled: false,
    onboarding_version: 1,
    coupon_access_duration_days: 180,
  },
};
