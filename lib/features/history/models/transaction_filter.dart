import '../models/history_models.dart';

/// Immutable filter state for the Transaction History screen.
class TransactionFilter {
  /// null = no date restriction
  final DateTime? fromDate;
  final DateTime? toDate;

  /// null / empty = "All"
  final String? metalName;
  final String? type;
  final String? status;

  const TransactionFilter({
    this.fromDate,
    this.toDate,
    this.metalName,
    this.type,
    this.status,
  });

  static const TransactionFilter empty = TransactionFilter();

  bool get isEmpty =>
      fromDate == null &&
      toDate == null &&
      (metalName == null || metalName!.isEmpty) &&
      (type == null || type!.isEmpty) &&
      (status == null || status!.isEmpty);

  /// Count of active filters (for badge display).
  int get activeCount {
    int count = 0;
    if (fromDate != null || toDate != null) count++;
    if (metalName != null && metalName!.isNotEmpty) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (status != null && status!.isNotEmpty) count++;
    return count;
  }

  TransactionFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
    String? metalName,
    bool clearMetal = false,
    String? type,
    bool clearType = false,
    String? status,
    bool clearStatus = false,
  }) {
    return TransactionFilter(
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      metalName: clearMetal ? null : (metalName ?? this.metalName),
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  /// Apply this filter to a flat list and regroup by date.
  Map<String, List<TransactionItem>> applyTo(HistoryResponse history) {
    // Flatten all transactions
    final List<TransactionItem> flat = history.transactions;

    final filtered = flat.where((tx) {
      // ── Date range ──────────────────────────────────────────────────
      if (fromDate != null || toDate != null) {
        DateTime? txDate;
        try {
          txDate = DateTime.parse(tx.date);
        } catch (_) {}
        if (txDate != null) {
          if (fromDate != null) {
            final from = DateTime(
                fromDate!.year, fromDate!.month, fromDate!.day);
            if (txDate.isBefore(from)) return false;
          }
          if (toDate != null) {
            final to = DateTime(
                toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
            if (txDate.isAfter(to)) return false;
          }
        }
      }

      // ── Metal / commodity ───────────────────────────────────────────
      if (metalName != null && metalName!.isNotEmpty) {
        if (!tx.metalName
            .toLowerCase()
            .contains(metalName!.toLowerCase())) {
          return false;
        }
      }

      // ── Type (purchase / withdrawal / referral) ─────────────────────
      if (type != null && type!.isNotEmpty) {
        if (tx.type.toLowerCase() != type!.toLowerCase()) return false;
      }

      // ── Status (Success / Pending / Cancelled) ──────────────────────
      if (status != null && status!.isNotEmpty) {
        if (tx.status.toLowerCase() != status!.toLowerCase()) return false;
      }

      return true;
    }).toList();

    // Regroup by original date key
    final Map<String, List<TransactionItem>> grouped = {};
    for (final tx in filtered) {
      grouped.putIfAbsent(tx.date, () => []).add(tx);
    }
    return grouped;
  }

  /// Extract unique metal names from history for filter options.
  static List<String> metalOptions(HistoryResponse history) {
    final Set<String> set = {};
    for (final tx in history.transactions) {
      if (tx.metalName.isNotEmpty) set.add(tx.metalName);
    }
    return set.toList()..sort();
  }

  /// Extract unique types from history.
  static List<String> typeOptions(HistoryResponse history) {
    final Set<String> set = {};
    for (final tx in history.transactions) {
      if (tx.type.isNotEmpty) set.add(tx.type);
    }
    return set.toList()..sort();
  }

  /// Extract unique statuses from history.
  static List<String> statusOptions(HistoryResponse history) {
    final Set<String> set = {};
    for (final tx in history.transactions) {
      if (tx.status.isNotEmpty) set.add(tx.status);
    }
    return set.toList()..sort();
  }
}
