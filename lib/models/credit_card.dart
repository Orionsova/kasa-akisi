class InstallmentPlan {
  final String id;
  final String title;
  final double totalAmount;
  final double monthlyAmount;
  final int totalInstallments;
  final int remainingInstallments;
  final DateTime firstPaymentDate;

  const InstallmentPlan({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.firstPaymentDate,
  });

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    return InstallmentPlan(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      monthlyAmount: (json['monthlyAmount'] ?? 0).toDouble(),
      totalInstallments: json['totalInstallments'] ?? 1,
      remainingInstallments: json['remainingInstallments'] ?? 1,
      firstPaymentDate: DateTime.parse(
        json['firstPaymentDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'monthlyAmount': monthlyAmount,
      'totalInstallments': totalInstallments,
      'remainingInstallments': remainingInstallments,
      'firstPaymentDate': firstPaymentDate.toIso8601String(),
    };
  }

  double get outstandingBalance => monthlyAmount * remainingInstallments;
  double get currentCycleAmount => remainingInstallments > 0 ? monthlyAmount : 0;
  double get nextCycleAmount => remainingInstallments > 1 ? monthlyAmount : 0;
  double get remainingAfterCurrentCycle =>
      remainingInstallments > 1 ? monthlyAmount * (remainingInstallments - 1) : 0;
}

class FuturePeriodPayment {
  final String id;
  final String title;
  final String monthLabel;
  final double amount;
  final int? totalInstallments;
  final int? remainingInstallments;

  const FuturePeriodPayment({
    required this.id,
    required this.title,
    required this.monthLabel,
    required this.amount,
    this.totalInstallments,
    this.remainingInstallments,
  });

  factory FuturePeriodPayment.fromJson(Map<String, dynamic> json) {
    return FuturePeriodPayment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      monthLabel: json['monthLabel'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      totalInstallments: json['totalInstallments'],
      remainingInstallments: json['remainingInstallments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'monthLabel': monthLabel,
      'amount': amount,
      'totalInstallments': totalInstallments,
      'remainingInstallments': remainingInstallments,
    };
  }
}

class CreditCardModel {
  final String id;
  final String name;
  final String lastFourDigits;
  final String? cardholderNameOverride;
  final bool isActive;
  final double limit;
  final double availableLimit;
  final int dueDay;
  final int statementDay;
  final int paymentGraceDays;
  final String colorHex;
  final String shapeKey;
  final List<InstallmentPlan> installments;
  final List<FuturePeriodPayment> futurePeriodPayments;

  const CreditCardModel({
    required this.id,
    required this.name,
    required this.lastFourDigits,
    required this.cardholderNameOverride,
    required this.isActive,
    required this.limit,
    required this.availableLimit,
    required this.dueDay,
    required this.statementDay,
    required this.paymentGraceDays,
    required this.colorHex,
    required this.shapeKey,
    required this.installments,
    required this.futurePeriodPayments,
  });

  double get currentDebt => (limit - availableLimit).clamp(0, limit);
  double get installmentOutstandingBalance =>
      installments.fold(0, (sum, item) => sum + item.outstandingBalance);
  double get installmentCurrentCycleTotal =>
      installments.fold(0, (sum, item) => sum + item.currentCycleAmount);
  double get installmentNextCycleTotal =>
      installments.fold(0, (sum, item) => sum + item.nextCycleAmount);
  double get installmentRemainingAfterCurrentCycle =>
      installments.fold(0, (sum, item) => sum + item.remainingAfterCurrentCycle);
  double get nonInstallmentDebt =>
      (currentDebt - installmentOutstandingBalance).clamp(0, limit);
  double get nextPeriodDebt =>
      installmentNextCycleTotal +
      futurePeriodPayments.fold(0, (sum, item) => sum + item.amount);
  double get currentStatementDebt => nonInstallmentDebt + installmentCurrentCycleTotal;
  double get remainingDebtAfterCurrentCycle =>
      installmentRemainingAfterCurrentCycle +
      futurePeriodPayments.fold(0, (sum, item) => sum + item.amount);
  double get monthlyInstallmentTotal =>
      installments.fold(0, (sum, item) => sum + item.monthlyAmount);

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    final limit = (json['limit'] ?? 0).toDouble();
    final storedAvailableLimit = json['availableLimit'];
    final legacyCurrentDebt = (json['currentDebt'] ?? 0).toDouble();
    final statementDay = json['statementDay'] ?? 1;
    final dueDay = json['dueDay'] ?? 1;
    final storedGraceDays = json['paymentGraceDays'];
    final derivedGraceDays = storedGraceDays is num
        ? storedGraceDays.toInt()
        : (dueDay is int && statementDay is int && dueDay > statementDay)
            ? (dueDay - statementDay)
            : 10;

    return CreditCardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lastFourDigits: (json['lastFourDigits'] ?? '').toString(),
      cardholderNameOverride: (json['cardholderNameOverride'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['cardholderNameOverride'] as String,
      isActive: json['isActive'] ?? true,
      limit: limit,
      availableLimit: storedAvailableLimit == null
          ? (limit - legacyCurrentDebt).clamp(0, limit)
          : (storedAvailableLimit as num).toDouble(),
      dueDay: dueDay,
      statementDay: statementDay,
      paymentGraceDays: derivedGraceDays <= 0 ? 10 : derivedGraceDays,
      colorHex: json['colorHex'] ?? 'graphite_metal',
      shapeKey: json['shapeKey'] ?? 'diagonal_gloss',
      installments: (json['installments'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => InstallmentPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      futurePeriodPayments: (json['futurePeriodPayments'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) => FuturePeriodPayment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastFourDigits': lastFourDigits,
      'cardholderNameOverride': cardholderNameOverride,
      'isActive': isActive,
      'limit': limit,
      'availableLimit': availableLimit,
      'currentDebt': currentDebt,
      'dueDay': dueDay,
      'statementDay': statementDay,
      'paymentGraceDays': paymentGraceDays,
      'colorHex': colorHex,
      'shapeKey': shapeKey,
      'installments': installments.map((item) => item.toJson()).toList(),
      'futurePeriodPayments': futurePeriodPayments
          .map((item) => item.toJson())
          .toList(),
    };
  }

  CreditCardModel copyWith({
    String? id,
    String? name,
    String? lastFourDigits,
    String? cardholderNameOverride,
    bool? isActive,
    double? limit,
    double? availableLimit,
    int? dueDay,
    int? statementDay,
    int? paymentGraceDays,
    String? colorHex,
    String? shapeKey,
    List<InstallmentPlan>? installments,
    List<FuturePeriodPayment>? futurePeriodPayments,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardholderNameOverride:
          cardholderNameOverride ?? this.cardholderNameOverride,
      isActive: isActive ?? this.isActive,
      limit: limit ?? this.limit,
      availableLimit: availableLimit ?? this.availableLimit,
      dueDay: dueDay ?? this.dueDay,
      statementDay: statementDay ?? this.statementDay,
      paymentGraceDays: paymentGraceDays ?? this.paymentGraceDays,
      colorHex: colorHex ?? this.colorHex,
      shapeKey: shapeKey ?? this.shapeKey,
      installments: installments ?? this.installments,
      futurePeriodPayments: futurePeriodPayments ?? this.futurePeriodPayments,
    );
  }
}
