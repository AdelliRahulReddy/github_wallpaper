import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:github_wallpaper/core/utils/app_utils.dart';

enum ProductEventName {
  syncStarted('sync_started'),
  syncSucceeded('sync_succeeded'),
  syncFailed('sync_failed'),
  wallpaperApplied('wallpaper_applied'),
  widgetTapped('widget_tapped'),
  reconnectCompleted('reconnect_completed');

  const ProductEventName(this.value);
  final String value;
}

@immutable
class ProductEvent {
  final ProductEventName name;
  final DateTime occurredAt;
  final Map<String, Object?> properties;

  const ProductEvent({
    required this.name,
    required this.occurredAt,
    this.properties = const <String, Object?>{},
  });
}

class ProductAnalytics {
  static final Queue<ProductEvent> _buffer = Queue<ProductEvent>();
  static const int _maxBufferedEvents = 100;

  static Future<void> track(
    ProductEventName name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    final event = ProductEvent(
      name: name,
      occurredAt: DateTime.now().toUtc(),
      properties: properties,
    );
    _buffer.addLast(event);
    while (_buffer.length > _maxBufferedEvents) {
      _buffer.removeFirst();
    }

    AppLog.info('product_event:${name.value} ${jsonEncode(properties)}');
  }

  @visibleForTesting
  static List<ProductEvent> get bufferedEvents =>
      List.unmodifiable(_buffer.toList(growable: false));

  @visibleForTesting
  static void clearBufferedEvents() {
    _buffer.clear();
  }
}
