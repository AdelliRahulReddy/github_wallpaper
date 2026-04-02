import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:github_wallpaper/app/pages/main_nav_page.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/auth/services/auth_flow_service.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';
import 'package:github_wallpaper/features/auth/widgets/onboarding_content.dart';

class GitHubConnectPage extends StatefulWidget {
  const GitHubConnectPage({super.key});

  @override
  State<GitHubConnectPage> createState() => _GitHubConnectPageState();
}

@Deprecated('Use GitHubConnectPage')
class OnboardingPage extends GitHubConnectPage {
  const OnboardingPage({
    super.key,
    int initialPage = 0,
  }) : super();
}

class _GitHubConnectPageState extends State<GitHubConnectPage> {
  bool _isConnecting = false;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      OAuthService.prewarmExchangeEndpoint().catchError((_) {}),
    );
  }

  Future<void> _connect() async {
    if (_isConnecting || _isPreparing) return;
    HapticFeedback.lightImpact();
    await _connectGitHub();
  }

  Future<void> _connectGitHub() async {
    if (!mounted || _isConnecting || _isPreparing) return;

    setState(() => _isConnecting = true);
    try {
      await AuthFlowService.connectGitHub(
        onboardingFlow: true,
      );
      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _isPreparing = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      MainNavPage.navIndex.value = 2;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isPreparing = false;
      });
      ErrorHandler.handle(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width >= 980
        ? 44.0
        : size.width >= 720
            ? 32.0
            : 20.0;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: _OnboardingBackdrop(accent: scheme.primary),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                18,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: GitHubConnectContent(
                          accent: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SingleActionBar(
                    accent: scheme.primary,
                    isConnecting: _isConnecting,
                    isPreparing: _isPreparing,
                    onPressed: _connect,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isPreparing,
              child: AnimatedOpacity(
                opacity: _isPreparing ? 1 : 0,
                duration: AppTheme.durationNormal,
                curve: Curves.easeOut,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color:
                        scheme.surfaceContainerLowest.withValues(alpha: 0.78),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: OnboardingPreparingState(accent: scheme.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleActionBar extends StatelessWidget {
  const _SingleActionBar({
    required this.accent,
    required this.isConnecting,
    required this.isPreparing,
    required this.onPressed,
  });

  final Color accent;
  final bool isConnecting;
  final bool isPreparing;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final busy = isConnecting || isPreparing;
    final buttonLabel = isPreparing
        ? 'Preparing...'
        : isConnecting
            ? 'Redirecting to GitHub...'
            : 'Connect on GitHub';

    final buttonIcon = busy
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
            ),
          )
        : const Icon(Icons.login_rounded, size: 18);

    final helperText = isPreparing
        ? 'Building your first GitWall preview.'
        : isConnecting
            ? 'Launching secure GitHub OAuth.'
            : 'Secure GitHub OAuth. Sync first, preview next, apply after.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withValues(alpha: 0.86),
                scheme.surfaceContainerHigh.withValues(alpha: 0.74),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 3,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: AppTheme.durationNormal,
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: busy
                      ? null
                      : LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            accent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: busy ? accent.withValues(alpha: 0.42) : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: busy
                      ? null
                      : [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                ),
                child: FilledButton.icon(
                  onPressed: busy ? null : onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.78),
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ).copyWith(
                    overlayColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  icon: buttonIcon,
                  label: Text(buttonLabel),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: AppTheme.durationNormal,
                child: Row(
                  key: ValueKey<String>(helperText),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPreparing
                          ? Icons.sync_rounded
                          : isConnecting
                              ? Icons.open_in_new_rounded
                              : Icons.lock_outline_rounded,
                      size: 14,
                      color: scheme.onSurface.withValues(alpha: 0.58),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        helperText,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow.withValues(alpha: 0.92),
            scheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -70,
            top: -80,
            child: _BackdropGlow(
              size: 220,
              color: accent.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: -90,
            top: 120,
            child: _BackdropGlow(
              size: 260,
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _BackdropPainter(accent: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.045)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.64,
        size.width * 0.42,
        size.height * 0.78,
        size.width * 0.62,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.62,
        size.width * 0.88,
        size.height * 0.42,
        size.width * 0.94,
        size.height * 0.24,
      );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
