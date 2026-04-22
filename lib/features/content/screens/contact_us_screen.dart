import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startgold/core/services/content_service.dart';
import 'package:startgold/shared/theme/app_theme.dart';
import 'package:startgold/shared/widgets/gradient_header.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  /// Returns the URL from [data] only if present and non-empty — no hardcoded fallback.
  String? _resolve(Map<String, dynamic> data, String key) {
    final val = data[key];
    if (val is String && val.trim().isNotEmpty) return val.trim();
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactInfoAsync = ref.watch(contactUsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(title: 'Contact Us'),
          Expanded(
            child: contactInfoAsync.when(
              data: (data) => _buildBody(context, data, isDark),
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2.5,
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 48.sp,
                        color: isDark ? Colors.white24 : Colors.black26),
                    SizedBox(height: 12.h),
                    Text(
                      'Failed to load contact info.',
                      style: GoogleFonts.lora(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, Map<String, dynamic> data, bool isDark) {
    // Resolve social links — returns null if empty so conditional rendering works
    final facebook = _resolve(data, 'facebook');
    final twitter = _resolve(data, 'twitter');
    final instagram = _resolve(data, 'instagram');
    final website = _resolve(data, 'website');

    // Build the list of social links that actually exist
    final socialLinks = <_SocialLink>[
      if (facebook != null)
        _SocialLink(
          label: 'Facebook',
          url: facebook,
          gradient: const LinearGradient(
            colors: [Color(0xFF1877F2), Color(0xFF0A5CC7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: const _FacebookIcon(),
        ),
      if (twitter != null)
        _SocialLink(
          label: 'X',
          url: twitter,
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF262626), const Color(0xFF3A3A3A)]
                : [const Color(0xFF0F0F0F), const Color(0xFF2D2D2D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: const _XIcon(),
        ),
      if (instagram != null)
        _SocialLink(
          label: 'Instagram',
          url: instagram,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFEDA77),
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: const _InstagramIcon(),
        ),
      if (website != null)
        _SocialLink(
          label: 'Website',
          url: website,
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.85),
              const Color(0xFF008060),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: const _WebsiteIcon(),
        ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ──────────────────────────────
          _SectionLabel(label: 'Help & Support', isDark: isDark),
          SizedBox(height: 14.h),

          // ── Contact cards ──────────────────────────────
          _ContactCard(
            icon: Icons.email_rounded,
            title: 'E-Mail Us',
            value: _resolve(data, 'email') ?? '—',
            isDark: isDark,
            onTap: _resolve(data, 'email') != null
                ? () => _launchUrl('mailto:${_resolve(data, 'email')}')
                : null,
          ),
          SizedBox(height: 12.h),
          _ContactCard(
            icon: Icons.phone_rounded,
            title: 'Call Us',
            value: _resolve(data, 'phone') ?? '—',
            isDark: isDark,
            onTap: _resolve(data, 'phone') != null
                ? () => _launchUrl(
                    'tel:${_resolve(data, 'phone')!.replaceAll(RegExp(r'[^0-9+]'), '')}')
                : null,
          ),
          SizedBox(height: 12.h),
          _ContactCard(
            icon: Icons.location_on_rounded,
            title: 'Visit Us',
            value: _resolve(data, 'address') ?? '—',
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          _ContactCard(
            icon: Icons.access_time_rounded,
            title: 'Working Hours',
            value: _resolve(data, 'working_hours') ?? '—',
            isDark: isDark,
          ),

          // ── Social section (only if at least 1 link exists) ──────────────
          if (socialLinks.isNotEmpty) ...[
            SizedBox(height: 32.h),
            _SectionLabel(label: 'Follow Us', isDark: isDark),
            SizedBox(height: 6.h),
            Text(
              'Stay connected with us on social media',
              style: GoogleFonts.lora(
                fontSize: 13.sp,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: socialLinks
                  .map((link) => _SocialIconTile(link: link, isDark: isDark))
                  .toList(),
            ),
          ],

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _SocialLink {
  final String label;
  final String url;
  final Gradient gradient;
  final Widget icon;

  const _SocialLink({
    required this.label,
    required this.url,
    required this.gradient,
    required this.icon,
  });
}

// ── Section label widget ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ── Contact card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _ctrl.forward() : null,
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          decoration: BoxDecoration(
            color:
                widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: widget.isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.15),
                      AppTheme.primaryGreen.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon,
                    color: AppTheme.primaryGreen, size: 22.sp),
              ),
              SizedBox(width: 16.w),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.lora(
                        fontSize: 12.sp,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      widget.value,
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow (only if tappable)
              if (widget.onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: widget.isDark
                      ? Colors.white24
                      : Colors.black.withOpacity(0.2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Social icon tile ─────────────────────────────────────────────────────────

class _SocialIconTile extends StatefulWidget {
  final _SocialLink link;
  final bool isDark;

  const _SocialIconTile({required this.link, required this.isDark});

  @override
  State<_SocialIconTile> createState() => _SocialIconTileState();
}

class _SocialIconTileState extends State<_SocialIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed width tiles — 4 per row on standard screens via Wrap
    final tileWidth = (MediaQuery.of(context).size.width - 40.w - 36.w) / 4;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        _launchUrl(widget.link.url);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: tileWidth,
          child: Column(
            children: [
              // Gradient icon container
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: widget.link.gradient,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(child: widget.link.icon),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.link.label,
                style: GoogleFonts.lora(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom icon painters ─────────────────────────────────────────────────────

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(24.sp, 24.sp),
      painter: _FacebookPainter(),
    );
  }
}

class _FacebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.62, h * 0.10);
    path.lineTo(w * 0.48, h * 0.10);
    path.cubicTo(w * 0.31, h * 0.10, w * 0.25, h * 0.20, w * 0.25, h * 0.34);
    path.lineTo(w * 0.25, h * 0.44);
    path.lineTo(w * 0.16, h * 0.44);
    path.lineTo(w * 0.16, h * 0.58);
    path.lineTo(w * 0.25, h * 0.58);
    path.lineTo(w * 0.25, h * 0.90);
    path.lineTo(w * 0.41, h * 0.90);
    path.lineTo(w * 0.41, h * 0.58);
    path.lineTo(w * 0.54, h * 0.58);
    path.lineTo(w * 0.57, h * 0.44);
    path.lineTo(w * 0.41, h * 0.44);
    path.lineTo(w * 0.41, h * 0.36);
    path.cubicTo(w * 0.41, h * 0.32, w * 0.43, h * 0.29, w * 0.49, h * 0.29);
    path.lineTo(w * 0.62, h * 0.29);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _XIcon extends StatelessWidget {
  const _XIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(22.sp, 22.sp),
      painter: _XPainter(),
    );
  }
}

class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Diagonal stroke top-left → bottom-right
    final p1 = Path();
    p1.moveTo(w * 0.05, h * 0.07);
    p1.lineTo(w * 0.22, h * 0.07);
    p1.lineTo(w * 0.95, h * 0.93);
    p1.lineTo(w * 0.78, h * 0.93);
    p1.close();
    canvas.drawPath(p1, paint);

    // Diagonal stroke top-right → bottom-left
    final p2 = Path();
    p2.moveTo(w * 0.78, h * 0.07);
    p2.lineTo(w * 0.95, h * 0.07);
    p2.lineTo(w * 0.22, h * 0.93);
    p2.lineTo(w * 0.05, h * 0.93);
    p2.close();
    canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(24.sp, 24.sp),
      painter: _InstagramPainter(),
    );
  }
}

class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Outer rounded square
    canvas.drawRRect(
      RRect.fromLTRBR(
          w * 0.08, h * 0.08, w * 0.92, h * 0.92, Radius.circular(w * 0.26)),
      strokePaint,
    );

    // Inner circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.21, strokePaint);

    // Top-right dot
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), w * 0.07, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WebsiteIcon extends StatelessWidget {
  const _WebsiteIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.language_rounded,
      color: Colors.white,
      size: 26.sp,
    );
  }
}
