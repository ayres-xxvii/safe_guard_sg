import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/user_points_service.dart' as UserPointsService;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../shared_layer/shared_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/voucher_models.dart';
import '../services/voucher_service.dart';
import '../services/user_points_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/user_points_service.dart' as UserPointsService;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../shared_layer/shared_scaffold.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/user_points_service.dart' as UserPointsService;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../shared_layer/shared_scaffold.dart';
import 'dart:convert';

// Model classes
class Voucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String? imageUrl;

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.imageUrl,
  });

  factory Voucher.fromMap(String id, Map<String, dynamic> map) {
    return Voucher(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'imageUrl': imageUrl,
    };
  }
}

class RedeemedVoucher {
  final String id;
  final String voucherId;
  final String title;
  final String description;
  final int pointsCost;
  final String? imageUrl;
  final String code;
  final DateTime redeemedAt;
  final DateTime expiresAt;

  RedeemedVoucher({
    required this.id,
    required this.voucherId,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.imageUrl,
    required this.code,
    required this.redeemedAt,
    required this.expiresAt,
  });

  factory RedeemedVoucher.fromMap(Map<String, dynamic> map) {
    return RedeemedVoucher(
      id: map['id'] ?? '',
      voucherId: map['voucherId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      imageUrl: map['imageUrl'],
      code: map['code'] ?? '',
      redeemedAt: DateTime.parse(map['redeemedAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherId': voucherId,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'imageUrl': imageUrl,
      'code': code,
      'redeemedAt': redeemedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

// Mock data service to replace Firestore
class VoucherDataService {
  // Sample vouchers
  static List<Voucher> getSampleVouchers() {
    return [
      Voucher(
        id: 'v1',
        title: '10% Off Any Purchase',
        description: 'Get 10% off any purchase at our store.',
        pointsCost: 500,
        imageUrl: 'https://picsum.photos/id/10/500/300',
      ),
      Voucher(
        id: 'v2',
        title: 'Free Coffee',
        description: 'Enjoy a free coffee at any of our locations.',
        pointsCost: 300,
        imageUrl: 'https://picsum.photos/id/20/500/300',
      ),
      Voucher(
        id: 'v3',
        title: 'Movie Ticket',
        description: 'One free movie ticket at partnered theaters.',
        pointsCost: 1000,
        imageUrl: 'https://picsum.photos/id/30/500/300',
      ),
      Voucher(
        id: 'v4',
        title: 'Spa Day',
        description: 'Enjoy a relaxing day at our partner spa.',
        pointsCost: 2000,
        imageUrl: 'https://picsum.photos/id/40/500/300',
      ),
    ];
  }
}

// SharedPreferences service for vouchers
class VoucherPrefsService {
  static const String redeemedVouchersKey = 'redeemed_vouchers';
  static const String userPointsKey = 'user_points';

  // Save redeemed voucher
  static Future<void> saveRedeemedVoucher(RedeemedVoucher voucher) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> vouchers = prefs.getStringList(redeemedVouchersKey) ?? [];
    
    // Add new voucher as JSON string
    vouchers.add(jsonEncode(voucher.toMap()));
    
    // Save updated list
    await prefs.setStringList(redeemedVouchersKey, vouchers);
  }

  // Get all redeemed vouchers
  static Future<List<RedeemedVoucher>> getRedeemedVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> vouchers = prefs.getStringList(redeemedVouchersKey) ?? [];
    
    return vouchers.map((voucherJson) {
      Map<String, dynamic> voucherMap = jsonDecode(voucherJson);
      return RedeemedVoucher.fromMap(voucherMap);
    }).toList();
  }

  // Get user points
  static Future<int> getUserPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(userPointsKey) ?? 1000; // Default 1000 points for new users
  }

  // Update user points
  static Future<int> updateUserPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(userPointsKey, points);
    return points;
  }

  // Deduct points for voucher redemption
  static Future<int> deductPoints(int pointsToDeduct) async {
    final currentPoints = await getUserPoints();
    final newPoints = currentPoints - pointsToDeduct;
    await updateUserPoints(newPoints);
    return newPoints;
  }

  // Clear all redeemed vouchers (for testing)
  static Future<void> clearRedeemedVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(redeemedVouchersKey);
  }

  // Reset points (for testing)
  static Future<void> resetPoints([int points = 1000]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(userPointsKey, points);
  }
}

class VouchersPage extends StatefulWidget {
  const VouchersPage({Key? key}) : super(key: key);

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Voucher> _availableVouchers = [];
  final List<RedeemedVoucher> _redeemedVouchers = [];
  bool _isLoading = true;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user points from SharedPreferences
      _userPoints = await VoucherPrefsService.getUserPoints();

      // Load available vouchers from mock data
      _availableVouchers.clear();
      _availableVouchers.addAll(VoucherDataService.getSampleVouchers());

      // Load redeemed vouchers from SharedPreferences
      await _loadRedeemedVouchers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading vouchers: $e');
    }
  }

  Future<void> _loadRedeemedVouchers() async {
    _redeemedVouchers.clear();
    
    try {
      // Load from SharedPreferences
      final redeemedList = await VoucherPrefsService.getRedeemedVouchers();
      
      // Sort by redemption date (newest first)
      redeemedList.sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
      
      _redeemedVouchers.addAll(redeemedList);
    } catch (e) {
      print('Error loading redeemed vouchers: $e');
      _showError('Error loading redeemed vouchers: $e');
    }
  }

  Future<void> _redeemVoucher(Voucher voucher) async {
    // Check if user has enough points
    if (_userPoints < voucher.pointsCost) {
      _showError("Insufficient Points");
      return;
    }

    // Show confirmation dialog
    bool confirmed = await _showConfirmationDialog(voucher);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Deduct points using SharedPreferences
      final int newPointsTotal = await VoucherPrefsService.deductPoints(voucher.pointsCost);
      
      // Create redeemed voucher
      final redeemedVoucher = RedeemedVoucher(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        voucherId: voucher.id,
        title: voucher.title,
        description: voucher.description,
        pointsCost: voucher.pointsCost,
        imageUrl: voucher.imageUrl,
        code: _generateVoucherCode(),
        redeemedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 30)),
      );

      // Save to SharedPreferences
      await VoucherPrefsService.saveRedeemedVoucher(redeemedVoucher);

      // Update state
      setState(() {
        _redeemedVouchers.insert(0, redeemedVoucher); // Add to beginning of list
        _userPoints = newPointsTotal; // Update points
        _isLoading = false;
      });

      // Switch to My Redemptions tab
      _tabController.animateTo(1);

      // Show success message
      _showSuccessWithPoints(
        "Redeemed ${voucher.title} successfully!", 
        voucher.pointsCost, 
        newPointsTotal
      );
    } catch (e) {
      print('Error redeeming voucher: $e');
      setState(() => _isLoading = false);
      _showError('Error redeeming voucher: $e');
    }
  }

  String _generateVoucherCode() {
    // Generate a random voucher code
    return 'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<bool> _showConfirmationDialog(Voucher voucher) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Redeem ${voucher.title}?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Redeem this voucher for ${voucher.pointsCost} points?"),
            SizedBox(height: 12),
              Text("You have ${_userPoints} points",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
              Text(
                "You will have ${_userPoints - voucher.pointsCost} points left",
                style: TextStyle(color: Colors.red),
              ),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              result = true;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text("Confirm"),
          ),
        ],
      ),
    );
    return result;
  }

  void _showVoucherDetails(Voucher voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voucher.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (voucher.imageUrl != null && voucher.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  voucher.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text(
              voucher.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.stars, color: Color(0xFF68d7cf)),
                SizedBox(width: 8),
                Text(
                  '${voucher.pointsCost} ${"points"}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF68d7cf),
                  ),
                ),
              ],
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _redeemVoucher(voucher);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF68d7cf),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Redeem Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemedVoucherDetails(RedeemedVoucher voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voucher.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (voucher.imageUrl != null && voucher.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  voucher.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text(
              voucher.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF68d7cf).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF68d7cf).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Voucher Code",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        voucher.code,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          // Copy code to clipboard
                          // Clipboard.setData(ClipboardData(text: voucher.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Copied to Clipboard"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 8),
                Text(
                  'Voucher Redeemed on: ${DateFormat('MMM dd, yyyy').format(voucher.redeemedAt)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timelapse, size: 16),
                SizedBox(width: 8),
                Text(
                  'Voucher Expiry: ${DateFormat('MMM dd, yyyy').format(voucher.expiresAt)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessWithPoints(String message, int pointsDeducted, int totalPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Check the "My Redemptions" tab to view your voucher.',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF68d7cf).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF68d7cf).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Color(0xFF68d7cf), size: 24),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '-$pointsDeducted points redeemed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF68d7cf),
                          ),
                        ),
                        Text(
                          'Remaining: $totalPoints points',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // For testing only: reset points and clear vouchers
  void _resetData() async {
    await VoucherPrefsService.resetPoints(1000);
    await VoucherPrefsService.clearRedeemedVouchers();
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Data reset: 1000 points, cleared vouchers"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildAvailableVouchersTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_availableVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
             'No vouchers available',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Points display
        Container(
          margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFF68d7cf).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF68d7cf).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.stars, color: Color(0xFF68d7cf), size: 24),
              SizedBox(width: 12),
              Text(
                'Your Points: $_userPoints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              InkWell(
                onTap: _loadData, // Refresh points
                child: Icon(Icons.refresh, color: Color(0xFF68d7cf)),
              ),
              // Development only: reset button
              SizedBox(width: 8),
              InkWell(
                onTap: _resetData,
                child: Icon(Icons.restart_alt, color: Colors.blue),
              ),
            ],
          ),
        ),
        
        // Vouchers list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _availableVouchers.length,
            itemBuilder: (context, index) {
              final voucher = _availableVouchers[index];
              bool canRedeem = _userPoints >= voucher.pointsCost;
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () => _showVoucherDetails(voucher),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (voucher.imageUrl != null && voucher.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            voucher.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          ),
                        ),
                      
                      // Content
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              voucher.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                // Points cost
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF68d7cf).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        size: 16,
                                        color: Color(0xFF68d7cf),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${voucher.pointsCost}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF68d7cf),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Spacer(),
                                
                                // Redeem button
                                ElevatedButton(
                                  onPressed: canRedeem
                                      ? () => _redeemVoucher(voucher)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canRedeem
                                        ? Color(0xFF68d7cf)
                                        : Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Redeem',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemedVouchersTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_redeemedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.redeem, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No redeemed vouchers",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _redeemedVouchers.length,
      itemBuilder: (context, index) {
        final voucher = _redeemedVouchers[index];
        final bool isExpired = DateTime.now().isAfter(voucher.expiresAt);
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => _showRedeemedVoucherDetails(voucher),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner (if expired)
                if (isExpired)
                  Container(
width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      "EXPIRED",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Image
                if (voucher.imageUrl != null && voucher.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: isExpired 
                        ? BorderRadius.zero 
                        : BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      voucher.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucher.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.grey : null,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  voucher.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isExpired ? Colors.grey : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired 
                                  ? Colors.grey.withOpacity(0.1) 
                                  : Color(0xFF68d7cf).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 16,
                                  color: isExpired ? Colors.grey : Color(0xFF68d7cf),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${voucher.pointsCost}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.grey : Color(0xFF68d7cf),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? Colors.grey.withOpacity(0.1) 
                              : Color(0xFF68d7cf).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isExpired 
                                ? Colors.grey.withOpacity(0.3) 
                                : Color(0xFF68d7cf).withOpacity(0.3)
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Voucher Code",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isExpired ? Colors.grey : null,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  voucher.code,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: isExpired ? Colors.grey : null,
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.copy, 
                                    color: isExpired ? Colors.grey : null,
                                  ),
                                  onPressed: isExpired ? null : () {
                                    // Copy code to clipboard
                                    // Clipboard.setData(ClipboardData(text: voucher.code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Copied to Clipboard"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, 
                            size: 14, 
                            color: isExpired ? Colors.grey : Colors.grey[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Redeemed: ${DateFormat('MMM dd, yyyy').format(voucher.redeemedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.grey : Colors.grey[700],
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.timelapse, 
                            size: 14, 
                            color: isExpired ? Colors.grey : Colors.grey[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(voucher.expiresAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired 
                                  ? Colors.grey 
                                  : DateTime.now().isAfter(voucher.expiresAt.subtract(Duration(days: 5))) 
                                      ? Colors.red 
                                      : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

@override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentIndex: 3, // Add the required currentIndex parameter
      
      body: Column(
        children: [
          Container(
            color: Color(0xFF67d7cf),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
                Tab(text: "Available Vouchers"),
                Tab(text: "My Redemptions"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableVouchersTab(),
                _buildRedeemedVouchersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Test page for development purposes
class VouchersTestPage extends StatelessWidget {
  const VouchersTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Vouchers'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Reset points to 1000
                await VoucherPrefsService.resetPoints();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Points reset to 1000')),
                );
              },
              child: Text('Reset Points to 1000'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Clear all redeemed vouchers
                await VoucherPrefsService.clearRedeemedVouchers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cleared all redeemed vouchers')),
                );
              },
              child: Text('Clear Redeemed Vouchers'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Add some sample redeemed vouchers for testing
                final now = DateTime.now();
                
                // Sample voucher 1 - active
                final voucher1 = RedeemedVoucher(
                  id: 'test1',
                  voucherId: 'v1',
                  title: '10% Off Any Purchase',
                  description: 'Get 10% off any purchase at our store.',
                  pointsCost: 500,
                  imageUrl: 'https://picsum.photos/id/10/500/300',
                  code: 'TEST-1234',
                  redeemedAt: now.subtract(Duration(days: 5)),
                  expiresAt: now.add(Duration(days: 25)),
                );
                
                // Sample voucher 2 - expired
                final voucher2 = RedeemedVoucher(
                  id: 'test2',
                  voucherId: 'v2',
                  title: 'Free Coffee',
                  description: 'Enjoy a free coffee at any of our locations.',
                  pointsCost: 300,
                  imageUrl: 'https://picsum.photos/id/20/500/300',
                  code: 'TEST-5678',
                  redeemedAt: now.subtract(Duration(days: 35)),
                  expiresAt: now.subtract(Duration(days: 5)),
                );
                
                // Save the vouchers
                await VoucherPrefsService.saveRedeemedVoucher(voucher1);
                await VoucherPrefsService.saveRedeemedVoucher(voucher2);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added sample redeemed vouchers')),
                );
              },
              child: Text('Add Sample Redeemed Vouchers'),
            ),
          ],
        ),
      ),
    );
  }
}