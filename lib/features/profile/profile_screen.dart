import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/security/secure_storage_service.dart';
import '../../routes/app_router.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/custom_button.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isMpinEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _checkMpinStatus();
  }

  Future<void> _checkMpinStatus() async {
    final enabled = await SecureStorageService.isMpinEnabled();
    if (mounted) {
      setState(() {
        _isMpinEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, state, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    _buildKycStatus(isDark),
                    SizedBox(height: 32.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Personal Information', isDark),
                        if (!state.isEditing)
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: AppTheme.arcticBlue, size: 22.sp),
                            onPressed: () {
                              _nameController.text = state.user.name;
                              _emailController.text = state.user.email;
                              ref.read(profileProvider.notifier).setEditing(true);
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildEditableField(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      controller: _nameController,
                      isEditable: state.isEditing,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    _buildEditableField(
                      icon: Icons.alternate_email,
                      label: 'Email Address',
                      controller: _emailController,
                      isEditable: state.isEditing,
                      isDark: isDark,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email cannot be empty';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildReadOnlyField(
                      Icons.phone_iphone,
                      'Mobile Number',
                      state.user.phone,
                      isDark,
                    ),
                    if (state.isEditing) ...[
                      SizedBox(height: 32.h),
                      if (state.error != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Text(
                            state.error!,
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent, fontSize: 13.sp),
                          ),
                        ),
                      CustomButton(
                        text: 'Update Profile',
                        isLoading: state.isLoading,
                        onPressed: _handleUpdate,
                        backgroundColor: AppTheme.arcticBlue,
                      ),
                      SizedBox(height: 12.h),
                      Center(
                        child: TextButton(
                          onPressed: state.isLoading
                              ? null
                              : () => ref
                                  .read(profileProvider.notifier)
                                  .setEditing(false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                                color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 32.h),
                    _buildSectionTitle('Security & Privacy', isDark),
                    SizedBox(height: 16.h),
                    _buildMpinTile(_isMpinEnabled, isDark),
                    _buildProfileTile(Icons.fingerprint, 'Biometric Login',
                        'Enabled', isDark,
                        isAction: true),
                    _buildProfileTile(Icons.description_outlined,
                        'KYC Documents', 'Verified', isDark,
                        isAction: true),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Icon(icon,
                color: isDark ? Colors.white38 : Colors.black38, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black38)),
                if (isEditable)
                  TextFormField(
                    controller: controller,
                    validator: validator,
                    autofocus: true,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      border: InputBorder.none,
                      hintText: 'Enter $label',
                      hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                  )
                else
                  Text(controller.text,
                      style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
      IconData icon, String title, String value, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isDark ? Colors.white12 : Colors.black12, size: 22.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white24 : Colors.black26)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 16.sp, color: Colors.grey.withOpacity(0.3)),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(profileProvider.notifier).updateProfile(
            name: _nameController.text,
            email: _emailController.text,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  Widget _buildSliverAppBar(BuildContext context, ProfileState state, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240.h,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black, size: 20.sp),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.arcticBlue.withOpacity(0.8),
                    AppTheme.auroraPurple.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                          state.user.name.substring(0, 2).toUpperCase(),
                          style: GoogleFonts.outfit(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.arcticBlue)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    state.user.name,
                    style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  Text(
                    'Investor ID: #A98765',
                    style: GoogleFonts.outfit(
                        fontSize: 14.sp, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycStatus(bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.electricCyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppTheme.electricCyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: AppTheme.electricCyan, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KYC Verified',
                      style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.electricCyan)),
                  Text('Your account is fully compliant and secure.',
                      style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.arcticBlue),
    );
  }

  Widget _buildMpinTile(bool isEnabled, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: isDark ? Colors.white38 : Colors.black38, size: 22.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enable MPIN',
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black38)),
                Text(isEnabled ? 'Active' : 'Not Set',
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) async {
              if (value) {
                final result =
                    await Navigator.pushNamed(context, AppRouter.mpinCreation);
                if (result == true) _checkMpinStatus();
              } else {
                await SecureStorageService.setMpinEnabled(false);
                _checkMpinStatus();
              }
            },
            activeColor: AppTheme.arcticBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
      IconData icon, String title, String value, bool isDark,
      {bool isAction = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isDark ? Colors.white38 : Colors.black38, size: 22.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black38)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          if (isAction)
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }
}
