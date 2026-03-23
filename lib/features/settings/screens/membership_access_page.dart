import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/membership_service.dart';
import 'package:github_wallpaper/shared/services/revenuecat_service.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum MembershipAccessAction {
  none,
  restorePurchase,
  redeemCoupon,
}

class MembershipAccessPage extends StatefulWidget {
  final MembershipAccessAction initialAction;

  const MembershipAccessPage({
    super.key,
    this.initialAction = MembershipAccessAction.none,
  });

  @override
  State<MembershipAccessPage> createState() => _MembershipAccessPageState();
}

class _MembershipAccessPageState extends State<MembershipAccessPage> {
  MembershipInfo? _membershipInfo;
  bool _isLoading = false;
  bool _isWorking = false;
  bool _didRunInitialAction = false;
  EntitlementInfo? _activeProEntitlement;
  String? _managementUrl;

  MembershipInfo get _info =>
      _membershipInfo ??
      context.read<MembershipState>().info ??
      StorageService.getCachedMembershipInfo() ??
      MembershipInfo.free();

  bool get _billingAvailable => RevenueCatService.isAvailable;
  bool get _hasStoreManagedPro => _activeProEntitlement?.isActive == true;
  bool get _isTrialActive => _activeProEntitlement?.periodType == PeriodType.trial;

  @override
  void initState() {
    super.initState();
    _membershipInfo = StorageService.getCachedMembershipInfo();
    _refreshPageState();
  }

  Future<void> _refreshPageState({bool forceMembershipRefresh = true}) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      CustomerInfo? customerInfo;
      if (_billingAvailable) {
        await RevenueCatService.initializeForCurrentUser();
        customerInfo = await RevenueCatService.getCustomerInfo();
      }

      final info =
          await MembershipService.refresh(force: forceMembershipRefresh);
      if (!mounted) return;

      context.read<MembershipState>().setMembershipInfo(info);
      setState(() {
        _membershipInfo = info;
        _activeProEntitlement =
            customerInfo == null
                ? null
                : customerInfo.entitlements.active[RevenueCatService.entitlementId];
        _managementUrl = customerInfo?.managementURL?.trim();
      });

      _runInitialActionIfNeeded();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _runInitialActionIfNeeded() {
    if (_didRunInitialAction ||
        widget.initialAction == MembershipAccessAction.none) {
      return;
    }
    _didRunInitialAction = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.initialAction) {
        case MembershipAccessAction.none:
          return;
        case MembershipAccessAction.restorePurchase:
          _restorePurchases();
        case MembershipAccessAction.redeemCoupon:
          _redeemCouponCode();
      }
    });
  }

  Future<void> _applyMembershipChange(
    Future<MembershipInfo> Function() action, {
    String? successMessage,
  }) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final info = await action();
      await _syncReminderState(info);
      if (!mounted) return;
      context.read<MembershipState>().setMembershipInfo(info);
      setState(() => _membershipInfo = info);
      if (successMessage != null && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (mounted) {
        setState(() => _isWorking = false);
      }
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

  Future<void> _restorePurchases() async {
    await _applyMembershipChange(
      () async {
        if (_billingAvailable) {
          await RevenueCatService.restorePurchases();
        }
        await _refreshPageState(forceMembershipRefresh: true);
        return MembershipService.refresh(force: true);
      },
      successMessage: 'Purchases restored from Google Play.',
    );
  }

  Future<void> _redeemCouponCode() async {
    String draftCode = '';
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Redeem coupon'),
        content: TextFormField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => draftCode = value,
          decoration: const InputDecoration(
            labelText: AppStrings.membershipCouponHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(draftCode),
            child: const Text(AppStrings.apply),
          ),
        ],
      ),
    );

    final normalizedCode = code?.trim().toUpperCase();
    if (normalizedCode == null || normalizedCode.isEmpty) return;

    await _applyMembershipChange(
      () => MembershipService.redeemCouponCode(normalizedCode),
      successMessage: AppStrings.membershipCouponApplied,
    );
    await _refreshPageState(forceMembershipRefresh: true);
  }

  Future<void> _manageGooglePlaySubscription() async {
    final urlString = _managementUrl?.trim();
    final fallback = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    final uri = (urlString != null && urlString.isNotEmpty)
        ? Uri.tryParse(urlString)
        : fallback;
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Play subscription management.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MembershipPaywallPage(),
      ),
    );
    if (!mounted) return;
    await _refreshPageState(forceMembershipRefresh: true);
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return AppStrings.unknown;
    return '${value.day}/${value.month}/${value.year}';
  }

  String _statusTitle(MembershipInfo info) {
    if (_hasStoreManagedPro) {
      return _isTrialActive ? 'Trial active' : 'Pro subscription active';
    }
    switch (info.plan) {
      case MembershipPlan.couponPro:
        return 'Coupon access active';
      case MembershipPlan.pro:
        return 'Waiting for subscription verification';
      case MembershipPlan.free:
        return 'Free plan active';
    }
  }

  String _statusBody(MembershipInfo info) {
    if (_hasStoreManagedPro) {
      return _isTrialActive
          ? 'Your free trial is active through Google Play. Pro stays unlocked until ${_dateLabel(info.proAccessExpiresAt)}.'
          : 'RevenueCat reports an active Google Play subscription, so every Pro feature is unlocked on this account.';
    }
    switch (info.plan) {
      case MembershipPlan.couponPro:
        return 'An admin coupon currently unlocks Pro until ${_dateLabel(info.proAccessExpiresAt)}.';
      case MembershipPlan.pro:
        return 'This device does not currently have an active RevenueCat entitlement, so the app is treating the account as Free until billing is verified again.';
      case MembershipPlan.free:
        return 'All Pro features stay visible, but they remain locked until you start the subscription or apply an admin coupon.';
    }
  }

  List<Color> _heroColors(MembershipInfo info) {
    switch (info.plan) {
      case MembershipPlan.couponPro:
        return const [AppTheme.successGreen, Color(0xFF2CA24C)];
      case MembershipPlan.pro:
        return const [AppTheme.primaryBlue, Color(0xFF0F6BBD)];
      case MembershipPlan.free:
        return const [Color(0xFF0F3D5E), AppTheme.primaryBlue];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = _info;
    final sourceLabel = _hasStoreManagedPro
        ? 'RevenueCat / Google Play'
        : info.isCouponAccess
            ? 'Admin coupon'
            : 'Free plan';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('Subscription Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: AppTheme.brXL,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _heroColors(info),
                ),
                boxShadow: AppTheme.shadow(
                  scheme.shadow,
                  blur: 24,
                  opacity: 0.10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PagePill(
                        label: sourceLabel,
                        foreground: Colors.white,
                        background: Colors.white.withValues(alpha: 0.14),
                      ),
                      const Spacer(),
                      if (_isLoading || _isWorking)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _statusTitle(info),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusBody(info),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _PagePill(
                        label: info.hasProAccess ? 'Unlocked' : 'Locked',
                        foreground: Colors.white,
                        background: Colors.white.withValues(alpha: 0.12),
                      ),
                      if (_isTrialActive)
                        _PagePill(
                          label: 'Free trial',
                          foreground: Colors.white,
                          background: Colors.white.withValues(alpha: 0.12),
                        ),
                      if (info.proAccessExpiresAt != null)
                        _PagePill(
                          label: 'Ends ${_dateLabel(info.proAccessExpiresAt)}',
                          foreground: Colors.white,
                          background: Colors.white.withValues(alpha: 0.12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (info.plan == MembershipPlan.free)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ready to unlock Pro?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the monthly plan with live Google Play pricing, or apply an admin-issued coupon if you have one.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isWorking ? null : _openPaywall,
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text('Upgrade to Pro'),
                      ),
                    ],
                  ),
                ),
              ),
            if (info.plan == MembershipPlan.free) const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Current plan', value: info.plan.value),
                    _DetailRow(label: 'Access source', value: sourceLabel),
                    _DetailRow(
                      label: 'Pro status',
                      value: info.hasProAccess ? 'Unlocked' : 'Locked',
                    ),
                    _DetailRow(
                      label: 'Coupon code',
                      value: info.couponCode ?? 'None',
                    ),
                    _DetailRow(
                      label: 'Expires',
                      value: info.proAccessExpiresAt == null
                          ? 'Not set'
                          : _dateLabel(info.proAccessExpiresAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ActionButton(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Upgrade to Pro',
                      subtitle:
                          'Open the paywall for the live monthly plan and any store-provided trial.',
                      onTap: _isWorking ? null : _openPaywall,
                    ),
                    _ActionButton(
                      icon: Icons.restore_rounded,
                      title: 'Restore Purchase',
                      subtitle:
                          'Re-check RevenueCat and Google Play after reinstalling or signing back in.',
                      onTap: _isWorking ? null : _restorePurchases,
                    ),
                    _ActionButton(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Redeem Coupon',
                      subtitle:
                          'Apply an admin-issued coupon to unlock Pro without a store subscription.',
                      onTap: _isWorking ? null : _redeemCouponCode,
                    ),
                    if (_hasStoreManagedPro)
                      _ActionButton(
                        icon: Icons.subscriptions_rounded,
                        title: 'Manage Google Play subscription',
                        subtitle:
                            'Open Google Play to cancel, pause, or review billing for this account.',
                        onTap:
                            _isWorking ? null : _manageGooglePlaySubscription,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagePill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _PagePill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppTheme.brLarge,
        child: InkWell(
          borderRadius: AppTheme.brLarge,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
