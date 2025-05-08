// voucher_service.dart
import '../models/voucher_models.dart';

class VoucherService {
  // In a real app, this would be fetched from an API or database
  final List<Voucher> availableVouchers = [
    Voucher(
      id: 'climate100',
      title: 'Climate Vouchers (\$100)',
      value: '\$100',
      description: 'Save on eco-friendly products',
      validFrom: '15 Apr 2025',
      validTo: '31 Dec 2027',
      pointsRequired: 2000,
      logoAsset: 'assets/images/climate_voucher_logo.png',
      terms: [
        'Limited to one voucher per household',
        'Valid for purchases above \$200',
        'Cannot be combined with other promotions',
      ],
    ),
    Voucher(
      id: 'climate300',
      title: 'Climate Vouchers (\$300)',
      value: '\$300',
      description: 'Premium savings on eco-friendly products',
      validFrom: '15 Apr 2024',
      validTo: '31 Dec 2027',
      pointsRequired: 5000,
      logoAsset: 'assets/images/climate_voucher_logo.png',
      terms: [
        'Limited to one voucher per household',
        'Valid for purchases above \$500',
        'Cannot be combined with other promotions',
      ],
    ),
    Voucher(
      id: 'ntuc5',
      title: 'NTUC Voucher',
      value: '\$5',
      description: 'Save on your groceries at NTUC FairPrice',
      validFrom: '1 Jan 2025',
      validTo: '31 Dec 2025',
      pointsRequired: 2500,
      logoAsset: 'assets/images/ntuc_logo.png',
      terms: [
        'Valid at all NTUC FairPrice outlets',
        'Minimum purchase of \$50 required',
        'Cannot be combined with other vouchers',
      ],
    ),
    Voucher(
      id: 'ntuc10',
      title: 'NTUC Voucher',
      value: '\$10',
      description: 'Save on your groceries at NTUC FairPrice',
      validFrom: '1 Jan 2025',
      validTo: '31 Dec 2025',
      pointsRequired: 4500,
      logoAsset: 'assets/images/ntuc_logo.png',
      terms: [
        'Valid at all NTUC FairPrice outlets',
        'Minimum purchase of \$80 required',
        'Cannot be combined with other vouchers',
      ],
    ),
  ];

  // Sample redeemed vouchers data
  final List<RedeemedVoucher> redeemedVouchers = [
    RedeemedVoucher(
      id: 'ntuc5-red1',
      title: 'NTUC Voucher',
      value: '\$5',
      redeemedDate: '10 Mar 2025',
      expiryDate: '10 Jun 2025',
      voucherCode: 'NTUC5682923',
      logoAsset: 'assets/images/ntuc_logo.png',
      isExpired: false,
    ),
    RedeemedVoucher(
      id: 'climate100-red1',
      title: 'Climate Vouchers',
      value: '\$100',
      redeemedDate: '15 Jan 2025',
      expiryDate: '15 Apr 2025',
      voucherCode: 'CLM1002483',
      logoAsset: 'assets/images/climate_voucher_logo.png',
      isExpired: true,
    ),
  ];

  // Method to redeem a voucher
  RedeemedVoucher redeemVoucher(Voucher voucher) {
    // In a real app, this would involve API calls and updating user points
    final today = DateTime.now();
    final expiryDate = today.add(const Duration(days: 90));
    
    final redeemedVoucher = RedeemedVoucher(
      id: '${voucher.id}-${redeemedVouchers.length + 1}',
      title: voucher.title,
      value: voucher.value,
      redeemedDate: '${today.day} ${_getMonthName(today.month)} ${today.year}',
      expiryDate: '${expiryDate.day} ${_getMonthName(expiryDate.month)} ${expiryDate.year}',
      voucherCode: _generateVoucherCode(),
      logoAsset: voucher.logoAsset,
    );
    
    // In a real app, we would add this to the database
    redeemedVouchers.add(redeemedVoucher);
    
    return redeemedVoucher;
  }
  
  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  // Helper method to generate a random voucher code
  String _generateVoucherCode() {
    // In a real app, this would generate a unique code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final codePrefix = availableVouchers[0].title.substring(0, 4).toUpperCase();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[DateTime.now().millisecond % chars.length];
    }
    return '$codePrefix$code';
  }
}