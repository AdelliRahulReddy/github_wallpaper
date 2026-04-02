import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import {
  GoogleAuthProvider,
  browserLocalPersistence,
  getAuth,
  getRedirectResult,
  onAuthStateChanged,
  setPersistence,
  signInWithPopup,
  signInWithRedirect,
  signOut,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getFirestore,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";
import { constants, defaults, firebaseConfig, schemas } from "./config.js";

const firebaseApp = initializeApp(firebaseConfig);
const auth = getAuth(firebaseApp);
const db = getFirestore(firebaseApp, "default");
const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({ prompt: "select_account" });

const UNAUTHORIZED_ADMIN_MESSAGE =
  "This Google account is not currently authorized as a web admin. Add admins/<your email> with enabled: true in Firestore first.";
const DEFAULT_AUTH_HELPER_MESSAGE =
  "Sign in once with your approved Google admin account and this dashboard will restore the session automatically.";

const elements = {
  authStatePill: document.querySelector("#auth-state-pill"),
  realtimeStatePill: document.querySelector("#realtime-state-pill"),
  realtimeHelper: document.querySelector("#realtime-helper"),
  signOutButton: document.querySelector("#sign-out-button"),
  startSignInButton: document.querySelector("#start-sign-in"),
  authSignedOut: document.querySelector("#auth-signed-out"),
  authSignedIn: document.querySelector("#auth-signed-in"),
  authHelper: document.querySelector("#auth-helper"),
  sessionName: document.querySelector("#session-name"),
  sessionEmail: document.querySelector("#session-email"),
  sessionMode: document.querySelector("#session-mode"),
  statusBanner: document.querySelector("#status-banner"),
  dashboard: document.querySelector("#dashboard"),
  summaryGrid: document.querySelector("#summary-grid"),
  appConfigFields: document.querySelector("#app-config-fields"),
  broadcastTitle: document.querySelector("#broadcast-title"),
  broadcastBody: document.querySelector("#broadcast-body"),
  sendBroadcastButton: document.querySelector("#send-broadcast-button"),
  broadcastFeed: document.querySelector("#broadcast-feed"),
  adminsTable: document.querySelector("#admins-table"),
  metricsGrid: document.querySelector("#metrics-grid"),
  crashReportList: document.querySelector("#crash-report-list"),
  logList: document.querySelector("#log-list"),
  adminForm: document.querySelector("#admin-form"),
  adminEmail: document.querySelector("#admin-email"),
  adminRole: document.querySelector("#admin-role"),
  adminEnabled: document.querySelector("#admin-enabled"),
  adminNotes: document.querySelector("#admin-notes"),
  resetAdminForm: document.querySelector("#reset-admin-form"),
  userSearch: document.querySelector("#user-search"),
  usersTable: document.querySelector("#users-table"),
};

const state = {
  authorized: false,
  currentAdminId: null,
  currentUserName: "",
  currentUserEmail: "",
  docs: structuredClone(defaults),
  drafts: structuredClone(defaults),
  admins: [],
  metrics: {},
  broadcasts: [],
  crashReports: [],
  logs: [],
  users: [],
  unsubscribers: [],
  lastAuthError: "",
  userSearch: "",
  realtime: {
    status: "idle",
    detail: "Waiting for admin session.",
    lastEventAt: null,
  },
};

const authPersistenceReady = initializeAuthPersistence();

elements.startSignInButton.addEventListener("click", startGoogleSignIn);
elements.signOutButton.addEventListener("click", handleSignOut);
elements.adminForm.addEventListener("submit", handleAdminSubmit);
elements.resetAdminForm.addEventListener("click", resetAdminForm);
elements.userSearch.addEventListener("input", handleUserSearch);
elements.sendBroadcastButton.addEventListener("click", sendAdminBroadcast);
document.addEventListener("click", handleGlobalClick);
document.addEventListener("input", handleFieldChange);
document.addEventListener("change", handleFieldChange);
window.addEventListener("focus", handleWindowFocus);
window.addEventListener("online", handleConnectivityChange);
window.addEventListener("offline", handleConnectivityChange);

void bootstrapAuth();

function resetLiveState() {
  state.authorized = false;
  state.currentAdminId = null;
  state.currentUserName = "";
  state.currentUserEmail = "";
  state.docs = structuredClone(defaults);
  state.drafts = structuredClone(defaults);
  state.admins = [];
  state.metrics = {};
  state.broadcasts = [];
  state.crashReports = [];
  state.logs = [];
  state.users = [];
  state.userSearch = "";
  state.realtime.lastEventAt = null;
  setRealtimeStatus("idle", "Waiting for admin session.");
}

async function startGoogleSignIn() {
  if (state.authorized) {
    return;
  }

  showBanner("Starting Google sign-in…", "success");
  setRealtimeStatus("authorizing", "Opening Google sign-in.");

  try {
    await authPersistenceReady;
    state.lastAuthError = "";
    await signInWithPopup(auth, googleProvider);
  } catch (error) {
    if (error?.code === "auth/popup-blocked") {
      setRealtimeStatus("authorizing", "Popup blocked. Redirecting to Google sign-in.");
      await signInWithRedirect(auth, googleProvider);
      return;
    }

    if (error?.code === "auth/popup-closed-by-user") {
      setRealtimeStatus("idle", "Google sign-in was closed before completion.");
      showBanner("Google sign-in was closed before completion.", "danger");
      return;
    }

    showBanner(extractErrorMessage(error), "danger");
  }
}

async function handleSignOut() {
  clearSubscriptions();
  resetLiveState();
  await signOut(auth).catch(() => {});
  render();
  showBanner("Signed out.", "success");
}

async function loadDashboard() {
  await assertAdmin();
  clearSubscriptions();
  subscribeDoc("app_config", doc(db, "config", "app_config"));
  subscribeBroadcasts();
  subscribeMetrics();
  subscribeAdmins();
  subscribeUsers();
  subscribeIncidentFeeds();
  setRealtimeStatus("connecting", "Realtime listeners connected. Waiting for the first live snapshot.");
}

async function assertAdmin() {
  try {
    const adminDoc = await getDoc(doc(db, "admins", state.currentAdminId));
    if (!adminDoc.exists() || adminDoc.data()?.enabled === false) {
      throw new Error(UNAUTHORIZED_ADMIN_MESSAGE);
    }
  } catch (error) {
    if (error?.code === "permission-denied") {
      throw new Error(UNAUTHORIZED_ADMIN_MESSAGE);
    }
    throw error;
  }
}

function subscribeDoc(key, ref) {
  state.unsubscribers.push(
    onSnapshot(
      ref,
      (snapshot) => {
        const data = snapshot.exists() ? snapshot.data() : structuredClone(defaults[key]);
        state.docs[key] = { ...structuredClone(defaults[key]), ...data };
        state.drafts[key] = structuredClone(state.docs[key]);
        renderConfigSection(key);
        renderSummary();
        noteRealtimeEvent(`Live config refreshed from ${prettyLabel(key)}.`);
      },
      onSnapshotError,
    ),
  );
}

function subscribeMetrics() {
  state.unsubscribers.push(
    onSnapshot(
      doc(db, "admin_metrics", "summary"),
      (snapshot) => {
        state.metrics = snapshot.exists() ? snapshot.data() : {};
        renderMetrics();
        renderSummary();
        noteRealtimeEvent("Realtime metrics refreshed.");
      },
      onSnapshotError,
    ),
  );
}

function subscribeAdmins() {
  state.unsubscribers.push(
    onSnapshot(
      collection(db, "admins"),
      (snapshot) => {
        state.admins = snapshot.docs
          .map((item) => ({ id: item.id, ...item.data() }))
          .sort((left, right) => left.id.localeCompare(right.id));
        renderAdmins();
        renderMetrics();
        renderSummary();
        noteRealtimeEvent("Admin access list refreshed.");
      },
      onSnapshotError,
    ),
  );
}

function subscribeUsers() {
  state.unsubscribers.push(
    onSnapshot(
      query(collection(db, "users"), orderBy("createdAt", "desc"), limit(200)),
      (snapshot) => {
        state.users = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }));
        renderUsers();
        renderMetrics();
        renderSummary();
        noteRealtimeEvent("User records refreshed.");
      },
      onSnapshotError,
    ),
  );
}

function subscribeBroadcasts() {
  state.unsubscribers.push(
    onSnapshot(
      query(collection(db, "admin_notifications"), orderBy("created_at", "desc"), limit(20)),
      (snapshot) => {
        state.broadcasts = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }));
        renderBroadcasts();
        renderSummary();
        noteRealtimeEvent("Broadcast delivery feed refreshed.");
      },
      onSnapshotError,
    ),
  );
}

function subscribeIncidentFeeds() {
  state.unsubscribers.push(
    onSnapshot(
      query(collection(db, "admin_crash_reports"), orderBy("timestamp", "desc"), limit(20)),
      (snapshot) => {
        state.crashReports = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }));
        renderList(
          elements.crashReportList,
          state.crashReports,
          "No crash reports found yet. Realtime incidents will appear here automatically.",
        );
        renderMetrics();
        renderSummary();
        noteRealtimeEvent("Crash report feed refreshed.");
      },
      onSnapshotError,
    ),
  );

  state.unsubscribers.push(
    onSnapshot(
      query(collection(db, "logs"), orderBy("timestamp", "desc"), limit(25)),
      (snapshot) => {
        state.logs = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }));
        renderList(elements.logList, state.logs, "No telemetry logs found yet. Realtime logs will appear here automatically.");
        renderMetrics();
        renderSummary();
        noteRealtimeEvent("Telemetry log feed refreshed.");
      },
      onSnapshotError,
    ),
  );
}

function onSnapshotError(error) {
  const message = extractErrorMessage(error);
  setRealtimeStatus("degraded", message);
  showBanner(message, "danger");
}

function clearSubscriptions() {
  for (const unsubscribe of state.unsubscribers) {
    unsubscribe();
  }
  state.unsubscribers = [];
}

function render() {
  renderPill(state.authorized ? "Admin session active" : "Signed out");
  renderRealtimeStatus();

  elements.signOutButton.classList.toggle("hidden", !state.authorized);
  elements.authSignedOut.classList.toggle("hidden", state.authorized);
  elements.authSignedIn.classList.toggle("hidden", !state.authorized);
  elements.dashboard.classList.toggle("hidden", !state.authorized);
  elements.sendBroadcastButton.disabled = !state.authorized;

  if (!state.authorized) {
    elements.authHelper.textContent = state.lastAuthError || DEFAULT_AUTH_HELPER_MESSAGE;
    return;
  }

  elements.authHelper.textContent = DEFAULT_AUTH_HELPER_MESSAGE;
  elements.sessionName.textContent = state.currentUserName || "Google admin";
  elements.sessionEmail.textContent = state.currentUserEmail || "No verified email";
  elements.sessionMode.textContent = buildRealtimeSessionLabel();
  renderConfigSection("app_config");
  renderAdmins();
  renderUsers();
  renderBroadcasts();
  renderMetrics();
  renderList(
    elements.crashReportList,
    state.crashReports,
    "No crash reports found yet. Realtime incidents will appear here automatically.",
  );
  renderList(elements.logList, state.logs, "No telemetry logs found yet. Realtime logs will appear here automatically.");
  renderSummary();
}

function renderPill(text) {
  elements.authStatePill.textContent = text;
}

function renderRealtimeStatus() {
  const { label, tone } = getRealtimePresentation();
  elements.realtimeStatePill.textContent = label;
  elements.realtimeStatePill.dataset.tone = tone;
  elements.realtimeHelper.textContent = buildRealtimeDetail();
}

function renderSummary() {
  const derivedMetrics = getDerivedMetrics();
  const cards = [
    { label: "Session", value: state.authorized ? "Live" : "Signed out", meta: "Realtime admin connection" },
    { label: "Admins", value: String(state.admins.length), meta: "Whitelisted operators" },
    { label: "Users", value: String(derivedMetrics.visible_users ?? 0), meta: "Visible user records" },
    { label: "Maintenance", value: state.docs.app_config?.maintenance_mode ? "On" : "Off", meta: "App availability flag" },
    { label: "Crashes", value: String(derivedMetrics.visible_crash_reports ?? 0), meta: "Visible crash reports" },
    { label: "Sync Failures", value: String(derivedMetrics.sync_failures_visible ?? 0), meta: "Visible telemetry failures" },
  ];

  elements.summaryGrid.innerHTML = cards
    .map(
      (card) => `
        <article class="summary-card">
          <span>${escapeHtml(card.label)}</span>
          <strong>${escapeHtml(card.value)}</strong>
          <span>${escapeHtml(card.meta)}</span>
        </article>
      `,
    )
    .join("");
}

function renderConfigSection(key) {
  const targets = {
    app_config: elements.appConfigFields,
  };
  const target = targets[key];
  target.innerHTML = schemas[key].map((field) => renderField(key, field, state.drafts[key]?.[field.key])).join("");
  const saveButton = document.querySelector(`[data-save-doc="${key}"]`);
  saveButton.disabled = !state.authorized;
  saveButton.textContent = "Save";
}

function renderField(docKey, field, value) {
  if (field.type === "boolean") {
    return `
      <label class="field field-toggle">
        <span>${escapeHtml(field.label)}</span>
        <input data-doc-key="${docKey}" data-field-key="${field.key}" type="checkbox" ${value ? "checked" : ""} />
      </label>
    `;
  }

  if (field.type === "json") {
    return `
      <label class="field field-full">
        <span>${escapeHtml(field.label)}</span>
        <textarea data-doc-key="${docKey}" data-field-key="${field.key}" rows="10">${escapeHtml(JSON.stringify(value ?? [], null, 2))}</textarea>
      </label>
    `;
  }

  return `
    <label class="field ${field.type === "string" && String(value ?? "").length > 90 ? "field-full" : ""}">
      <span>${escapeHtml(field.label)}</span>
      <input data-doc-key="${docKey}" data-field-key="${field.key}" type="${field.type === "number" ? "number" : "text"}" value="${escapeHtml(String(value ?? ""))}" />
    </label>
  `;
}

function renderAdmins() {
  elements.adminsTable.innerHTML =
    state.admins.length === 0
      ? `<tr><td colspan="4"><div class="empty-state">No admin entries found.</div></td></tr>`
      : state.admins
          .map(
            (item) => `
              <tr>
                <td>
                  <strong>${escapeHtml(item.id)}</strong>
                  ${item.notes ? `<div class="meta">${escapeHtml(item.notes)}</div>` : ""}
                </td>
                <td>${escapeHtml(item.role ?? "admin")}</td>
                <td><span class="status-chip ${item.enabled !== false ? "enabled" : "disabled"}">${item.enabled !== false ? "Enabled" : "Disabled"}</span></td>
                <td>
                  <div class="stack-inline">
                    <button class="secondary-button" data-edit-admin="${escapeHtml(item.id)}" type="button">Edit</button>
                    <button class="ghost-button" data-delete-admin="${escapeHtml(item.id)}" type="button">Delete</button>
                  </div>
                </td>
              </tr>
            `,
          )
          .join("");
}

function renderUsers() {
  const items = getVisibleUsers();
  elements.usersTable.innerHTML =
    items.length === 0
      ? `<tr><td colspan="4"><div class="empty-state">No users match the current search.</div></td></tr>`
      : items
          .map((item) => {
            const identity = item.username
              ? `<strong>${escapeHtml(item.id)}</strong><div class="meta">${escapeHtml(item.username)}</div>`
              : `<strong>${escapeHtml(item.id)}</strong>`;
            return `
              <tr>
                <td>${identity}</td>
                <td>${escapeHtml(item.email || "None")}</td>
                <td>${escapeHtml(formatTimestamp(item.createdAt) || "Unknown")}</td>
                <td>${escapeHtml(formatTimestamp(item.updatedAt) || "Unknown")}</td>
              </tr>
            `;
          })
          .join("");
}

function renderBroadcasts() {
  elements.broadcastFeed.innerHTML =
    state.broadcasts.length === 0
      ? `<div class="empty-state">No broadcast attempts yet. Send a custom notification to see live delivery status here.</div>`
      : state.broadcasts
          .map((item) => {
            const meta = [
              item.requested_by ? `By ${item.requested_by}` : null,
              formatTimestamp(item.created_at),
              item.message_id ? `FCM ${item.message_id}` : null,
            ]
              .filter(Boolean)
              .join(" · ");
            const counters = [
              `Received ${Number(item.received_count ?? 0)}`,
              `Displayed ${Number(item.displayed_count ?? 0)}`,
              `Opened ${Number(item.opened_count ?? 0)}`,
            ];
            const detail =
              item.status === "failed"
                ? item.error_message || "Broadcast failed before FCM accepted it."
                : item.status === "accepted"
                  ? "Accepted by Firebase Cloud Messaging. Waiting for device receipts."
                  : "Broadcast request created and waiting for FCM acceptance.";

            return `
              <article class="list-item">
                <div class="list-item-header">
                  <div>
                    <h4>${escapeHtml(item.title || "Untitled broadcast")}</h4>
                    <div class="meta">${escapeHtml(meta || item.id)}</div>
                  </div>
                  <span class="status-chip ${escapeHtml(String(item.status || "pending").toLowerCase())}">
                    ${escapeHtml(prettyLabel(String(item.status || "pending")))}
                  </span>
                </div>
                <div>${escapeHtml(item.body || "")}</div>
                <div class="meta">${escapeHtml(detail)}</div>
                <div class="list-item-metrics">
                  ${counters
                    .map(
                      (counter) =>
                        `<span class="status-chip received">${escapeHtml(counter)}</span>`,
                    )
                    .join("")}
                </div>
                ${item.error_message ? `<pre>${escapeHtml(item.error_message)}</pre>` : ""}
              </article>
            `;
          })
          .join("");
}

function renderMetrics() {
  const mergedMetrics = new Map(Object.entries(getDerivedMetrics()));
  for (const [key, value] of Object.entries(state.metrics || {})) {
    if (["string", "number", "boolean"].includes(typeof value)) {
      mergedMetrics.set(key, value);
    }
  }

  const entries = [...mergedMetrics.entries()];
  elements.metricsGrid.innerHTML =
    entries.length === 0
      ? `<div class="empty-state">No metrics are available yet.</div>`
      : entries
          .map(
            ([key, value]) => `
              <article class="metric-card">
                <span>${escapeHtml(prettyLabel(key))}</span>
                <strong>${escapeHtml(formatValue(value))}</strong>
              </article>
            `,
          )
          .join("");
}

function getDerivedMetrics() {
  const failureCounts = {
    sync_failures_visible: 0,
    wallpaper_failures_visible: 0,
    background_job_failures_visible: 0,
  };

  for (const item of state.logs) {
    if (item.type === "sync_failure") {
      failureCounts.sync_failures_visible += 1;
    } else if (item.type === "wallpaper_failure") {
      failureCounts.wallpaper_failures_visible += 1;
    } else if (item.type === "background_job_failure") {
      failureCounts.background_job_failures_visible += 1;
    }
  }

  return {
    whitelisted_admins: state.admins.length,
    visible_users: state.users.length,
    visible_log_events: state.logs.length,
    visible_crash_reports: state.crashReports.length,
    latest_log_at: formatTimestamp(state.logs[0]?.timestamp) || "None",
    ...failureCounts,
  };
}

function renderList(target, items, emptyMessage) {
  target.innerHTML =
    items.length === 0
      ? `<div class="empty-state">${escapeHtml(emptyMessage)}</div>`
      : items
          .map((item) => {
            const meta = [item.platform, item.app_version, formatTimestamp(item.timestamp)].filter(Boolean).join(" · ");
            return `
              <article class="list-item">
                <div class="meta">${escapeHtml(meta)}</div>
                <h4>${escapeHtml(item.type ?? item.id)}</h4>
                ${item.username ? `<div class="meta">User: ${escapeHtml(item.username)}</div>` : ""}
                ${item.error ? `<pre>${escapeHtml(item.error)}</pre>` : ""}
              </article>
            `;
          })
          .join("");
}

function handleFieldChange(event) {
  const docKey = event.target.dataset.docKey;
  const fieldKey = event.target.dataset.fieldKey;
  if (!docKey || !fieldKey || !(docKey in state.drafts)) {
    return;
  }

  state.drafts[docKey][fieldKey] = event.target.type === "checkbox" ? event.target.checked : event.target.value;
}

async function handleGlobalClick(event) {
  const saveDocKey = event.target.dataset.saveDoc;
  if (saveDocKey) {
    await saveConfig(saveDocKey);
    return;
  }

  const editAdminId = event.target.dataset.editAdmin;
  if (editAdminId) {
    populateAdminForm(editAdminId);
    return;
  }

  const deleteAdminId = event.target.dataset.deleteAdmin;
  if (deleteAdminId) {
    await deleteAdmin(deleteAdminId);
  }
}

async function saveConfig(docKey) {
  try {
    const normalized = normalizeConfigPayload(docKey, state.drafts[docKey]);
    await setDoc(
      doc(db, "config", docKey),
      {
        ...normalized,
        updated_at: serverTimestamp(),
        updated_by: state.currentAdminId,
        version: Number(state.docs[docKey]?.version ?? 0) + 1,
      },
      { merge: true },
    );
    showBanner(`${prettyLabel(docKey)} saved.`, "success");
  } catch (error) {
    showBanner(extractErrorMessage(error), "danger");
  }
}

function normalizeConfigPayload(docKey, draft) {
  const normalized = {};

  for (const field of schemas[docKey]) {
    const raw = draft[field.key];
    if (field.type === "boolean") {
      normalized[field.key] = Boolean(raw);
    } else if (field.type === "number") {
      normalized[field.key] = Number(raw || 0);
    } else if (field.type === "json") {
      const parsed =
        Array.isArray(raw) ? raw : JSON.parse(typeof raw === "string" && raw.trim() ? raw : "[]");
      if (!Array.isArray(parsed)) {
        throw new Error(`${field.label} must be a JSON array.`);
      }
      normalized[field.key] = parsed;
    } else {
      normalized[field.key] = `${raw ?? ""}`.trim();
    }
  }

  return normalized;
}

function populateAdminForm(adminId) {
  const item = state.admins.find((entry) => entry.id === adminId);
  if (!item) {
    return;
  }

  elements.adminEmail.value = item.id;
  elements.adminRole.value = item.role ?? "admin";
  elements.adminEnabled.checked = item.enabled !== false;
  elements.adminNotes.value = item.notes ?? "";
}

function resetAdminForm() {
  elements.adminForm.reset();
  elements.adminEnabled.checked = true;
}

function handleUserSearch(event) {
  state.userSearch = event.target.value.trim().toLowerCase();
  renderUsers();
}

async function handleAdminSubmit(event) {
  event.preventDefault();

  const email = elements.adminEmail.value.trim().toLowerCase();
  if (!email) {
    showBanner("Admin email is required.", "danger");
    return;
  }

  try {
    const ref = doc(db, "admins", email);
    const existing = await getDoc(ref);
    await setDoc(
      ref,
      {
        email,
        role: elements.adminRole.value.trim() || "admin",
        enabled: elements.adminEnabled.checked,
        notes: elements.adminNotes.value.trim(),
        updated_by: state.currentAdminId,
        updated_at: serverTimestamp(),
        added_by: existing.data()?.added_by ?? state.currentAdminId,
        added_at: existing.data()?.added_at ?? serverTimestamp(),
      },
      { merge: true },
    );
    resetAdminForm();
    showBanner(`Admin entry saved for ${email}.`, "success");
  } catch (error) {
    showBanner(extractErrorMessage(error), "danger");
  }
}

async function deleteAdmin(adminId) {
  if (adminId === state.currentAdminId) {
    showBanner("You cannot delete the admin account currently in use.", "danger");
    return;
  }

  const enabledAdmins = state.admins.filter((entry) => entry.enabled !== false);
  if (
    enabledAdmins.length <= 1 &&
    enabledAdmins.some((entry) => entry.id === adminId)
  ) {
    showBanner("You cannot delete the last enabled admin.", "danger");
    return;
  }

  if (!window.confirm(`Delete admin entry for ${adminId}?`)) {
    return;
  }

  try {
    await deleteDoc(doc(db, "admins", adminId));
    showBanner(`Deleted ${adminId}.`, "success");
  } catch (error) {
    showBanner(extractErrorMessage(error), "danger");
  }
}

async function sendAdminBroadcast() {
  const title = elements.broadcastTitle.value.trim();
  const body = elements.broadcastBody.value.trim();

  if (!title) {
    showBanner("Broadcast title is required.", "danger");
    return;
  }

  if (!body) {
    showBanner("Broadcast message is required.", "danger");
    return;
  }

  elements.sendBroadcastButton.disabled = true;
  elements.sendBroadcastButton.textContent = "Sending…";
  setRealtimeStatus("connecting", "Sending admin broadcast notification.");

  try {
    const payload = await postJsonWithAdminAuth(`${constants.functionsBase}/sendAdminBroadcast`, {
      title,
      body,
    });
    elements.broadcastTitle.value = "";
    elements.broadcastBody.value = "";
    setRealtimeStatus("live", "Admin broadcast request accepted. Waiting for live delivery updates.");
    showBanner(
      `Broadcast ${payload.status || "accepted"} by FCM. Tracking ID: ${payload.notificationId}.`,
      "success",
    );
  } catch (error) {
    showBanner(extractErrorMessage(error), "danger");
  } finally {
    elements.sendBroadcastButton.disabled = !state.authorized;
    elements.sendBroadcastButton.textContent = "Send";
  }
}

async function postJsonWithAdminAuth(url, body) {
  const user = auth.currentUser;
  if (!user) {
    throw new Error("Sign in again before sending a broadcast.");
  }

  const idToken = await user.getIdToken();
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify(body),
  });

  const payload = await response.json().catch(() => ({}));
  if (response.ok) {
    return payload;
  }

  const error = new Error(payload.message || `HTTP ${response.status}`);
  error.httpStatus = response.status;
  error.payload = payload;
  throw error;
}

function extractErrorMessage(error) {
  if (error?.code === "permission-denied") {
    return "Admin sign-in is active, but Firestore denied access to one of the dashboard collections. Deploy the latest firestore.rules and hard-refresh this page.";
  }

  if (error?.code === "auth/account-exists-with-different-credential") {
    return "This email already exists with a different Firebase sign-in method.";
  }

  if (error?.code === "auth/unauthorized-domain") {
    return "This domain is not authorized in Firebase Authentication. Add localhost in authorized domains.";
  }

  if (error?.code === "auth/operation-not-allowed") {
    return "Google sign-in is not enabled in Firebase Authentication for this project.";
  }

  if (typeof error?.message === "string" && error.message.trim()) {
    if (error.message.includes("not currently authorized as a web admin")) {
      return UNAUTHORIZED_ADMIN_MESSAGE;
    }
    return error.message;
  }

  return "Something went wrong.";
}

function showBanner(message, tone = "success") {
  elements.statusBanner.classList.remove("hidden");
  elements.statusBanner.dataset.tone = tone;
  elements.statusBanner.textContent = message;
  if (tone === "danger") {
    state.lastAuthError = message;
    setRealtimeStatus("degraded", message);
  } else if (tone === "success" && state.authorized) {
    state.lastAuthError = "";
  }
}

function prettyLabel(value) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (match) => match.toUpperCase());
}

function formatValue(value) {
  if (typeof value === "number") {
    return Number.isInteger(value) ? value.toString() : value.toFixed(2);
  }

  if (typeof value === "boolean") {
    return value ? "On" : "Off";
  }

  return String(value);
}

async function initializeAuthPersistence() {
  try {
    await setPersistence(auth, browserLocalPersistence);
  } catch (error) {
    const message =
      "Browser session persistence could not be enabled. Admin login may be lost on refresh.";
    state.lastAuthError = message;
    showBanner(message, "danger");
    throw error;
  }
}

async function bootstrapAuth() {
  setRealtimeStatus("connecting", "Restoring any saved admin session.");
  try {
    await authPersistenceReady;
    await getRedirectResult(auth).catch((error) => {
      throw error;
    });
  } catch (error) {
    showBanner(extractErrorMessage(error), "danger");
  }

  onAuthStateChanged(auth, async (user) => {
    clearSubscriptions();

    if (!user) {
      resetLiveState();
      render();
      return;
    }

    try {
      const email = `${user.email ?? ""}`.trim().toLowerCase();
      if (!email) {
        throw new Error("This Google session is missing a verified email.");
      }

      state.currentAdminId = email;
      state.currentUserEmail = email;
      state.currentUserName = `${user.displayName ?? ""}`.trim() || email;
      state.authorized = true;
      state.lastAuthError = "";
      setRealtimeStatus("connecting", "Google session restored. Connecting live Firestore listeners.");
      render();
      await loadDashboard();
      showBanner(`Signed in as ${email}. Live updates are active.`, "success");
    } catch (error) {
      const message = extractErrorMessage(error);
      resetLiveState();
      state.lastAuthError = message;
      render();
      await signOut(auth).catch(() => {});
      showBanner(message, "danger");
    }
  });

  render();
}

function getRealtimePresentation() {
  switch (state.realtime.status) {
    case "authorizing":
      return { label: "Authorizing", tone: "warning" };
    case "connecting":
      return { label: "Connecting Live", tone: "warning" };
    case "live":
      return { label: "Realtime Live", tone: "success" };
    case "degraded":
      return { label: "Realtime Blocked", tone: "danger" };
    case "offline":
      return { label: "Offline", tone: "danger" };
    default:
      return { label: "Realtime Standby", tone: "warning" };
  }
}

function setRealtimeStatus(status, detail) {
  state.realtime.status = status;
  state.realtime.detail = detail;
  renderRealtimeStatus();
}

function noteRealtimeEvent(detail) {
  state.realtime.status = "live";
  state.realtime.detail = detail;
  state.realtime.lastEventAt = new Date();
  renderRealtimeStatus();
}

function buildRealtimeDetail() {
  const detail = state.realtime.detail || "Waiting for admin session.";
  const suffix = state.realtime.lastEventAt
    ? ` Last update at ${state.realtime.lastEventAt.toLocaleTimeString()}.`
    : "";
  return `${detail}${suffix}`;
}

function buildRealtimeSessionLabel() {
  if (!state.authorized) {
    return "Session inactive";
  }

  return state.realtime.lastEventAt
    ? `Realtime session • last live update ${state.realtime.lastEventAt.toLocaleTimeString()}`
    : "Realtime session";
}

function handleWindowFocus() {
  if (state.authorized && navigator.onLine) {
    setRealtimeStatus(
      state.realtime.lastEventAt ? "live" : "connecting",
      state.realtime.lastEventAt
        ? "Dashboard is connected and waiting for the next live change."
        : "Dashboard is active. Waiting for the first live Firestore snapshot.",
    );
  }
}

function handleConnectivityChange() {
  if (!navigator.onLine) {
    setRealtimeStatus("offline", "Browser is offline. Live updates are paused until the connection returns.");
    return;
  }

  if (state.authorized) {
    setRealtimeStatus(
      state.realtime.lastEventAt ? "live" : "connecting",
      state.realtime.lastEventAt
        ? "Connection restored. Realtime listeners are active."
        : "Connection restored. Waiting for live Firestore data.",
    );
    return;
  }

  setRealtimeStatus("idle", "Connection restored. Waiting for admin session.");
}

function getVisibleUsers() {
  return state.users.filter((item) => {
    if (!state.userSearch) {
      return true;
    }

    const haystack = `${item.id} ${item.username ?? ""} ${item.email ?? ""}`.toLowerCase();
    return haystack.includes(state.userSearch);
  });
}

function getDateValue(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatTimestamp(value) {
  if (!value) {
    return "";
  }

  if (typeof value.toDate === "function") {
    return value.toDate().toLocaleString();
  }

  if (value instanceof Date) {
    return value.toLocaleString();
  }

  return String(value);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
