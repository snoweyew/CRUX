class Voucher {
  final String id;
  final String userId;
  final String code;
  final double value;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isRedeemed;
  final DateTime? redeemedAt;

  Voucher({
    required this.id,
    required this.userId,
    required this.code,
    required this.value,
    required this.issuedAt,
    required this.expiresAt,
    this.isRedeemed = false,
    this.redeemedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'code': code,
      'value': value,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isRedeemed': isRedeemed,
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      userId: json['userId'],
      code: json['code'],
      value: json['value'],
      issuedAt: DateTime.parse(json['issuedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      isRedeemed: json['isRedeemed'],
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && !isRedeemed;
} 