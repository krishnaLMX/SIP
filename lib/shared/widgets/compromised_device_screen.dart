import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompromisedDeviceScreen extends StatelessWidget {
  const CompromisedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 80.sp, color: Colors.redAccent),
            SizedBox(height: 32.h),
            Text(
              'Security Protocol Triggered',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'This application cannot run on a rooted or jailbroken device to ensure the safety of your assets and personal data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 48.h),
            const CircularProgressIndicator(color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
