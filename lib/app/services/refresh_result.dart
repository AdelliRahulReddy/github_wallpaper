enum RefreshResult {
  success,
  noChanges,
  networkError,
  authError,
  unknownError,
  throttled;

  bool get isSuccess => index <= 1;
}
