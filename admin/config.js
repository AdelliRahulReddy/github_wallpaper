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
  firestore: {
    collections: {
      config: "config",
      admins: "admins",
      users: "users",
      adminNotifications: "admin_notifications",
      adminMetrics: "admin_metrics",
      adminCrashReports: "admin_crash_reports",
      logs: "logs",
    },
    docs: {
      appConfig: "app_config",
      metricsSummary: "summary",
    },
  },
  notifications: {
    adminBroadcast: {
      topic: "all_users_broadcast",
      maxTitleLength: 80,
      maxBodyLength: 240,
      defaultTitle: "GitWall update",
      titlePlaceholder: "GitWall update",
      bodyPlaceholder:
        "Write the notification that should reach all users instantly.",
    },
  },
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
    {
      key: "smart_quotes_enabled",
      label: "Smart quotes enabled",
      type: "boolean",
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
    smart_quotes_enabled: true,
  },
};
