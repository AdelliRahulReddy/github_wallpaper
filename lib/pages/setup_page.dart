import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/main_nav_page.dart';
import 'package:github_wallpaper/app_utils.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _tokenVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      await GitHubService.getContributions(
          username: username, token: token, forceRefresh: true);

      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setOnboardingComplete(true);

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: Stack(
        children: [
          // Softer Ambient Tints
          _GlowBlob(
            color: cs.primary.withValues(alpha: 0.08),
            top: -100,
            right: -100,
            size: 400,
          ),
          _GlowBlob(
            color: AppTheme.primaryBrandAccent.withValues(alpha: 0.04),
            bottom: -50,
            left: -100,
            size: 350,
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacing60),

                    // Clean Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.surface.withValues(alpha: 0.85),
                              border: Border.all(
                                color: cs.outline.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(alpha: 0.08),
                                  blurRadius: AppTheme.spacing40,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Icon(Icons.hub_outlined,
                                color: cs.primary, size: 48),
                          ).animate().scale(
                              duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          Text('Connect Account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: AppTheme.fontHeadline,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                      letterSpacing: -0.5))
                              .animate()
                              .fadeIn()
                              .slideY(begin: 0.2),
                          const SizedBox(height: 8),
                          Text('Import your GitHub statistics',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: AppTheme.fontBase,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500))
                              .animate()
                              .fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing48),

                    // Refined Light Glass Card
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacing24),
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
                          const SizedBox(height: 32),
                          _buildProField(
                            label: 'ACCESS TOKEN',
                            controller: _tokenController,
                            hint: 'ghp_...',
                            icon: Icons.vpn_key_outlined,
                            obscure: !_tokenVisible,
                            validator: isValidTokenFormat,
                            suffix: IconButton(
                              icon: Icon(
                                  _tokenVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                  size: 20),
                              onPressed: () => setState(
                                  () => _tokenVisible = !_tokenVisible),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutQuad),

                    const SizedBox(height: AppTheme.spacing40),

                    // Dynamic Error
                    if (_errorMessage != null)
                      Container(
                        margin:
                            const EdgeInsets.only(bottom: AppTheme.spacing24),
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                              color: AppTheme.errorRed.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.errorRed,
                                      fontSize: AppTheme.fontSmall,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ).animate().shake(),

                    // Primary Action
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.spacing60,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _completeSetup,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge)),
                          elevation: 4,
                          shadowColor: cs.primary.withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: cs.onPrimary,
                                ))
                            : const Text('Initialize Workspace',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: AppTheme.fontLarge,
                                    letterSpacing: 0.5)),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: AppTheme.spacing32),

                    // Footer security info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            color: cs.outline.withValues(alpha: 0.6),
                            size: AppTheme.fontLarge),
                        const SizedBox(width: AppTheme.spacing8),
                        Text('Secure local-only authentication',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.45),
                                fontSize: AppTheme.fontCaption,
                                fontWeight: FontWeight.w500)),
                      ],
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: AppTheme.spacing40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        Text(label,
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w800,
                fontSize: AppTheme.fontCaption,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(
              color: cs.onSurface,
              fontSize: AppTheme.fontMedium,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
            prefixIcon: Icon(icon,
                color: cs.onSurface.withValues(alpha: 0.55), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing20 - 2),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide:
                    BorderSide(color: cs.outline.withValues(alpha: 0.45))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(
                    color: cs.primary.withValues(alpha: 0.4), width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide(
                    color: AppTheme.errorRed.withValues(alpha: 0.2))),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  final double size;

  const _GlowBlob(
      {required this.color,
      this.top,
      this.bottom,
      this.left,
      this.right,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size / 2,
              spreadRadius: size / 4,
            )
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
          begin: const Offset(-20, -20),
          end: const Offset(20, 20),
          duration: 5.seconds,
          curve: Curves.easeInOut),
    );
  }
}
