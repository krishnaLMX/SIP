import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/numeric_styled_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../routes/app_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../services/delete_account_service.dart';

// â”€â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final _deleteAccountServiceProvider =
    Provider<DeleteAccountService>((ref) => DeleteAccountService());

final _deleteInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(_deleteAccountServiceProvider).fetchDeleteInfo(),
);

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _isDeleting = false;

  // â”€â”€ Confirm deletion flow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _onConfirmTap() async {
    final confirmed = await _showConfirmationDialog();
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(_deleteAccountServiceProvider).confirmDelete();
      if (!mounted) return;
      await _clearAllData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppToast.show(
        context,
        msg.isNotEmpty ? msg : 'Account deletion failed. Please try again.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _clearAllData() async {
    // SecureStorage (tokens, MPIN, biometric flags, etc.)
    await SecureStorageService.logout();
    // SharedPreferences (language selection, etc.)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> _showConfirmationDialog() async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: Colors.black.withValues(alpha: 0.6),
          transitionDuration: const Duration(milliseconds: 280),
          transitionBuilder: (ctx, a1, a2, child) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: a1, child: child),
            );
          },
          pageBuilder: (ctx, _, __) => const _ConfirmDialog(),
        ) ??
        false;
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(_deleteInfoProvider);

    return Scaffold(
      // Transparent â†’ global AppTheme.lightGradient shows through (same as
      // WithdrawalScreen, ReferralScreen, etc.)
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // â”€â”€ Green gradient header â€” matches every other screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          GradientHeader(
            title: 'Delete Account',
            onBack: () => Navigator.pop(context),
          ),

          // â”€â”€ Page body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: infoAsync.when(
              data: (info) => _buildBody(info),
              loading: () => _buildSkeleton(),
              error: (e, _) => _buildError(e),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Main body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBody(Map<String, dynamic> info) {
    final content = info['content'] as String? ?? '';
    final isAllowed = info['is_allowed'] as bool? ?? false;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 14.h),

                // â”€â”€ Danger icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildDangerIcon(),

                SizedBox(height: 12.h),

                // â”€â”€ Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text(
                  'Permanently Delete Your Account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 8.h),

                // â”€â”€ Warning badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFDC2626),
                        size: 12.sp,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'This action is irreversible',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // â”€â”€ Content card from API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (content.isNotEmpty) _buildContentCard(content),

                SizedBox(height: 10.h),

                // â”€â”€ What will be deleted â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildDeletionList(),

                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),

        // â”€â”€ Pinned footer â€” only shown when is_allowed == true â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (isAllowed) _buildFooter(),
      ],
    );
  }

  // â”€â”€ Danger icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDangerIcon() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.delete_forever_rounded,
        color: const Color(0xFFDC2626),
        size: 28.sp,
      ),
    );
  }

  // â”€â”€ Content card from API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildContentCard(String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFFDC2626),
            size: 15.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: NumericStyledText(
              content,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4B5563),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ What will be deleted list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDeletionList() {
    final items = [
      (Icons.account_circle_outlined, 'Profile & Personal Data'),
      (Icons.account_balance_wallet_outlined, 'Portfolio & Holdings'),
      (Icons.history_rounded, 'Transaction History'),
      (Icons.card_giftcard_rounded, 'Referral Rewards'),
      (Icons.notifications_off_outlined, 'All Preferences & Settings'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Will Be Deleted',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 8.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 7.h),
              child: Row(
                children: [
                  Icon(
                    item.$1,
                    color: const Color(0xFFDC2626).withValues(alpha: 0.65),
                    size: 15.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    item.$2,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Pinned footer button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
        child: CustomButton(
          text: 'Delete My Account', svgIconPath: 'assets/buttons/tick.svg',
          isLoading: _isDeleting,
          loadingText: 'Deleting Account...',
          // Red gradient â€” matches the destructive action intent
          gradient: const LinearGradient(
            begin: Alignment(-0.87, -0.5),
            end: Alignment(0.87, 0.5),
            colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          onPressed: _isDeleting ? null : _onConfirmTap,
        ),
      ),
    );
  }

  // â”€â”€ Skeleton loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSkeleton() {
    final base = Colors.black.withValues(alpha: 0.05);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Center(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: base),
            ),
          ),
          SizedBox(height: 24.h),
          _shimmer(180.w, 22.h, base),
          SizedBox(height: 8.h),
          _shimmer(120.w, 16.h, base),
          SizedBox(height: 28.h),
          _shimmer(double.infinity, 140.h, base, r: 20.r),
          SizedBox(height: 16.h),
          _shimmer(double.infinity, 160.h, base, r: 20.r),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, Color c, {double? r}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(r ?? 10.r),
        ),
      );

  // â”€â”€ Error state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52.sp, color: Colors.black26),
            SizedBox(height: 16.h),
            Text(
              'Could not load information',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              e.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(fontSize: 13.sp, color: Colors.black38),
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () => ref.refresh(_deleteInfoProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.r),
                ),
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Confirmation Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(28.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: const Color(0xFFDC2626),
                size: 30.sp,
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Delete Account?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),

            SizedBox(height: 10.h),

            Text(
              'Are you sure you want to\ndelete your account?',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            SizedBox(height: 8.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'All data will be permanently erased\nand cannot be recovered.',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFDC2626),
                  height: 1.5,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Buttons
            Row(
              children: [
                // Cancel â€” neutral outlined
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.12)),
                      minimumSize: Size(0, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Confirm â€” red gradient matching footer button
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.87, -0.5),
                        end: Alignment(0.87, 0.5),
                        colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFDC2626).withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        minimumSize: Size(0, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                      child: Text(
                        'Yes, Delete',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
