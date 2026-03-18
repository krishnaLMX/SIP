import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../routes/app_router.dart';
import 'profile_controller.dart';
import 'widgets/profile_photo_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _addressController = TextEditingController(text: user.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await ref.read(profileProvider.notifier).updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          address: _addressController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.electricCyan,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handlePhotoUpdate(File photo) async {
    final success =
        await ref.read(profileProvider.notifier).updateProfilePhoto(photo);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo updated successfully',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.electricCyan,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;

    // Listen for state changes to update controllers when data is fetched
    ref.listen(profileProvider, (previous, next) {
      if (!next.isEditing && (previous == null || previous.user != next.user)) {
        _nameController.text = next.user.name;
        _emailController.text = next.user.email;
        _addressController.text = next.user.address;
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: profileState.isLoading && user.name == 'Investor'
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.arcticBlue))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, isDark, user, profileState),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                            TextButton.icon(
                              onPressed: () {
                                ref
                                    .read(profileProvider.notifier)
                                    .setEditing(!profileState.isEditing);
                                if (!profileState.isEditing) {
                                  // Reset controllers when entering edit mode to ensure sync
                                  _nameController.text = user.name;
                                  _emailController.text = user.email;
                                  _addressController.text = user.address;
                                }
                              },
                              icon: Icon(
                                profileState.isEditing
                                    ? Icons.close
                                    : Icons.edit_note,
                                size: 18.sp,
                                color: AppTheme.arcticBlue,
                              ),
                              label: Text(
                                profileState.isEditing ? 'Cancel' : 'Edit',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.arcticBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildProfileTile(
                          Icons.person_outline,
                          'Full Name',
                          user.name,
                          isDark,
                          isEditing: profileState.isEditing,
                          controller: _nameController,
                        ),
                        _buildProfileTile(
                          Icons.alternate_email,
                          'Email Address',
                          user.email,
                          isDark,
                          isEditing: profileState.isEditing,
                          controller: _emailController,
                        ),
                        _buildProfileTile(
                          Icons.location_on_outlined,
                          'Residential Address',
                          user.address,
                          isDark,
                          isEditing: profileState.isEditing,
                          controller: _addressController,
                          maxLines: 3,
                        ),
                        _buildProfileTile(
                          Icons.phone_iphone,
                          'Mobile Number',
                          user.phone,
                          isDark,
                          isReadOnly: true,
                        ),
                        if (profileState.isEditing) ...[
                          SizedBox(height: 24.h),
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 100),
                            child: ElevatedButton(
                              onPressed:
                                  profileState.isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.arcticBlue,
                                minimumSize: Size(double.infinity, 56.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: profileState.isLoading
                                  ? SizedBox(
                                      height: 24.h,
                                      width: 24.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Apply Changes',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          if (profileState.error != null)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: Text(
                                profileState.error!,
                                style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                        SizedBox(height: 32.h),
                        _buildSectionTitle('Security & Privacy', isDark),
                        SizedBox(height: 16.h),
                        _buildProfileTile(
                          Icons.lock_outline,
                          'Change MPIN',
                          'Last updated 2 days ago',
                          isDark,
                          isAction: true,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.settings),
                        ),
                        _buildProfileTile(Icons.fingerprint, 'Biometric Login',
                            'Enabled', isDark,
                            isAction: true),
                        _buildProfileTile(Icons.description_outlined,
                            'KYC Documents', 'Verified', isDark,
                            isAction: true),
                        SizedBox(height: 120.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, bool isDark, UserProfile user, ProfileState state) {
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
                  ProfilePhotoWidget(
                    initialPhotoUrl: user.photoUrl,
                    initials: user.name.isNotEmpty
                        ? user.name
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join('')
                            .toUpperCase()
                        : '??',
                    onPhotoSelected: _handlePhotoUpdate,
                    isLoading: state.isPhotoLoading,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  Text(
                    'Investor ID: #${user.id}',
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

  Widget _buildProfileTile(
      IconData icon, String title, String value, bool isDark,
      {bool isAction = false,
      VoidCallback? onTap,
      bool isEditing = false,
      bool isReadOnly = false,
      int? maxLines,
      TextEditingController? controller}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isEditing && !isReadOnly
            ? (isDark
                ? AppTheme.arcticBlue.withOpacity(0.08)
                : AppTheme.arcticBlue.withOpacity(0.03))
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isEditing && !isReadOnly
              ? AppTheme.arcticBlue.withOpacity(0.4)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: isEditing && !isReadOnly ? 1.5 : 1.0,
        ),
        boxShadow: isEditing && !isReadOnly
            ? [
                BoxShadow(
                  color: AppTheme.arcticBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
                  if (isEditing && !isReadOnly && controller != null)
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: maxLines,
                      style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        border: InputBorder.none,
                        hintText: 'Enter $title',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        suffixIcon: Icon(
                          Icons.mode_edit_outline_outlined,
                          size: 16.sp,
                          color: AppTheme.arcticBlue.withOpacity(0.5),
                        ),
                        suffixIconConstraints: BoxConstraints(
                          minWidth: 24.w,
                          minHeight: 24.w,
                        ),
                      ),
                    )
                  else
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
      ),
    );
  }
}
