import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppLoaders {
  static Widget fullScreenLoader(BuildContext context, {bool isDark = false}) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : const Color(0xFF1B882C),
        ),
      ),
    );
  }

  static Widget sectionLoader({
    double height = 120,
    double width = double.infinity,
    bool isDark = false,
    double borderRadius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      highlightColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget headerShimmerBlock({
    double height = 80,
    double width = double.infinity,
    double borderRadius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.2),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget headerShimmerPill({
    double height = 24,
    double width = 80,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.2),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
