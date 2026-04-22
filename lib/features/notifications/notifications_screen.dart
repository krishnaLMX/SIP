import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/notification_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/gradient_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // FCM is a trigger — always fetch fresh data from API on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(title: 'Notifications'),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen))
                : state.error != null
                    ? _buildError(state.error!, isDark)
                    : state.notifications.isEmpty
                        ? _buildEmpty(isDark)
                        : _buildList(state, isDark),
          ),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────

  Widget _buildList(NotificationState state, bool isDark) {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () => ref.read(notificationProvider.notifier).load(),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) =>
            _buildCard(state.notifications[index], isDark),
      ),
    );
  }

  Widget _buildCard(AppNotification notif, bool isDark) {
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTap: () {
        // Mark as read via API + optimistic UI update
        if (isUnread) {
          ref.read(notificationProvider.notifier).markAsRead(notif.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? AppTheme.primaryGreen.withOpacity(0.08)
                  : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isUnread
                ? AppTheme.primaryGreen.withOpacity(0.25)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _typeColor(notif.type).withOpacity(0.12),
                ),
                child: Icon(
                  _typeIcon(notif.type),
                  color: _typeColor(notif.type),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.lora(
                              fontSize: 13.sp,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notif.message,
                      style: GoogleFonts.lora(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      notif.createdAt,
                      style: GoogleFonts.lora(
                        fontSize: 10.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty / Error ─────────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withOpacity(0.08),
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 48.sp, color: AppTheme.primaryGreen),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Notifications Yet',
            style: GoogleFonts.lora(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'re all caught up! Alerts and\nupdates will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 13.sp,
              color: isDark ? Colors.white38 : Colors.black45,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48.sp, color: Colors.redAccent),
          SizedBox(height: 16.h),
          Text(
            'Failed to load notifications',
            style: GoogleFonts.lora(
                fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () =>
                ref.read(notificationProvider.notifier).load(),
            child: Text('Retry',
                style: GoogleFonts.lora(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'market':
        return Icons.show_chart_rounded;
      case 'transaction':
        return Icons.receipt_long_rounded;
      case 'kyc':
        return Icons.verified_user_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'market':
        return const Color(0xFF0284C7);
      case 'transaction':
        return AppTheme.primaryGreen;
      case 'kyc':
        return const Color(0xFF7C3AED);
      case 'withdrawal':
        return const Color(0xFFD97706);
      case 'offer':
        return const Color(0xFFDB2777);
      default:
        return AppTheme.primaryGreen;
    }
  }
}
