import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/auth_controller.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String mobile;
  const RegistrationScreen({super.key, required this.mobile});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(height: 32.h),
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Complete Your\nProfile',
                        style: GoogleFonts.outfit(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.05,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Join the elite circle of smart investors.',
                        style: GoogleFonts.outfit(
                          fontSize: 17.sp,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                      delay: 300,
                    ),
                    SizedBox(height: 24.h),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Age is required';
                        final age = int.tryParse(v);
                        if (age == null || age < 18) {
                          return 'Must be 18 or older';
                        }
                        return null;
                      },
                      delay: 400,
                    ),
                    if (authState.error != null)
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: Center(
                          child: Text(authState.error!,
                              style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    const Spacer(),
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 500),
                      child: CustomButton(
                        text: 'Continue to Secure PIN',
                        isLoading: authState.isLoading,
                        onPressed: _handleRegistration,
                        backgroundColor: AppTheme.arcticBlue,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required int delay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInAnimation(
      delay: Duration(milliseconds: delay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 10.h),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20.sp, color: AppTheme.arcticBlue),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: const BorderSide(color: AppTheme.arcticBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).register(
            mobile: widget.mobile,
            name: _nameController.text,
            age: int.parse(_ageController.text),
          );

      if (success && mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.home,
          arguments: {'mobile': widget.mobile},
        );
      }else{
        // else part test purpose only
            Navigator.pushReplacementNamed(
          context,
          AppRouter.home,
          arguments: {'mobile': widget.mobile},
        );
      }
    }
  }
}
