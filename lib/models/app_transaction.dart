class AppTransaction {
  static const String typeStandard = 'standard';
  static const String typeCreditCardExpense = 'credit-card-expense';
  static const String typeCardDebtPayment = 'card-debt-payment';

  final String id;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;
  final String? selectedCardId;
  final bool isInstallment;
  final String transactionType;

  AppTransaction({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
    this.selectedCardId,
    this.isInstallment = false,
    this.transactionType = typeStandard,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isIncome: json['isIncome'] ?? false,
      selectedCardId: json['selectedCardId'],
      isInstallment: json['isInstallment'] ?? false,
      transactionType: _resolveTransactionType(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'selectedCardId': selectedCardId,
      'isInstallment': isInstallment,
      'transactionType': transactionType,
    };
  }

  AppTransaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    bool? isIncome,
    String? selectedCardId,
    bool? isInstallment,
    String? transactionType,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      selectedCardId: selectedCardId ?? this.selectedCardId,
      isInstallment: isInstallment ?? this.isInstallment,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  bool get isCardExpense => transactionType == typeCreditCardExpense;

  bool get isCardDebtPayment => transactionType == typeCardDebtPayment;

  bool get affectsCashBalance => isIncome || !isCardExpense;

  static String _resolveTransactionType(Map<String, dynamic> json) {
    final storedType = json['transactionType']?.toString().trim();
    if (storedType != null && storedType.isNotEmpty) {
      return storedType;
    }

    final isIncome = json['isIncome'] ?? false;
    final selectedCardId = json['selectedCardId']?.toString().trim();
    final category = json['category']?.toString().trim() ?? '';

    if (!isIncome && category == 'Kart Borcu Ödeme') {
      return typeCardDebtPayment;
    }

    if (!isIncome && selectedCardId != null && selectedCardId.isNotEmpty) {
      return typeCreditCardExpense;
    }

    return typeStandard;
  }
}
