import 'package:flutter/material.dart';
import 'dart:async';

import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';
import 'package:github_wallpaper/features/membership/controllers/membership_controller.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/membership/services/membership_service.dart';
import 'package:github_wallpaper/features/membership/services/revenuecat_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/widget_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature-benefit model
// ─────────────────────────────────────────────────────────────────────────────
class _ProFeature {
  const _ProFeature({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.gradient,
  });
  final IconData icon;
  final String title;
  final String tagline;
  final List<Color> gradient;
}

final _proFeatures = <_ProFeature>[
  _ProFeature(
    icon: Icons.palette_rounded,
    title: 'Premium Themes',
    tagline: 'Dracula, Nord, Solarized & more — unlock every curated palette.',
    gradient: [const Color(0xFF9D50E0), const Color(0xFF6E4CF6)],
  ),
  _ProFeature(
    icon: Icons.auto_awesome_rounded,
    title: 'AI Quote Generation',
    tagline:
        'Fresh, personalised GitHub phrases auto-generated as your wallpaper subtitle.',
    gradient: [const Color(0xFFFF8C00), const Color(0xFFFF5F00)],
  ),
  _ProFeature(
    icon: Icons.bar_chart_rounded,
    title: 'Advanced Stats',
    tagline:
        'Language breakdown, per-repo activity, streak heatmaps — all on your lock screen.',
    gradient: [const Color(0xFF0969DA), const Color(0xFF344BCF)],
  ),
  _ProFeature(
    icon: Icons.calendar_month_rounded,
    title: 'GitWall Wrapped',
    tagline:
        'Your annual GitHub highlights packaged into a beautiful shareable card.',
    gradient: [const Color(0xFF1F883D), const Color(0xFF0D6A2E)],
  ),
  _ProFeature(
    icon: Icons.share_rounded,
    title: 'Watermark-Free Sharing',
    tagline: 'Share wallpaper cards publicly without the GitWall branding.',
    gradient: [const Color(0xFF0A7EA4), const Color(0xFF0969DA)],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class MembershipPaywallPage extends StatefulWidget {
  final String? featureName;
  final String? featureDescription;

  const MembershipPaywallPage({
    super.key,
    this.featureName,
    this.featureDescription,
  });

  @override
  State<MembershipPaywallPage> createState() => _MembershipPaywallPageState();
}

class _MembershipPaywallPageState extends State<MembershipPaywallPage>
    with SingleTickerProviderStateMixin {
  // ── state ─────────────────────────────────────────────────────────────────
  bool _isWorking = false;
  bool _isLoadingBilling = false;
  bool _animateIn = false;
  Offering? _currentOffering;
  EntitlementInfo? _activeProEntitlement;
  String? _managementUrl;

  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  // ── computed ──────────────────────────────────────────────────────────────
  bool get _billingAvailable => RevenueCatService.isAvailable;
  bool get _hasStoreManagedPro => _activeProEntitlement?.isActive == true;

  Package? get _primaryPackage {
    final packages = _currentOffering?.availablePackages ?? const <Package>[];
    for (final p in packages) {
      if (p.packageType == PackageType.monthly) return p;
    }
    return packages.isEmpty ? null : packages.first;
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    _loadBillingState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateIn = true);
      _heroCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  // ── billing ───────────────────────────────────────────────────────────────
  Future<void> _loadBillingState({
    bool silent = false,
    CustomerInfo? seededCustomerInfo,
  }) async {
    if (!_billingAvailable) return;
    if (!silent && mounted) setState(() => _isLoadingBilling = true);
    try {
      await RevenueCatService.initializeForCurrentUser();
      final offerings = await RevenueCatService.getOfferings();
      final customerInfo =
          seededCustomerInfo ?? await RevenueCatService.getCustomerInfo();
      final entitlement = await RevenueCatService.getActiveProEntitlement(
        customerInfo: customerInfo,
      );
      if (!mounted) return;
      setState(() {
        _currentOffering = offerings?.current;
        _activeProEntitlement = entitlement;
        _managementUrl = customerInfo?.managementURL?.trim();
      });
    } finally {
      if (mounted) setState(() => _isLoadingBilling = false);
    }
  }

  Future<void> _applyMembershipChange(
    Future<MembershipInfo> Function() action, {
    String? successMessage,
    bool popOnSuccess = false,
  }) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final info = await action();
      await _syncReminderState(info);
      if (!mounted) return;
      context.read<MembershipController>().setMembershipInfo(info);
      unawaited(WidgetService.refreshFromCache());
      if (successMessage != null && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (popOnSuccess) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message =
          error is StateError && error.message.toString().trim().isNotEmpty
              ? error.message.toString()
              : AppStrings.errorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _syncReminderState(MembershipInfo info) async {
    if (info.hasProAccess ||
        BackgroundScheduler.shouldScheduleReminderChecks()) {
      await BackgroundScheduler.scheduleStreakReminders();
      return;
    }
    await BackgroundScheduler.cancelStreakReminders();
  }

  Future<void> _purchasePrimaryPlan() async {
    final package = _primaryPackage;
    if (package == null) return;
    await _applyMembershipChange(
      () async {
        final customerInfo = await RevenueCatService.purchasePackage(package);
        await _loadBillingState(
          silent: true,
          seededCustomerInfo: customerInfo,
        );
        return MembershipService.refresh(
          force: true,
          revenueCatCustomerInfo: customerInfo,
        );
      },
      successMessage: 'Pro unlocked! Enjoy all features.',
      popOnSuccess: true,
    );
  }

  Future<void> _restorePurchases() async {
    await _applyMembershipChange(
      () async {
        final customerInfo = await RevenueCatService.restorePurchases();
        await _loadBillingState(
          silent: true,
          seededCustomerInfo: customerInfo,
        );
        return MembershipService.refresh(
          force: true,
          revenueCatCustomerInfo: customerInfo,
        );
      },
      successMessage: 'Pro access restored from Google Play.',
      popOnSuccess: true,
    );
  }

  Future<void> _manageSubscription() async {
    final urlString = _managementUrl?.trim();
    final fallback = AppConfig.playStoreSubscriptionsUri;
    final uri = (urlString != null && urlString.isNotEmpty)
        ? Uri.tryParse(urlString)
        : fallback;
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String? _trialLabelFor(Package? package) {
    final billingPeriod =
        package?.storeProduct.defaultOption?.freePhase?.billingPeriod;
    if (billingPeriod == null) return null;
    final value = billingPeriod.value;
    if (value <= 0) return null;
    switch (billingPeriod.unit) {
      case PeriodUnit.day:
        return '$value day${value == 1 ? '' : 's'}';
      case PeriodUnit.week:
        final days = value * 7;
        return '$days day${days == 1 ? '' : 's'}';
      case PeriodUnit.month:
        return '$value month${value == 1 ? '' : 's'}';
      case PeriodUnit.year:
        return '$value year${value == 1 ? '' : 's'}';
      case PeriodUnit.unknown:
        return null;
    }
  }

  String _billingCadenceLabel(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'month';
      case PackageType.weekly:
        return 'week';
      case PackageType.annual:
        return 'year';
      case PackageType.twoMonth:
        return '2 months';
      case PackageType.threeMonth:
        return '3 months';
      case PackageType.sixMonth:
        return '6 months';
      case PackageType.lifetime:
        return 'lifetime';
      case PackageType.custom:
      case PackageType.unknown:
        final period = package.storeProduct.subscriptionPeriod?.trim();
        if (period == null || period.isEmpty) return 'billing period';
        return period;
    }
  }

  String _heroTitle() {
    if (_hasStoreManagedPro) {
      return _activeProEntitlement?.periodType == PeriodType.trial
          ? 'Your trial is running'
          : 'Pro is active';
    }
    if (_trialLabelFor(_primaryPackage) != null) return 'Try Pro free';
    final locked = widget.featureName?.trim();
    if (locked != null && locked.isNotEmpty) return 'Unlock $locked';
    return 'Unlock GitWall Pro';
  }

  String _heroSubtitle() {
    if (_hasStoreManagedPro) {
      return _activeProEntitlement?.periodType == PeriodType.trial
          ? 'All Pro features are unlocked during your active trial.'
          : 'Your Google Play subscription is active and unlocking everything.';
    }
    final desc = widget.featureDescription?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    return 'Premium themes, AI quotes, advanced stats and more — one plan unlocks it all.';
  }

  String _purchaseCtaLabel(Package package) =>
      _trialLabelFor(package) == null ? 'Get Pro now' : 'Start free trial';

  // ── staggered entrance ────────────────────────────────────────────────────
  Widget _entrance({required int step, required Widget child}) {
    final delay = step * 55;
    final dur = Duration(milliseconds: 320 + delay);
    return AnimatedSlide(
      duration: dur,
      curve: Curves.easeOutCubic,
      offset: _animateIn ? Offset.zero : const Offset(0, 0.07),
      child: AnimatedOpacity(
        duration: dur,
        curve: Curves.easeOut,
        opacity: _animateIn ? 1.0 : 0.0,
        child: child,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────────────────────────────────────────

  /// Animated mesh-gradient hero header.
  Widget _buildHeroHeader(ColorScheme scheme, bool isDark) {
    final tt = Theme.of(context).textTheme;
    // Deep GitHub-blue gradient with a subtle violet shimmer
    final gradTop = isDark ? const Color(0xFF0A1628) : const Color(0xFF0969DA);
    final gradMid = isDark ? const Color(0xFF0D2340) : const Color(0xFF1A4FA3);
    final gradBot = isDark ? const Color(0xFF122040) : const Color(0xFF344BCF);

    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [gradTop, gradMid, gradBot],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles in background
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: -20,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentViolet.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pro badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentViolet.withValues(alpha: 0.35),
                            AppTheme.accentViolet.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.accentViolet.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GITWALL PRO',
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Icon ring
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Headline
                    Text(
                      _heroTitle(),
                      textAlign: TextAlign.center,
                      style: tt.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle
                    Text(
                      _heroSubtitle(),
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Social proof strip
                    _buildSocialProof(tt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ★★★★★ social proof row
  Widget _buildSocialProof(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++) ...[
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
            if (i < 4) const SizedBox(width: 1),
          ],
          const SizedBox(width: 8),
          Text(
            'Loved by developers on GitHub',
            style: tt.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Single feature benefit tile.
  Widget _buildFeatureCard(
    _ProFeature feature,
    int index,
    ColorScheme scheme,
    bool isDark,
  ) {
    final tt = Theme.of(context).textTheme;
    return _entrance(
      step: index + 2,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? scheme.surface : Colors.white,
          borderRadius: AppTheme.brLarge,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gradient icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: feature.gradient,
                  ),
                  borderRadius: AppTheme.brMedium,
                  boxShadow: [
                    BoxShadow(
                      color: feature.gradient.first.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(feature.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      feature.tagline,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppTheme.successGreen.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pricing highlight card shown above the feature list.
  Widget _buildPricingCard(
    Package package,
    String? trialLabel,
    ColorScheme scheme,
    bool isDark,
  ) {
    final tt = Theme.of(context).textTheme;
    final price = package.storeProduct.priceString;
    final cadence = _billingCadenceLabel(package);

    return _entrance(
      step: 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A1628), const Color(0xFF0D2340)]
                : [AppTheme.primaryBlue, const Color(0xFF2160C4)],
          ),
          borderRadius: AppTheme.brXL,
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: isDark
              ? Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Price column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: tt.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ $cadence',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trialLabel != null
                          ? '$trialLabel free trial • then billed monthly'
                          : 'Billed monthly • Cancel anytime',
                      style: tt.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.70),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right-side badge
              if (trialLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: AppTheme.brLarge,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'FREE',
                        style: tt.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        trialLabel,
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppTheme.brMedium,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    'Cancel\nanytime',
                    textAlign: TextAlign.center,
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Managed subscription status card.
  Widget _buildManagedSubscriptionCard(
    ColorScheme scheme,
    bool isTrialActive,
    bool isDark,
  ) {
    final tt = Theme.of(context).textTheme;
    return _entrance(
      step: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? scheme.surface : Colors.white,
          borderRadius: AppTheme.brXL,
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.4 : 0.25),
          ),
          boxShadow:
              AppTheme.shadow(AppTheme.primaryBlue, blur: 16, opacity: 0.08),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.20),
                        AppTheme.primaryBlue.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: AppTheme.brMedium,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTrialActive ? 'Trial active' : 'Pro active',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isTrialActive
                            ? 'Your free trial is currently running.'
                            : 'Subscription is current & active.',
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.12),
                    borderRadius: AppTheme.brSmall,
                  ),
                  child: Text(
                    'ACTIVE',
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppTheme.brLarge,
              ),
              child: Text(
                isTrialActive
                    ? 'After the trial ends, Google Play continues the monthly subscription automatically unless you cancel before it ends.'
                    : 'Google Play and RevenueCat are unlocking every Pro feature for this account.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.brLarge,
                  ),
                ),
                onPressed: _isWorking ? null : _manageSubscription,
                icon: const Icon(Icons.subscriptions_rounded, size: 18),
                label: const Text('Manage Google Play subscription'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact error / info state card.
  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return _entrance(
      step: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppTheme.brXL,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onTap != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  /// Sticky bottom CTA bar.
  Widget _buildStickyCtaBar(
    Package package,
    String? trialLabel,
    ColorScheme scheme,
    bool isDark,
  ) {
    final tt = Theme.of(context).textTheme;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: _animateIn ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _animateIn ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? scheme.surface : Colors.white,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            14 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main CTA button
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.brLarge,
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isWorking ? null : _purchasePrimaryPlan,
                  child: _isWorking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _purchaseCtaLabel(package),
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Sub-label row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trialLabel != null
                        ? '$trialLabel free • then ${package.storeProduct.priceString}/${_billingCadenceLabel(package)} • Cancel anytime'
                        : '${package.storeProduct.priceString}/${_billingCadenceLabel(package)} • Secure checkout • Cancel anytime',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final package = _primaryPackage;
    final trialLabel = _trialLabelFor(package);
    final isTrialActive = _activeProEntitlement?.periodType == PeriodType.trial;
    final showStickyBar = _billingAvailable &&
        !_isLoadingBilling &&
        !_hasStoreManagedPro &&
        package != null;

    return Scaffold(
      backgroundColor:
          isDark ? scheme.surfaceContainerLowest : const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          // ── Main scrollable area ──────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero collapsing app bar
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _buildHeroHeader(scheme, isDark),
                  title: Text(
                    'GitWall Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  titlePadding:
                      const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                ),
              ),

              // ── Content area ─────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  showStickyBar ? 140 : 32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── State: billing unavailable ────────────────────────
                    if (!_billingAvailable)
                      _buildStateCard(
                        icon: Icons.block_rounded,
                        title: 'Google Play billing is unavailable',
                        body:
                            'RevenueCat purchases are only available on Android builds with Google Play Billing configured.',
                      )

                    // ── State: loading ────────────────────────────────────
                    else if (_isLoadingBilling)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      )

                    // ── State: already subscribed ─────────────────────────
                    else if (_hasStoreManagedPro)
                      _buildManagedSubscriptionCard(
                        scheme,
                        isTrialActive,
                        isDark,
                      )

                    // ── State: no package ─────────────────────────────────
                    else if (package == null)
                      _buildStateCard(
                        icon: Icons.storefront_outlined,
                        title: 'No live Pro plan found',
                        body:
                            'Connect a monthly package to the current RevenueCat offering so the purchase button appears here.',
                        actionLabel: 'Refresh billing',
                        onTap: _isWorking ? null : () => _loadBillingState(),
                      )

                    // ── State: show purchase UI ────────────────────────────
                    else ...[
                      // Pricing card
                      _buildPricingCard(package, trialLabel, scheme, isDark),

                      // Section header
                      _entrance(
                        step: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text(
                                'Everything in Pro',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.10),
                                  borderRadius: AppTheme.brSmall,
                                ),
                                child: Text(
                                  '${_proFeatures.length} features',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Feature cards
                      for (var i = 0; i < _proFeatures.length; i++)
                        _buildFeatureCard(
                          _proFeatures[i],
                          i,
                          scheme,
                          isDark,
                        ),
                    ],

                    // ── Footer ────────────────────────────────────────────
                    if (_billingAvailable &&
                        !_isLoadingBilling &&
                        !_hasStoreManagedPro)
                      _entrance(
                        step: _proFeatures.length + 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            children: [
                              Text(
                                trialLabel == null
                                    ? 'Subscription is billed through Google Play and can be cancelled at any time.'
                                    : 'Cancel before the trial ends and you will not be charged.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed:
                                    _isWorking ? null : _restorePurchases,
                                child: const Text('Restore purchase'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky bottom CTA ─────────────────────────────────────────────
          if (showStickyBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyCtaBar(package, trialLabel, scheme, isDark),
            ),
        ],
      ),
    );
  }
}
