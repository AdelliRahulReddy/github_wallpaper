import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String Function(int value)? formatter;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.formatter,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = reduceMotion ? Duration.zero : duration;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: effectiveDuration,
      curve: curve,
      builder: (context, animatedValue, child) {
        final roundedValue = animatedValue.round();
        final text = formatter?.call(roundedValue) ?? '$roundedValue';
        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: style,
        );
      },
    );
  }
}
