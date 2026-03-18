import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/features/support/enquiry_service.dart';
import 'package:sip/shared/theme/app_theme.dart';
import 'package:sip/shared/widgets/animations.dart';

class EnquiryFormScreen extends ConsumerStatefulWidget {
  const EnquiryFormScreen({super.key});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'GENERAL';
  bool _isLoading = false;

  final List<String> _categories = ['PAYMENT', 'TECHNICAL', 'GENERAL', 'ACCOUNT'];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref.read(enquiryServiceProvider).submitEnquiry(
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
            category: _selectedCategory,
          );

      if (response['success'] == true && mounted) {
        ref.invalidate(enquiriesProvider);
        _showSuccessDialog(response['message'] ?? 'Enquiry submitted successfully');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Icon(Icons.check_circle_rounded, color: AppTheme.electricCyan, size: 48.sp),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 16.sp, height: 1.5),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to listing or support
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.arcticBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Great!', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('New Enquiry', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Category'),
              _buildCategorySelector(isDark),
              SizedBox(height: 24.h),
              _buildLabel('Subject'),
              _buildTextField(
                controller: _subjectController,
                hint: 'Briefly describe your issue',
                isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Subject is required' : null,
              ),
              SizedBox(height: 24.h),
              _buildLabel('Message'),
              _buildTextField(
                controller: _messageController,
                hint: 'Provide details about your query',
                isDark: isDark,
                maxLines: 6,
                validator: (v) => v!.isEmpty ? 'Message is required' : null,
              ),
              SizedBox(height: 48.h),
              FadeInAnimation(
                delay: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.arcticBlue,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Enquiry',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppTheme.arcticBlue,
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat, style: GoogleFonts.outfit(fontSize: 15.sp)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppTheme.arcticBlue, width: 2),
        ),
      ),
    );
  }
}
