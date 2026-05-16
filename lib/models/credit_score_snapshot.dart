class CreditScoreSnapshot {
  final String id;
  final DateTime createdAt;
  final int score;
  final double totalLimit;
  final double availableLimit;
  final double currentStatementDebt;

  const CreditScoreSnapshot({
    required this.id,
    required this.createdAt,
    required this.score,
    required this.totalLimit,
    required this.availableLimit,
    required this.currentStatementDebt,
  });

  factory CreditScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return CreditScoreSnapshot(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      score: json['score'] ?? 0,
      totalLimit: (json['totalLimit'] ?? 0).toDouble(),
      availableLimit: (json['availableLimit'] ?? 0).toDouble(),
      currentStatementDebt: (json['currentStatementDebt'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'score': score,
      'totalLimit': totalLimit,
      'availableLimit': availableLimit,
      'currentStatementDebt': currentStatementDebt,
    };
  }
}
