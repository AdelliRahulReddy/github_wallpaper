import 'package:flutter/material.dart';

abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  @protected
  bool get isDisposed => _isDisposed;

  @protected
  void notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
