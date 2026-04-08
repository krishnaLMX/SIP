class MarketRates {
  final String goldName;
  final double goldBuy;
  final double goldSell;
  final double goldChange;
  final double goldPercentage;
  final String silverName;
  final double silverBuy;
  final double silverSell;
  final double silverChange;
  final double silverPercentage;
  final DateTime timestamp;
  final String currency;

  MarketRates({
    this.goldName = 'Gold 24KT',
    required this.goldBuy,
    required this.goldSell,
    required this.goldChange,
    required this.goldPercentage,
    this.silverName = 'Silver 999',
    required this.silverBuy,
    required this.silverSell,
    required this.silverChange,
    required this.silverPercentage,
    required this.timestamp,
    this.currency = 'INR',
  });

  MarketRates.initial()
      : goldName = 'Gold 24KT',
        goldBuy = 0.0,
        goldSell = 0.0,
        goldChange = 0.0,
        goldPercentage = 0.0,
        silverName = 'Silver 999',
        silverBuy = 0.0,
        silverSell = 0.0,
        silverChange = 0.0,
        silverPercentage = 0.0,
        timestamp = DateTime.now(),
        currency = 'INR';

  factory MarketRates.fromRawString(String rawData, MarketRates? previous,
      {String goldId = '1',
      String silverId = '3',
      String goldName = 'Gold 24KT',
      String silverName = 'Silver 999'}) {
    final lines = rawData.split('\n');
    String gName = previous?.goldName ?? goldName;
    double gBuy = previous?.goldBuy ?? 0.0;
    double gSell = previous?.goldSell ?? 0.0;
    String sName = previous?.silverName ?? silverName;
    double sBuy = previous?.silverBuy ?? 0.0;
    double sSell = previous?.silverSell ?? 0.0;

    for (var line in lines) {
      // Use pipe delimiter for KJPL native websocket
      final parts = line.split('|');

      if (parts.length >= 5 && parts[0] == '3') {
        final id = parts[1];

        // Safely parse rates from parts[3] (buy) and parts[4] (sell)
        final buyStr = parts[3];
        final sellStr = parts[4];

        double rate1 = double.tryParse(buyStr) ?? 0.0;
        double rate2 = double.tryParse(sellStr) ?? 0.0;

        // If buy is '-', fallback to sell value
        if (rate1 == 0.0 && rate2 != 0.0) rate1 = rate2;
        // If sell is '-', fallback to buy value
        if (rate2 == 0.0 && rate1 != 0.0) rate2 = rate1;

        if (id == goldId) {
          gName = goldName;
          gBuy = rate1;
          gSell = rate2;
        } else if (id == silverId) {
          sName = silverName;
          sBuy = rate1;
          sSell = rate2;
        }
      } /*  else if (parts.length >= 4 && parts[0] == '1') {
        // this is no needed .when go for production pls remove the part
        // Optional: Also parse live streaming rates if needed
        final symbol = parts[1];
        final buy = double.tryParse(parts[2]) ?? 0.0;
        final sell = double.tryParse(parts[3]) ?? 0.0;

        if (symbol == 'G' && gBuy == 0.0) {
          gBuy = buy;
          gSell = sell;
        } else if (symbol == 'S' && sBuy == 0.0) {
          sBuy = buy;
          sSell = sell;
        }
      } */
    }

    // Calculate changes if we have previous rates
    double gChange =
        (previous != null && gSell != 0) ? gSell - previous.goldSell : 0.0;
    double sChange =
        (previous != null && sSell != 0) ? sSell - previous.silverSell : 0.0;

    return MarketRates(
      goldName: gName,
      goldBuy: gBuy,
      goldSell: gSell,
      goldChange: gChange,
      goldPercentage: (previous != null && previous.goldSell != 0)
          ? (gChange / previous.goldSell) * 100
          : 0.0,
      silverName: sName,
      silverBuy: sBuy,
      silverSell: sSell,
      silverChange: sChange,
      silverPercentage: (previous != null && previous.silverSell != 0)
          ? (sChange / previous.silverSell) * 100
          : 0.0,
      timestamp: DateTime.now(),
      currency: 'INR',
    );
  }

  factory MarketRates.fromJson(Map<String, dynamic> json) {
    return MarketRates(
      goldName: json['gold_name'] ?? 'Gold 24KT',
      goldBuy: (json['gold_buy'] as num? ?? 0.0).toDouble(),
      goldSell: (json['gold_sell'] as num? ?? 0.0).toDouble(),
      goldChange: (json['gold_change'] as num? ?? 0.0).toDouble(),
      goldPercentage: (json['gold_percentage'] as num? ?? 0.0).toDouble(),
      silverName: json['silver_name'] ?? 'Silver 999',
      silverBuy: (json['silver_buy'] as num? ?? 0.0).toDouble(),
      silverSell: (json['silver_sell'] as num? ?? 0.0).toDouble(),
      silverChange: (json['silver_change'] as num? ?? 0.0).toDouble(),
      silverPercentage: (json['silver_percentage'] as num? ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      currency: json['currency'] ?? 'INR',
    );
  }

  MarketRates copyWith({
    String? goldName,
    double? goldBuy,
    double? goldSell,
    double? goldChange,
    double? goldPercentage,
    String? silverName,
    double? silverBuy,
    double? silverSell,
    double? silverChange,
    double? silverPercentage,
    DateTime? timestamp,
    String? currency,
  }) {
    return MarketRates(
      goldName: goldName ?? this.goldName,
      goldBuy: goldBuy ?? this.goldBuy,
      goldSell: goldSell ?? this.goldSell,
      goldChange: goldChange ?? this.goldChange,
      goldPercentage: goldPercentage ?? this.goldPercentage,
      silverName: silverName ?? this.silverName,
      silverBuy: silverBuy ?? this.silverBuy,
      silverSell: silverSell ?? this.silverSell,
      silverChange: silverChange ?? this.silverChange,
      silverPercentage: silverPercentage ?? this.silverPercentage,
      timestamp: timestamp ?? this.timestamp,
      currency: currency ?? this.currency,
    );
  }

  bool isSignificantChange(MarketRates other) {
    return goldName != other.goldName ||
        silverName != other.silverName ||
        (goldBuy - other.goldBuy).abs() > 0.001 ||
        (goldSell - other.goldSell).abs() > 0.001 ||
        (silverBuy - other.silverBuy).abs() > 0.001 ||
        (silverSell - other.silverSell).abs() > 0.001;
  }
}
