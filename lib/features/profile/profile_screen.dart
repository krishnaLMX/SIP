import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../routes/app_router.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/masking_utils.dart';
import '../auth/controller/auth_controller.dart';
import '../main/main_screen.dart';
import 'profile_controller.dart' as pc;
import '../../shared/widgets/loaders.dart';
import '../../shared/widgets/app_toast.dart';

// ── App version provider ───────────────────────────────────────────────────
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'Version ${info.version} (${info.buildNumber})';
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await SecureStorageService.isBiometricEnabled();
    bool available = false;
    try {
      available = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _biometricAvailable = available;
      });
    }
  }

  Future<void> _onBiometricToggle(bool newValue) async {
    debugPrint('── Biometric Toggle: $newValue ──');
    if (newValue) {
      // Step 1: Verify identity with existing MPIN.
      debugPrint('  Step 1: Opening MPIN verify_only...');
      final verified = await Navigator.pushNamed(
        context,
        AppRouter.mpin,
        arguments: {'type': 'verify_only'},
      );
      debugPrint('  Step 1 result: verified=$verified');
      if (verified != true) {
        debugPrint('  ABORTED: MPIN not verified');
        return;
      }

      // Step 2: Confirm with actual biometric enrollment
      debugPrint('  Step 2: Prompting biometric enrollment...');
      try {
        final enrolled = await _localAuth.authenticate(
          localizedReason: 'Confirm biometrics to enable this feature',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        debugPrint('  Step 2 result: enrolled=$enrolled');
        if (!enrolled) {
          debugPrint('  ABORTED: Biometric enrollment rejected');
          return;
        }
      } catch (e) {
        debugPrint('  Step 2 ERROR: $e');
        return;
      }
    }

    debugPrint('  Step 3: Saving biometricEnabled=$newValue');
    await SecureStorageService.setBiometricEnabled(newValue);
    // Also persist the MPIN enabled flag so the flag stays correct
    if (newValue) await SecureStorageService.setMpinEnabled(true);
    if (mounted) setState(() => _biometricEnabled = newValue);

    final msg = newValue
        ? 'Biometric authentication enabled'
        : 'Biometric authentication disabled';
    final type = newValue ? ToastType.success : ToastType.info;
    if (mounted) AppToast.show(context, msg, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(pc.profileProvider);

    if (profileState.isLoading && profileState.user.name == 'Investor') {
      return AppLoaders.fullScreenLoader(context, isDark: isDark);
    }

    final user = profileState.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, user, isDark),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                      'Profile Settings',
                      [
                        _buildMenuItem(
                          'Account Details',
                          'assets/sidemenu/account.svg',
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.accountDetails),
                        ),
                        _buildMenuItem(
                          'Transaction History',
                          'assets/sidemenu/transhistory.svg',
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.transactionHistory),
                        ),
                        _buildMenuItem(
                          'KYC Verification',
                          'assets/sidemenu/kyc.svg',
                          onTap: () async {
                            if (user.kycStatus == 1) {
                              AppToast.show(
                                  context, 'Your KYC is already verified! ✓',
                                  type: ToastType.success);
                              return;
                            }
                            final result = await Navigator.pushNamed(
                                context, AppRouter.kyc,
                                arguments: {'request_from': 'profile'});
                            // Refresh profile to update the verified badge
                            if (result == true && mounted) {
                              ref
                                  .read(pc.profileProvider.notifier)
                                  .fetchProfileDetails();
                            }
                          },
                          trailing: user.kycStatus == 1
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E5723)
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(100.r),
                                    border: Border.all(
                                        color: const Color(0xFF0E5723)
                                            .withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_rounded,
                                          color: const Color(0xFF0E5723),
                                          size: 14.sp),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0E5723),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                        // Nominee Details - Commented as requested
                        /*
                    _buildMenuItem(
                      'Nominee Details',
                      'assets/sidemenu/nominee.svg',
                      onTap: () {},
                    ),
                    */
                        // Auto Savings - Commented as requested
                        /*
                    _buildMenuItem(
                      'Auto Savings',
                      'assets/sidemenu/autosaving.svg',
                      onTap: () {},
                    ),
                    */
                      ],
                      isDark),
                  SizedBox(height: 16.h),
                  _buildSection(
                      'General',
                      [
                        _buildMenuItem(
                          'Refer & Earn',
                          'assets/sidemenu/refer.svg',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.referral),
                        ),
                        _buildMenuItem(
                          'Privacy Policy',
                          'assets/sidemenu/privacy.svg',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.privacy),
                        ),
                        _buildMenuItem(
                          'Terms & Conditions',
                          'assets/sidemenu/tc.svg',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.terms),
                        ),
                        _buildMenuItem(
                          'Enquiry',
                          'assets/sidemenu/enquiry.svg',
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.enquiryList),
                        ),
                        _buildMenuItem(
                          'Help & Support',
                          'assets/sidemenu/help.svg',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.contact),
                        ),
                      ],
                      isDark),
                  SizedBox(height: 16.h),
                  _buildSection(
                      'Account',
                      [
                        // Biometrics Auth
                        if (_biometricAvailable)
                          _buildMenuItem(
                            'Biometric Authentication',
                            'assets/sidemenu/lock.svg',
                            onTap: () => _onBiometricToggle(!_biometricEnabled),
                            trailing: Switch(
                              value: _biometricEnabled,
                              onChanged: _onBiometricToggle,
                              activeColor: const Color(0xFF0E5723),
                            ),
                          ),

                        // Change MPIN

                        _buildMenuItem(
                          'Change MPIN',
                          'assets/sidemenu/mpin.svg',
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.changeMpin),
                        ),

                        _buildMenuItem(
                          'Logout',
                          'assets/sidemenu/logout.svg',
                          onTap: () => _handleLogout(context, ref),
                        ),
                        _buildMenuItem(
                          'Delete Account',
                          'assets/sidemenu/deleteacc.svg',
                          isDestructive: true,
                          onTap: () => _handleDeleteAccount(context),
                        ),
                      ],
                      isDark),
                  SizedBox(height: 32.h),
                  Center(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final versionAsync = ref.watch(appVersionProvider);
                        final label = versionAsync.when(
                          data: (v) => v,
                          loading: () => 'Version ...',
                          error: (_, __) => 'Version 1.0',
                        );
                        return Text(
                          label,
                          style: GoogleFonts.lora(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.87, -0.5),
          end: Alignment(0.87, 0.5),
          colors: [Color(0xFF003716), Color(0xFF167525)],
          stops: [0.0223, 0.9399],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nav row ─────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20.sp),
                    onPressed: () {
                      final routeName = ModalRoute.of(context)?.settings.name;
                      if (routeName == AppRouter.profile) {
                        Navigator.pop(context);
                      } else {
                        ref.read(selectedTabProvider.notifier).state = 0;
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w800,
                        fontSize: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // ── User info ───────────────────────────────────────────────
              Row(
                children: [
                  SizedBox(width: 8.w),
                  // Circular Progress Avatar
                  Builder(builder: (context) {
                    // Profile completion: 5 fields × 20% each
                    int filled = 0;
                    if (user.name.isNotEmpty) filled++;
                    if (user.phone.isNotEmpty) filled++;
                    if (user.dob.isNotEmpty) filled++;
                    if (user.kycStatus == 1) filled++;
                    if (user.pincode.isNotEmpty) filled++;
                    final completion = filled / 5.0;
                    final pct = (completion * 100).round();

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70.w,
                          height: 70.w,
                          child: CircularProgressIndicator(
                            value: completion,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFDE047)),
                          ),
                        ),
                        Container(
                          width: 58.w,
                          height: 58.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            image: user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(user.photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name
                                          .substring(
                                              0,
                                              user.name.length < 2
                                                  ? user.name.length
                                                  : 2)
                                          .toUpperCase()
                                      : 'AS',
                                  style: GoogleFonts.lora(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(7.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0E5723),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : '',
                          style: GoogleFonts.lora(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          MaskingUtils.maskMobile(user.phone),
                          style: GoogleFonts.lora(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildSection(String title, List<Widget> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(String title, String iconPath,
      {required VoidCallback onTap,
      bool isDestructive = false,
      Widget? trailing}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  padding: EdgeInsets.all(10.w),
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                        isDestructive ? Colors.red : const Color(0xFF0E5723),
                        BlendMode.srcIn),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          isDestructive ? Colors.red : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20.sp,
                      color: Colors.black26,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(selectedTabProvider.notifier).state = 0;
              ref.read(authControllerProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.login, (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    // Show a similar dialog for delete account if needed
  }
}
