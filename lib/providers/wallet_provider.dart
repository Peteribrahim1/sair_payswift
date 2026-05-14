import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;
  String _email = '';
  String _fullName = '';
  String _phone = '';
  bool _isLoading = false;
  List<dynamic> _transactions = [];

  // Virtual account (Paystack DVA)
  String? _virtualAccountNumber;
  String? _virtualAccountBank;
  String? _virtualAccountName;
  bool _loadingVirtualAccount = false;
  bool _requireKyc = false;


  final List<Map<String, String>> _bankAccounts = [
    {'bank': 'Access Bank', 'number': '0123****89', 'name': 'John Doe', 'logo': 'A'},
    {'bank': 'GTBank', 'number': '0987****21', 'name': 'John Doe', 'logo': 'G'},
  ];

  double get balance => _balance;
  String get email => _email;
  String get fullName => _fullName;
  String get phone => _phone;
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
      _transactions = data['transactions'] ?? [];
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
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
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
  void addBankAccount(String bank, String number, String name) {
    _bankAccounts.add({
      'bank': bank,
      'number': '${number.substring(0, 4)}****${number.substring(number.length - 2)}',
      'name': name,
      'logo': bank[0],
    });
    notifyListeners();
  }

  void removeBankAccount(int index) {
    if (index >= 0 && index < _bankAccounts.length) {
      _bankAccounts.removeAt(index);
      notifyListeners();
    }
  }

  void clearData() {
    _balance = 0.0;
    _email = '';
    _transactions = [];
    notifyListeners();
  }
}
