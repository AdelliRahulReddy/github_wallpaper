part of 'app_utils.dart';

class SensitiveDataSanitizer {
  static final List<RegExp> _tokenPatterns = [
    RegExp(r'ghp_[a-zA-Z0-9_]+'),
    RegExp(r'gho_[a-zA-Z0-9_]+'),
    RegExp(r'ghu_[a-zA-Z0-9_]+'),
    RegExp(r'ghs_[a-zA-Z0-9_]+'),
    RegExp(r'ghr_[a-zA-Z0-9_]+'),
    RegExp(r'github_pat_[a-zA-Z0-9_]+'),
  ];

  static String sanitize(String msg) {
    var out = msg;
    for (final pattern in _tokenPatterns) {
      out = out.replaceAll(pattern, '[REDACTED_TOKEN]');
    }
    return out
        .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]')
        .replaceAll(
            RegExp(r'Authorization:\s*[^\s,]+'), 'Authorization: [REDACTED]')
        .replaceAll(RegExp(r'token\s*=\s*[^\s&]+', caseSensitive: false),
            'token=[REDACTED]');
  }
}

// ERROR HANDLING
class ErrorHandler {
  static String? getUserFriendlyMessage(dynamic e) {
    if (e is NetworkException ||
        e is SocketException ||
        e.toString().contains('socket')) {
      return AppStrings.errorNetwork;
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server is not deployed') {
      return 'GitHub sign-in backend is not deployed yet. Deploy exchangeGitHubCode or update GITHUB_CODE_EXCHANGE_URL.';
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server is missing OAuth secrets') {
      return 'GitHub sign-in backend is missing GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET in Firebase.';
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server timed out') {
      return 'GitHub sign-in server timed out. Check the deployed function URL and server health.';
    }
    if (e is TokenExpiredException || e.toString().contains('401')) {
      return 'GitHub authentication required';
    }
    if (e is AccessDeniedException || e.toString().contains('403')) {
      return AppStrings.errorAccessDenied;
    }
    if (e is UserNotFoundException) return AppStrings.errorUserNotFound;
    if (e is RateLimitException) return AppStrings.errorRateLimit;
    if (e is StorageException) return AppStrings.errorStorage;
    if (e is WallpaperException) return AppStrings.errorWallpaper;
    if (e is FlutterAppAuthUserCancelledException ||
        e.toString().contains('User cancelled flow')) {
      return null;
    }

    final msg = e.toString().replaceAll('Exception:', '').trim();
    return msg.isNotEmpty
        ? '${AppStrings.errorGeneric} ($msg)'
        : AppStrings.errorGeneric;
  }

  static void _showSnackBarSafely({
    required BuildContext? context,
    required SnackBar snackBar,
    bool clearExisting = true,
  }) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showSnackBarSafely(
          context: context,
          snackBar: snackBar,
          clearExisting: clearExisting,
        );
      });
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ScaffoldMessengerState? messenger = (context != null &&
              context.mounted)
          ? (ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState)
          : messengerKey.currentState;

      if (messenger == null || !messenger.mounted) return;

      if (clearExisting) messenger.clearSnackBars();
      messenger.showSnackBar(snackBar);
    });
  }

  static void handle(BuildContext? c, dynamic e,
      {String? userMessage, bool showSnackBar = true, VoidCallback? onRetry}) {
    if (e is FlutterAppAuthUserCancelledException ||
        e.toString().contains('User cancelled flow')) {
      return;
    }
    if (showSnackBar) {
      _showSnackBarSafely(
        context: c,
        snackBar: SnackBar(
          content: Text(userMessage ??
              getUserFriendlyMessage(e) ??
              AppStrings.errorGeneric),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(
                  label: AppStrings.retry,
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static void showSuccess(BuildContext? c, String m) {
    _showSnackBarSafely(
      context: c,
      snackBar: SnackBar(
        content: Text(m),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  static void showLoading(BuildContext c, {String? message}) {
    if (c.mounted) {
      showDialog(
          context: c,
          barrierDismissible: false,
          builder: (_) => PopScope(
              canPop: false,
              child: Center(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const CircularProgressIndicator(),
                            if (message != null) ...[
                              const SizedBox(height: 16),
                              Text(message)
                            ]
                          ]))))));
    }
  }

  static void hideLoading(BuildContext c) {
    if (c.mounted && Navigator.canPop(c)) {
      Navigator.of(c, rootNavigator: true).pop();
    }
  }
}

// LOGGING
class AppLog {
  static void info(String m) {
    if (kDebugMode) {
      debugPrint("🟢 [INFO]: $m");
    } else {
      try {
        FirebaseCrashlytics.instance.log(SensitiveDataSanitizer.sanitize(m));
      } catch (_) {}
    }
  }

  // Sanitize sensitive data from error messages
  static String _sanitizeError(String msg) {
    return SensitiveDataSanitizer.sanitize(msg);
  }

  static void error(dynamic e, [StackTrace? s]) {
    final sanitizedMessage = _sanitizeError(e.toString());
    if (kDebugMode) {
      debugPrint("🔴 [ERROR]: $sanitizedMessage");
      return;
    }

    try {
      FirebaseCrashlytics.instance.log('ERROR: $sanitizedMessage');
      if (s != null) {
        FirebaseCrashlytics.instance.log(_sanitizeError(s.toString()));
      }
    } catch (_) {}
  }
}

// DEBOUNCER
class Debouncer {
  final Duration delay;
  Timer? _t;
  Debouncer({required this.delay});
  void run(VoidCallback action) {
    _t?.cancel();
    _t = Timer(delay, action);
  }

  void dispose() => _t?.cancel();
}

// VALIDATION
class ValidationUtils {
  static final _usernameRegex =
      RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
  static final _phoneCleanRegex = RegExp(r'[^\d]');
  static const _reservedUsernames = [
    'admin',
    'api',
    'www',
    'github',
    'support',
    'blog',
    'about'
  ];

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final clean = v.trim().toLowerCase();
    if (clean.length < 2) return 'Username too short (min 2 characters)';
    if (v.length > AppConstants.usernameMaxLength) return 'Too long';
    if (_reservedUsernames.contains(clean)) return 'Reserved username';
    if (v.contains('--') || !_usernameRegex.hasMatch(v)) {
      return 'Invalid format';
    }
    return null;
  }

  static String? quote(String? v) =>
      (v != null && v.length > AppConstants.quoteMaxLength) ? 'Too long' : null;

  /// Sanitize custom quote to prevent control characters and injection
  static String sanitizeQuote(String input) {
    return input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // Remove control chars
        .replaceAll(RegExp(r'[<>{}]'), '') // Prevent injection
        .trim();
  }

  static String cleanPhone(String original) =>
      original.replaceAll(_phoneCleanRegex, '');
}

// BACKWARD COMPAT (Deprecate later)
String? isValidUsernameFormat(String? v) => ValidationUtils.username(v);
String? isValidQuoteFormat(String? v) => ValidationUtils.quote(v);

// CONSTANTS & STRINGS
