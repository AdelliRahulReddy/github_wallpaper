import 'package:flutter/material.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';

class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.98,
    this.duration = AppTheme.durationFast,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.enabled || reduceMotion) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
