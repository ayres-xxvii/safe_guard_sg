// voucher_models.dart
class Voucher {
  final String id;
  final String title;
  final String value;
  final String description;
  final String validFrom;
  final String validTo;
  final int pointsRequired;
  final String logoAsset;
  final List<String> terms;

  Voucher({
    required this.id,
    required this.title,
    required this.value,
    required this.description,
    required this.validFrom,
    required this.validTo,
    required this.pointsRequired,
    required this.logoAsset,
    this.terms = const [],
  });
}

class RedeemedVoucher {
  final String id;
  final String title;
  final String value;
  final String redeemedDate;
  final String expiryDate;
  final String voucherCode;
  final String logoAsset;
  final bool isExpired;

  RedeemedVoucher({
    required this.id,
    required this.title,
    required this.value,
    required this.redeemedDate,
    required this.expiryDate,
    required this.voucherCode,
    required this.logoAsset,
    this.isExpired = false,
  });
}