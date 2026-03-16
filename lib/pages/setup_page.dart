import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/main_nav_page.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  static final Uri _tokenUri = Uri.parse(
      'https://github.com/settings/tokens/new?scopes=read:user&description=GitWall');

  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _tokenVisible = false;
  bool _instructionsExpanded = false;
  String? _errorMessage;
  String _loadingStatus = AppStrings.statusInitializing;

  // Progressive loading messages
  static const _loadingSteps = [
    AppStrings.statusInitializing,
    AppStrings.statusLoadingResources,
    AppStrings.statusSettingUp,
    AppStrings.statusAlmostReady,
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _openTokenPage() async {
    try {
      final ok =
          await launchUrl(_tokenUri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ErrorHandler.handle(context, Exception('launchUrl returned false'),
            userMessage:
                'Unable to open GitHub. Please visit github.com/settings/tokens');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handle(context, e,
          userMessage:
              'Unable to open GitHub. Please visit github.com/settings/tokens');
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingStatus = _loadingSteps[0];
    });

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      // Step 1 — Verify credentials against GitHub API
      _updateStatus(_loadingSteps[1]);
      await GitHubService.getContributions(
          username: username, token: token, forceRefresh: true);

      // Step 2 — Persist credentials
      _updateStatus(_loadingSteps[2]);
      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setHasAuthError(false);

      // Step 3 — Finalise onboarding
      _updateStatus(_loadingSteps[3]);
      await StorageService.setOnboardingComplete(true);
      await StorageService.setFirstLoginGreetingPending(true);
      if (!StorageService.getEarlyAccessShown()) {
        await StorageService.setEarlyAccessShown(true);
        await StorageService.setEarlyAccessCelebratePending(true);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
        _loadingStatus = _loadingSteps[0];
      });
    }
  }

  void _updateStatus(String status) {
    if (mounted) setState(() => _loadingStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: Stack(
        children: [
          // ── Ambient glows ───────────────────────────────────
          _GlowBlob(
              color: cs.primary.withValues(alpha: 0.07),
              top: -100,
              right: -100,
              size: 400),
          _GlowBlob(
              color: AppTheme.accentViolet.withValues(alpha: 0.04),
              bottom: -50,
              left: -100,
              size: 350),

          SafeArea(
            child: SingleChildScrollView(
              padding: AppTheme.pSymH24,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: textScale > 1.2
                            ? AppTheme.spacing40
                            : AppTheme.spacing60),

                    // ── Header ────────────────────────────────
                    _buildHeader(cs, textTheme),

                    AppTheme.h24,

                    // ── Trust pills ───────────────────────────
                    _buildTrustPills(cs),

                    AppTheme.h48,

                    // ── Form card ─────────────────────────────
                    _buildFormCard(cs, textTheme),

                    AppTheme.h32,

                    // ── Error ─────────────────────────────────
                    if (_errorMessage != null) _buildError(),

                    // ── CTA ───────────────────────────────────
                    _buildCta(cs),

                    AppTheme.h24,

                    // ── Security footer ───────────────────────
                    _buildSecurityFooter(cs, textTheme),

                    AppTheme.h40,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader(ColorScheme cs, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          padding: AppTheme.pAll20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface.withValues(alpha: 0.90),
            border: Border.all(color: cs.outline.withValues(alpha: 0.40)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(Icons.hub_outlined, color: cs.primary, size: 44),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        AppTheme.h20,
        Text(
          AppStrings.connectAccount,
          textAlign: TextAlign.center,
          style: (textTheme.displaySmall ?? const TextStyle(fontSize: 26))
              .copyWith(
            color: cs.onSurface,
            letterSpacing: -1.0,
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),
        AppTheme.h8,
        Text(
          AppStrings.setupSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTheme.fontBase,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }

  // ── TRUST PILLS ───────────────────────────────────────────
  Widget _buildTrustPills(ColorScheme cs) {
    final pills = [
      _TrustPill(
        icon: Icons.lock_rounded,
        title: 'Keystore encrypted',
        color: AppTheme.accentViolet,
      ),
      _TrustPill(
        icon: Icons.cloud_off_rounded,
        title: 'Never sent to server',
        color: AppTheme.primaryBlue,
      ),
      _TrustPill(
        icon: Icons.phone_android_rounded,
        title: 'Local only',
        color: AppTheme.successGreen,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: pills.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outline.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p.icon, size: 13, color: p.color),
              AppTheme.w6,
              Text(
                p.title,
                style: TextStyle(
                  fontSize: AppTheme.fontCaption,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        )
            .animate(delay: (300 + i * 60).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.08);
      }).toList(),
    );
  }

  // ── FORM CARD ─────────────────────────────────────────────
  Widget _buildFormCard(ColorScheme cs, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppTheme.brXXL,
        border:
            Border.all(color: cs.outline.withValues(alpha: 0.45), width: 1.5),
        boxShadow: AppTheme.shadow(cs.shadow, opacity: 0.08, blur: 30),
      ),
      padding: AppTheme.pAll24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProField(
            label: 'GITHUB USERNAME',
            controller: _usernameController,
            hint: 'octocat',
            icon: Icons.alternate_email_rounded,
            validator: isValidUsernameFormat,
          ),

          AppTheme.h28,

          _buildProField(
            label: 'PERSONAL ACCESS TOKEN',
            controller: _tokenController,
            hint: 'ghp_••••••••••••••••',
            icon: Icons.vpn_key_outlined,
            obscure: !_tokenVisible,
            validator: isValidTokenFormat,
            suffix: IconButton(
              icon: Icon(
                _tokenVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: cs.onSurface.withValues(alpha: 0.45),
                size: 20,
              ),
              onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
            ),
          ),

          AppTheme.h20,

          // ── Collapsible token instructions ────────────────
          GestureDetector(
            onTap: () =>
                setState(() => _instructionsExpanded = !_instructionsExpanded),
            child: Container(
              width: double.infinity,
              padding: AppTheme.pAll16,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.60),
                borderRadius: AppTheme.brLarge,
                border: Border.all(color: cs.outline.withValues(alpha: 0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row — always visible
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.55)),
                      AppTheme.w8,
                      Expanded(
                        child: Text(
                          'How to get a token',
                          style: TextStyle(
                            fontSize: AppTheme.fontBase,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface.withValues(alpha: 0.80),
                          ),
                        ),
                      ),
                      Icon(
                        _instructionsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ],
                  ),

                  // Expanded content
                  if (_instructionsExpanded) ...[
                    AppTheme.h12,
                    Text(
                      '1. GitHub → Settings → Developer settings\n'
                      '2. Personal access tokens → Tokens (classic)\n'
                      '3. Generate new token → scope: read:user\n'
                      '4. Copy once and paste above',
                      style: TextStyle(
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.72),
                        height: 1.55,
                      ),
                    ),
                    AppTheme.h12,
                    TextButton.icon(
                      onPressed: _isLoading ? null : _openTokenPage,
                      icon: Icon(Icons.open_in_new_rounded,
                          size: 14, color: cs.primary),
                      label: Text(
                        '${AppStrings.needToken}${AppStrings.createHere}',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: AppTheme.fontBase,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms)
        .slideY(begin: 0.10, curve: Curves.easeOutQuad);
  }

  // ── ERROR ─────────────────────────────────────────────────
  Widget _buildError() {
    return Padding(
      padding: AppTheme.pOnlyB24,
      child: Container(
        padding: AppTheme.pAll16,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.06),
          borderRadius: AppTheme.brLarge,
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.errorRed, size: 20),
            AppTheme.w12,
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: AppTheme.fontSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ).animate().shake(hz: 4, offset: const Offset(4, 0)),
    );
  }

  // ── CTA BUTTON ────────────────────────────────────────────
  Widget _buildCta(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.spacing48 + AppTheme.spacing8,
      child: FilledButton(
        onPressed: _isLoading ? null : _completeSetup,
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  ),
                  AppTheme.w12,
                  Text(
                    _loadingStatus,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTheme.fontBase,
                    ),
                  ),
                ],
              )
            : const Text(AppStrings.setupCta),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  // ── SECURITY FOOTER ───────────────────────────────────────
  Widget _buildSecurityFooter(ColorScheme cs, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined,
            color: cs.outline.withValues(alpha: 0.55),
            size: AppTheme.fontLarge),
        AppTheme.w8,
        Flexible(
          child: Text(
            AppStrings.setupSecurityNote,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  // ── FORM FIELD ────────────────────────────────────────────
  Widget _buildProField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withValues(alpha: 0.65),
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: AppTheme.fontLarge,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.40),
              fontSize: AppTheme.fontMedium,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// ── TRUST PILL DATA ───────────────────────────────────────────
class _TrustPill {
  final IconData icon;
  final String title;
  final Color color;
  const _TrustPill(
      {required this.icon, required this.title, required this.color});
}

// ── GLOW BLOB ─────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  final double size;

  const _GlowBlob({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
