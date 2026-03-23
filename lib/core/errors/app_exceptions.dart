class GitHubException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  GitHubException(this.message, {this.statusCode, this.details});

  factory GitHubException.fromResponse(int statusCode, String body) {
    return GitHubException(
      'GitHub API Error ($statusCode)',
      statusCode: statusCode,
      details: body,
    );
  }

  @override
  String toString() => 'GitHubException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);

  @override
  String toString() => 'NetworkException: $message';
}

class UserNotFoundException implements Exception {
  @override
  String toString() => 'UserNotFoundException: User not found';
}

class RateLimitException implements Exception {
  @override
  String toString() => 'RateLimitException: API rate limit exceeded';
}

class TokenExpiredException implements Exception {
  @override
  String toString() => 'TokenExpiredException: Token expired or invalid';
}

class AccessDeniedException implements Exception {
  @override
  String toString() => 'AccessDeniedException: Access denied';
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

class WallpaperException implements Exception {
  final String message;
  WallpaperException(this.message);

  @override
  String toString() => 'WallpaperException: $message';
}

class ContextInitException implements Exception {
  final String message;
  ContextInitException(this.message);

  @override
  String toString() => 'ContextInitException: $message';
}
