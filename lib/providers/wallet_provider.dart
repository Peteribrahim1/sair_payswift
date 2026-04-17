import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;
  bool _isLoading = false;

  double get balance => _balance;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getProfile();
      _balance = (data['balance'] as num).toDouble();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deductBalance(double amount, {String type = 'TRANSACTION'}) async {
    try {
      final data = await ApiService.transact(type, amount);
      if (data['success'] == true) {
        _balance = (data['balance'] as num).toDouble();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Transaction error: $e");
    }
    return false;
  }
}
