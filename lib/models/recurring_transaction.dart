class RecurringTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final int dayOfMonth;
  final bool isIncome;
  final bool isSubscription;
  final String? note;
  final DateTime startDate;

  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    required this.isIncome,
    required this.isSubscription,
    this.note,
    required this.startDate,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dayOfMonth: json['dayOfMonth'] ?? 1,
      isIncome: json['isIncome'] ?? false,
      isSubscription: json['isSubscription'] ?? false,
      note: json['note'],
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'isIncome': isIncome,
      'isSubscription': isSubscription,
      'note': note,
      'startDate': startDate.toIso8601String(),
    };
  }
}
