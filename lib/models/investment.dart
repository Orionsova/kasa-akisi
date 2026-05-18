class InvestmentModel {
  final String id;
  final String title;
  final String type;
  final double principal;
  final double currentValue;
  final double? maturityRate;
  final double? monthlyYield;
  final int? termDays;
  final DateTime? openedAt;
  final String? symbol;
  final String? note;

  const InvestmentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.principal,
    required this.currentValue,
    this.maturityRate,
    this.monthlyYield,
    this.termDays,
    this.openedAt,
    this.symbol,
    this.note,
  });

  double get profitLoss => currentValue - principal;

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      principal: (json['principal'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      maturityRate: json['maturityRate'] == null
          ? null
          : (json['maturityRate'] as num).toDouble(),
      monthlyYield: json['monthlyYield'] == null
          ? null
          : (json['monthlyYield'] as num).toDouble(),
      termDays: json['termDays'] as int?,
      openedAt: json['openedAt'] == null
          ? null
          : DateTime.parse(json['openedAt']),
      symbol: json['symbol'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'principal': principal,
      'currentValue': currentValue,
      'maturityRate': maturityRate,
      'monthlyYield': monthlyYield,
      'termDays': termDays,
      'openedAt': openedAt?.toIso8601String(),
      'symbol': symbol,
      'note': note,
    };
  }
}
