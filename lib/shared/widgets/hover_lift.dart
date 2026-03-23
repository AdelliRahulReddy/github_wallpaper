import 'package:flutter/material.dart';

class HoverLift extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool enableShadow;

  const HoverLift({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) => child;
}
