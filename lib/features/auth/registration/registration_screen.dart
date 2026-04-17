import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controller/auth_controller.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../core/services/auth_service.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String tempToken;
  const RegistrationScreen(
      {super.key, required this.mobile, required this.tempToken});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 6570)), // Default 18 years
      firstDate: DateTime(1900),
      lastDate: yesterday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF064E3B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && mounted) {
        AppToast.show(context, next.error!, type: ToastType.error);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF333333);
    final inputBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable Content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: primaryTextColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                            SvgPicture.asset(
                              'assets/images/startGold.svg',
                              height: 85.h,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),

                        // Title
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'Personal Information',
                            style: GoogleFonts.lora(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 36.h),

                        // Full Name Field
                        _buildInputLabel('Full Name *', primaryTextColor),
                        SizedBox(height: 8.h),
                        _buildClassicTextField(
                          controller: _nameController,
                          hint: 'Enter Your Full Name',
                          bgColor: inputBgColor,
                          textColor: primaryTextColor,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            // Allow only letters and spaces — no special characters
                            FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z ]")),
                            // Capitalise first letter of every word
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              final text = newValue.text;
                              if (text.isEmpty) return newValue;
                              final capitalized = text.split(' ').map((word) {
                                if (word.isEmpty) return word;
                                return word[0].toUpperCase() + word.substring(1);
                              }).join(' ');
                              return newValue.copyWith(text: capitalized);
                            }),
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14.sp,
                              color: const Color(0xFFD97706),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Note: Enter full name exactly as on your PAN Card.',
                                style: GoogleFonts.lora(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.white54 : const Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),

                        // DOB Field
                        _buildInputLabel('Date of Birth *', primaryTextColor),
                        SizedBox(height: 8.h),
                        _buildClassicTextField(
                          controller: _dobController,
                          hint: 'DD/MM/YYYY',
                          bgColor: inputBgColor,
                          textColor: primaryTextColor,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          suffixIcon: Icon(Icons.calendar_today_rounded,
                              size: 20.sp,
                              color: primaryTextColor.withOpacity(0.5)),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),

                        SizedBox(height: 24.h),

                        // Email Field
                        _buildInputLabel('E-Mail *', primaryTextColor),
                        SizedBox(height: 8.h),
                        _buildClassicTextField(
                          controller: _emailController,
                          hint: 'Enter Your E-Mail',
                          bgColor: inputBgColor,
                          textColor: primaryTextColor,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'E-Mail is required';
                            }
                            // RFC-compliant email pattern
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Enter a valid e-mail address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 24.h),

                        // Referral Field
                        _buildInputLabel(
                            'Referral Code (Optional)', primaryTextColor),
                        SizedBox(height: 8.h),
                        _buildClassicTextField(
                          controller: _referralController,
                          hint: 'Enter Referral Code',
                          bgColor: inputBgColor,
                          textColor: primaryTextColor,
                          textCapitalization: TextCapitalization.characters,
                        ),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Pinned Footer ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 28.h),
              child: FadeInAnimation(
                delay: const Duration(milliseconds: 400),
                child: CustomButton(
                  text: 'Confirm',
                  isLoading: authState.isLoading,
                  onPressed: _handleRegistration,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1B882C), Color(0xFF003716)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8F4C05).withOpacity(0.06),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                  textColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.lora(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _buildClassicTextField({
    required TextEditingController controller,
    required String hint,
    required Color bgColor,
    required Color textColor,
    TextInputType? keyboardType,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textAlign: textAlign,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: GoogleFonts.lora(
            fontSize: 16.sp, color: textColor.withOpacity(0.6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: bgColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: textColor.withOpacity(0.3), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.mpinCreation,
          arguments: {
            'fullName': _nameController.text,
            'mobile': widget.mobile,
            'email': _emailController.text,
            'dob': _dobController.text,
            'referralCode': _referralController.text,
            'tempToken': widget.tempToken,
          },
        );
      }
    }
  }
}
