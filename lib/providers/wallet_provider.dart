import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;
  String _email = '';
  String _fullName = '';
  String _phone = '';
  String _profilePicture = '';
  String _kycStatus = 'UNVERIFIED';
  bool _kycVerified = false;
  bool _isLoading = false;
  List<dynamic> _transactions = [];

  // Virtual account (Paystack DVA)
  String? _virtualAccountNumber;
  String? _virtualAccountBank;
  String? _virtualAccountName;
  bool _loadingVirtualAccount = false;
  bool _requireKyc = false;


  List<Map<String, String>> _bankAccounts = [];

  double get balance => _balance;
  String get email => _email;
  String get fullName => _fullName;
  String get phone => _phone;
  String get profilePicture => _profilePicture;
  String get kycStatus => _kycStatus;
  bool get kycVerified => _kycVerified;
  bool get isLoading => _isLoading;
  List<dynamic> get transactions => _transactions;
  List<Map<String, String>> get bankAccounts => _bankAccounts;

  // Virtual account getters
  String? get virtualAccountNumber => _virtualAccountNumber;
  String? get virtualAccountBank => _virtualAccountBank;
  String? get virtualAccountName => _virtualAccountName;
  bool get loadingVirtualAccount => _loadingVirtualAccount;
  bool get requireKyc => _requireKyc;

  Future<void> fetchVirtualAccount() async {
    if (_virtualAccountNumber != null) return;
    _loadingVirtualAccount = true;
    notifyListeners();
    try {
      final data = await ApiService.getVirtualAccount();
      _requireKyc = false;
      _virtualAccountNumber = data['accountNumber'];
      _virtualAccountBank = data['bankName'];
      _virtualAccountName = data['accountName'];
    } catch (e) {
      if (e.toString().contains('REQUIRE_KYC')) {
        _requireKyc = true;
      } else {
        debugPrint('Error fetching virtual account: $e');
      }
    } finally {
      _loadingVirtualAccount = false;
      notifyListeners();
    }
  }

  Future<bool> submitKyc({String? bvn, String? nin}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.submitKyc(bvn: bvn, nin: nin);
      if (data['success'] == true) {
        _requireKyc = false;
        await fetchVirtualAccount();
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting KYC: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getProfile();
      _balance = (data['balance'] as num).toDouble();
      _email = data['email'] ?? '';
      _fullName = data['fullName'] ?? '';
      _phone = data['phone'] ?? '';
      _profilePicture = data['profilePicture'] ?? '';

      _kycStatus = data['kycStatus'] ?? 'UNVERIFIED';
      _kycVerified = data['kycVerified'] ?? false;
      _transactions = data['transactions'] ?? [];
      
      try {
        // Request permissions for iOS and then get the token
        await FirebaseMessaging.instance.requestPermission();
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token fetched: $fcmToken');
        if (fcmToken != null) {
          await ApiService.saveFcmToken(fcmToken);
        } else {
          debugPrint('FCM Token is null');
        }
      } catch (fcmErr) {
        debugPrint('FCM Token error: $fcmErr');
      }

      await fetchBankAccounts();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String newFullName, String newPhone) async {
    try {
      final data = await ApiService.updateProfile(newFullName, newPhone);
      _fullName = data['fullName'] ?? '';
      _phone = data['phone'] ?? '';
      _profilePicture = data['profilePicture'] ?? '';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> uploadProfilePicture(String base64Image) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.uploadProfilePicture(base64Image);
      if (data['success'] == true) {
        if (data['user'] != null) {
          _profilePicture = data['user']['profilePicture'] ?? '';
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // ─── Legacy (FUND / CONVERT_AIRTIME) ──────────────────────────────────────
  Future<bool> processTransaction(double amount, {String type = 'TRANSACTION'}) async {
    try {
      final data = await ApiService.transact(type, amount);
      if (data['success'] == true) {
        _balance = (data['balance'] as num).toDouble();
        if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Transaction error: $e');
    }
    return false;
  }

  // ─── Withdraw ─────────────────────────────────────────────────────────────
  Future<bool> processWithdrawal(double amount, Map<String, String> account) async {
    try {
      final data = await ApiService.withdrawFunds(
        amount: amount,
        bankAccountId: account['id'] ?? '',
      );
      if (data['success'] == true) {
        _balance = (data['balance'] as num).toDouble();
        if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Withdrawal error: $e');
    }
    return false;
  }

  // ─── Airtime ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> buyAirtime({
    required String network,
    required String phone,
    required double amount,
  }) async {
    final data = await ApiService.buyAirtime(network: network, phone: phone, amount: amount);
    if (data['success'] == true) {
      _balance = (data['balance'] as num).toDouble();
      if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
      notifyListeners();
    }
    return data;
  }

  // ─── Data ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> buyData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
  }) async {
    final data = await ApiService.buyData(
      network: network,
      phone: phone,
      variationCode: variationCode,
      amount: amount,
    );
    if (data['success'] == true) {
      _balance = (data['balance'] as num).toDouble();
      if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
      notifyListeners();
    }
    return data;
  }

  // ─── SME Data ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> buySmeData({
    required String network,
    required String phone,
    required int planId,
    required double rawPrice,
  }) async {
    final data = await ApiService.buySmeData(
      network: network,
      phone: phone,
      planId: planId,
      rawPrice: rawPrice,
    );
    if (data['success'] == true) {
      _balance = (data['balance'] as num).toDouble();
      if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
      notifyListeners();
    }
    return data;
  }

  // ─── Electricity ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> payElectricity({
    required String provider,
    required String meterNumber,
    required String meterType,
    required double amount,
    required String phone,
  }) async {
    final data = await ApiService.payElectricity(
      provider: provider,
      meterNumber: meterNumber,
      meterType: meterType,
      amount: amount,
      phone: phone,
    );
    if (data['success'] == true) {
      _balance = (data['balance'] as num).toDouble();
      if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
      notifyListeners();
    }
    return data;
  }

  // ─── Cable TV ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> payCableTV({
    required String provider,
    required String smartCardNumber,
    required String variationCode,
    required double amount,
    required String phone,
  }) async {
    final data = await ApiService.payCableTV(
      provider: provider,
      smartCardNumber: smartCardNumber,
      variationCode: variationCode,
      amount: amount,
      phone: phone,
    );
    if (data['success'] == true) {
      _balance = (data['balance'] as num).toDouble();
      if (data['transaction'] != null) _transactions.insert(0, data['transaction']);
      notifyListeners();
    }
    return data;
  }

  // ─── Bank Accounts ────────────────────────────────────────────────────────
  Future<void> fetchBankAccounts() async {
    try {
      final accounts = await ApiService.getBankAccounts();
      _bankAccounts = accounts.map<Map<String, String>>((acc) => {
        'id': acc['id'].toString(),
        'bank': acc['bankName'].toString(),
        'number': acc['number'].toString(),
        'name': acc['accountName'].toString(),
        'logo': acc['bankName'].toString()[0],
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching bank accounts: $e');
    }
  }

  Future<bool> addBankAccount(String bankName, String bankCode, String accountNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.addBankAccount(
        bankName: bankName,
        bankCode: bankCode,
        accountNumber: accountNumber,
      );
      if (data['success'] == true) {
        await fetchBankAccounts();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding bank account: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> removeBankAccount(String id) async {
    try {
      final data = await ApiService.deleteBankAccount(id);
      if (data['success'] == true) {
        _bankAccounts.removeWhere((acc) => acc['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error removing bank account: $e');
    }
    return false;
  }

  void clearData() {
    _balance = 0.0;
    _email = '';
    _transactions = [];
    notifyListeners();
  }
}
