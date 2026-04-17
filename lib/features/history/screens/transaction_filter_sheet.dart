import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';

/// Full-featured filter bottom sheet for Transaction History.
///
/// Usage:
/// ```dart
/// final result = await showTransactionFilterSheet(
///   context: context,
///   current: _filter,
///   metalOptions: [...],
///   typeOptions:  [...],
///   statusOptions: [...],
/// );
/// if (result != null) setState(() => _filter = result);
/// ```
Future<TransactionFilter?> showTransactionFilterSheet({
  required BuildContext context,
  required TransactionFilter current,
  required List<String> metalOptions,
  required List<String> typeOptions,
  required List<String> statusOptions,
}) {
  return showModalBottomSheet<TransactionFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionFilterSheet(
      current: current,
      metalOptions: metalOptions,
      typeOptions: typeOptions,
      statusOptions: statusOptions,
    ),
  );
}

class _TransactionFilterSheet extends StatefulWidget {
  final TransactionFilter current;
  final List<String> metalOptions;
  final List<String> typeOptions;
  final List<String> statusOptions;

  const _TransactionFilterSheet({
    required this.current,
    required this.metalOptions,
    required this.typeOptions,
    required this.statusOptions,
  });

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late String? _metal;
  late String? _type;
  late String? _status;

  // ── Color palette ─────────────────────────────────────────────────
  static const _green = Color(0xFF1B882C);
  static const _darkGreen = Color(0xFF003716);
  static const _bgLight = Color(0xFFF8F9FA);
  static const _cardLight = Colors.white;
  static const _borderLight = Color(0xFFE9ECEF);
  static const _labelLight = Color(0xFF495057);
  static const _mutedLight = Color(0xFF868E96);

  @override
  void initState() {
    super.initState();
    _fromDate = widget.current.fromDate;
    _toDate = widget.current.toDate;
    _metal = widget.current.metalName;
    _type = widget.current.type;
    _status = widget.current.status;
  }

  int get _activeCount {
    int c = 0;
    if (_fromDate != null || _toDate != null) c++;
    if (_metal != null && _metal!.isNotEmpty) c++;
    if (_type != null && _type!.isNotEmpty) c++;
    if (_status != null && _status!.isNotEmpty) c++;
    return c;
  }

  void _reset() => setState(() {
        _fromDate = null;
        _toDate = null;
        _metal = null;
        _type = null;
        _status = null;
      });

  void _apply() => Navigator.pop(
        context,
        TransactionFilter(
          fromDate: _fromDate,
          toDate: _toDate,
          metalName: _metal,
          type: _type,
          status: _status,
        ),
      );

  // ── Date picker ───────────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final first = isFrom ? DateTime(2020) : (_fromDate ?? DateTime(2020));
    final last = isFrom ? (_toDate ?? DateTime.now()) : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        // Reset toDate if it's before new fromDate
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
      } else {
        _toDate = picked;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : _bgLight;
    final card = isDark ? const Color(0xFF1E293B) : _cardLight;
    final border = isDark ? const Color(0xFF334155) : _borderLight;
    final label = isDark ? Colors.white70 : _labelLight;
    final muted = isDark ? Colors.white38 : _mutedLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────────
            _buildHandle(isDark),

            // ── Header ────────────────────────────────────────────
            _buildHeader(isDark, muted),

            // ── Scrollable content ────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                children: [
                  // 1. Date Range
                  _buildSection(
                    label: 'Date Range',
                    icon: Icons.date_range_rounded,
                    isDark: isDark,
                    card: card,
                    border: border,
                    labelColor: label,
                    child: _buildDateRange(isDark, card, border, label, muted),
                  ),
                  SizedBox(height: 16.h),

                  // 2. Commodity
                  _buildSection(
                    label: 'Commodity',
                    icon: Icons.auto_awesome_rounded,
                    isDark: isDark,
                    card: card,
                    border: border,
                    labelColor: label,
                    child: _buildChipGroup(
                      options: widget.metalOptions,
                      selected: _metal,
                      onTap: (val) =>
                          setState(() => _metal = val == _metal ? null : val),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 3. Type
                  _buildSection(
                    label: 'Transaction Type',
                    icon: Icons.swap_horiz_rounded,
                    isDark: isDark,
                    card: card,
                    border: border,
                    labelColor: label,
                    child: _buildChipGroup(
                      options: widget.typeOptions,
                      selected: _type,
                      onTap: (val) =>
                          setState(() => _type = val == _type ? null : val),
                      labelMapper: _typeLabel,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 4. Status
                  _buildSection(
                    label: 'Status',
                    icon: Icons.verified_rounded,
                    isDark: isDark,
                    card: card,
                    border: border,
                    labelColor: label,
                    child: _buildChipGroup(
                      options: widget.statusOptions,
                      selected: _status,
                      onTap: (val) =>
                          setState(() => _status = val == _status ? null : val),
                      colorMapper: _statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action bar ─────────────────────────────────────────
            _buildActionBar(isDark, card, border),
          ],
        ),
      ),
    );
  }

  // ── Handle ──────────────────────────────────────────────────────────
  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
      child: Container(
        width: 42.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black12,
          borderRadius: BorderRadius.circular(100.r),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color muted) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Transactions',
                  style: GoogleFonts.lora(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                if (_activeCount > 0) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '$_activeCount filter${_activeCount > 1 ? 's' : ''} applied',
                    style: GoogleFonts.lora(
                      fontSize: 12.sp,
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_activeCount > 0)
            GestureDetector(
              onTap: _reset,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        size: 14.sp, color: const Color(0xFFDC2626)),
                    SizedBox(width: 5.w),
                    Text(
                      'Reset All',
                      style: GoogleFonts.lora(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────
  Widget _buildSection({
    required String label,
    required IconData icon,
    required bool isDark,
    required Color card,
    required Color border,
    required Color labelColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 14.sp, color: _green),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.lora(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: labelColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: border),
          ),
          padding: EdgeInsets.all(16.r),
          child: child,
        ),
      ],
    );
  }

  // ── Date range picker ────────────────────────────────────────────────
  Widget _buildDateRange(bool isDark, Color card, Color border,
      Color label, Color muted) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: 'From',
            date: _fromDate,
            icon: Icons.calendar_today_outlined,
            isDark: isDark,
            onTap: () => _pickDate(isFrom: true),
            onClear: _fromDate != null
                ? () => setState(() {
                      _fromDate = null;
                    })
                : null,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text('→',
              style: GoogleFonts.lora(
                fontSize: 16.sp,
                color: _green,
                fontWeight: FontWeight.w700,
              )),
        ),
        Expanded(
          child: _buildDateButton(
            label: 'To',
            date: _toDate,
            icon: Icons.calendar_today_outlined,
            isDark: isDark,
            onTap: () => _pickDate(isFrom: false),
            onClear: _toDate != null
                ? () => setState(() {
                      _toDate = null;
                    })
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final isSet = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSet
              ? _green.withOpacity(0.07)
              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSet ? _green.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14.sp, color: isSet ? _green : Colors.grey),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: isSet ? _green : Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yy').format(date)
                        : 'Select',
                    style: GoogleFonts.lora(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSet
                          ? _darkGreen
                          : (isDark ? Colors.white38 : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 14.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // ── Chip group ────────────────────────────────────────────────────────
  Widget _buildChipGroup({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onTap,
    String Function(String)? labelMapper,
    Color Function(String)? colorMapper,
  }) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((opt) {
        final isSelected = opt == selected;
        final displayLabel = labelMapper != null ? labelMapper(opt) : opt;
        final color = colorMapper != null ? colorMapper(opt) : _green;
        return GestureDetector(
          onTap: () => onTap(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [color.withOpacity(0.9), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isSelected
                    ? color
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded,
                      size: 12.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                ],
                Text(
                  _capitalise(displayLabel),
                  style: GoogleFonts.lora(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Action bar ────────────────────────────────────────────────────────
  Widget _buildActionBar(bool isDark, Color card, Color border) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: card,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            // Reset button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Reset',
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Apply button
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _apply,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_green, _darkGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 16.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        _activeCount > 0
                            ? 'Apply ($_activeCount)'
                            : 'Show All',
                        style: GoogleFonts.lora(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _typeLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'purchase':
        return 'Purchase';
      case 'withdrawal':
        return 'Withdrawal';
      case 'referral':
        return 'Referral';
      default:
        return _capitalise(raw);
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'success':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return _green;
    }
  }
}
