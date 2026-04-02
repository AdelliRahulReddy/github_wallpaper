class ProductStateLanguage {
  static String connectionLabel({
    required bool isConnected,
    required bool hasAuthIssue,
  }) {
    if (hasAuthIssue) return 'Reconnect required';
    if (isConnected) return 'Connected';
    return 'Not connected';
  }

  static String connectionDescription({
    required bool isConnected,
    required bool hasAuthIssue,
  }) {
    if (hasAuthIssue) {
      return 'GitHub needs attention before the next sync.';
    }
    if (isConnected) {
      return 'GitHub is linked and ready.';
    }
    return 'Connect GitHub to start your GitWall.';
  }

  static String freshnessLabel({
    required bool hasData,
    required bool isStale,
    required DateTime? lastSyncAt,
  }) {
    if (!hasData || lastSyncAt == null) return 'No sync yet';
    return isStale ? 'Stale' : 'Fresh';
  }

  static String freshnessDescription({
    required bool hasData,
    required bool isStale,
    required DateTime? lastSyncAt,
  }) {
    if (!hasData || lastSyncAt == null) {
      return 'Pull your GitHub activity to fill the dashboard.';
    }
    if (isStale) {
      return 'Your dashboard is showing cached activity.';
    }
    return 'Your latest GitHub activity is available.';
  }

  static String planLabel() => 'Included';

  static String planDescription() =>
      'All GitWall features are available on every account.';
}
