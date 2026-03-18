import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sip/shared/theme/app_theme.dart';
import 'package:sip/features/kyc/controllers/kyc_controller.dart';
import 'package:sip/features/kyc/models/kyc_document.dart';
import 'package:sip/core/localization/language_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  final String requestFrom;
  final Map<String, dynamic>? extraData;

  const KycScreen({
    super.key,
    required this.requestFrom,
    this.extraData,
  });

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  KycDocumentType? _selectedDoc;
  final Map<String, TextEditingController> _controllers = {};
  XFile? _frontImage;
  XFile? _backImage;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDocSelected(KycDocumentType doc) {
    setState(() {
      _selectedDoc = doc;
      _frontImage = null;
      _backImage = null;
      _controllers.clear();
      for (var field in doc.fields) {
        _controllers[field.name] = TextEditingController();
      }
    });
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImage = image;
        } else {
          _backImage = image;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDoc == null) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoc!.images.front && _frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Front image is required')),
      );
      return;
    }

    if (_selectedDoc!.images.back && _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Back image is required')),
      );
      return;
    }

    final fields = _controllers.map((key, controller) => MapEntry(key, controller.text));

    await ref.read(kycSubmitProvider.notifier).submit(
          requestFrom: widget.requestFrom,
          documentId: _selectedDoc!.id,
          fields: fields,
          frontPath: _frontImage?.path,
          backPath: _backImage?.path,
        );

    final result = ref.read(kycSubmitProvider);
    if (result.hasValue && result.value == true) {
      if (mounted) {
        // Success navigation logic
        if (widget.requestFrom == 'instant') {
          Navigator.pushReplacementNamed(context, '/payment-methods', arguments: widget.extraData);
        } else {
          Navigator.pop(context, true);
        }
      }
    } else if (result.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docsAsync = ref.watch(kycDocumentsProvider(widget.requestFrom));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          ref.tr('kycVerification'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No documents available'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('selectDocumentType'),
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildDocSelector(docs, isDark),
                if (_selectedDoc != null) ...[
                  SizedBox(height: 32.h),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._selectedDoc!.fields.map((field) => _buildDynamicField(field, isDark)),
                        SizedBox(height: 24.h),
                        _buildImagePickers(isDark),
                      ],
                    ),
                  ),
                  SizedBox(height: 48.h),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _selectedDoc != null ? _buildFooter(isDark) : null,
    );
  }

  Widget _buildDocSelector(List<KycDocumentType> docs, bool isDark) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: docs.map((doc) {
        final isSelected = _selectedDoc?.id == doc.id;
        return GestureDetector(
          onTap: () => _onDocSelected(doc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.arcticBlue : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? AppTheme.arcticBlue : (isDark ? Colors.white10 : Colors.black12),
              ),
            ),
            child: Text(
              doc.name,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicField(KycField field, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _controllers[field.name],
            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (field.regex != null && field.regex!.isNotEmpty) {
                if (!RegExp(field.regex!).hasMatch(value)) {
                  return 'Invalid format';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickers(bool isDark) {
    return Row(
      children: [
        if (_selectedDoc!.images.front)
          Expanded(child: _buildImageCard('Front Side', _frontImage, true, isDark)),
        if (_selectedDoc!.images.back) ...[
          SizedBox(width: 16.w),
          Expanded(child: _buildImageCard('Back Side', _backImage, false, isDark)),
        ],
      ],
    );
  }

  Widget _buildImageCard(String label, XFile? image, bool isFront, bool isDark) {
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12, style: BorderStyle.solid),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(19.r),
                  child: Image.file(File(image.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppTheme.arcticBlue, size: 28.sp),
                    SizedBox(height: 8.h),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final submitState = ref.watch(kycSubmitProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: submitState.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.arcticBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          child: submitState.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Submit Verification'.toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
        ),
      ),
    );
  }
}
