enum AccountType { demo, real }

class TradingAccount {
  const TradingAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.startingBalance,
    required this.currency,
    required this.createdAt,
    this.profitTarget = 0,
  });

  final String id;
  final String name;
  final AccountType type;
  final double startingBalance;
  final String currency;
  final DateTime createdAt;
  final double profitTarget;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'startingBalance': startingBalance,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'profitTarget': profitTarget,
  };

  factory TradingAccount.fromJson(Map<String, dynamic> json) => TradingAccount(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    type: AccountType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => AccountType.demo,
    ),
    startingBalance: _finiteNumber(json['startingBalance']),
    currency: json['currency'] as String? ?? 'USD',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    profitTarget: _finiteNumber(json['profitTarget']),
  );
}

double _finiteNumber(Object? value) {
  final parsed = value is num ? value.toDouble() : 0.0;
  return parsed.isFinite && parsed >= 0 ? parsed : 0.0;
}
