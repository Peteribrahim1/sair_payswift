import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Local Backend URL (for Android Emulator sandbox testing)
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  // Use live Render backend
  static const String baseUrl = 'https://sair-payswift.onrender.com/api';

  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String email, String password, String fullName, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-reset-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  // ─── User ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/user/profile'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile(String fullName, String phone) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: _headers,
      body: jsonEncode({'fullName': fullName, 'phone': phone}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/profile-picture'),
      headers: _headers,
      body: jsonEncode({'profilePicture': base64Image}),
    );
    return _handleResponse(response);
  }

  // ─── Wallet / Virtual Account ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitKyc({String? bvn, String? nin}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/kyc'),
      headers: _headers,
      body: jsonEncode({'bvn': bvn, 'nin': nin}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadKycDocument(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/kyc-document'),
      headers: _headers,
      body: jsonEncode({'documentImage': base64Image}),
    );
    return _handleResponse(response);
  }

  /// Fetches (or provisions) the user's dedicated virtual account from Paystack
  static Future<Map<String, dynamic>> getVirtualAccount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/virtual-account'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ─── Convert Airtime ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> convertAirtime(String network, String phone, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/convert-airtime'),
      headers: _headers,
      body: jsonEncode({
        'network': network,
        'phone': phone,
        'amount': amount,
      }),
    );
    return _handleResponse(response);
  }

  // ─── SME Data (SMEPlug) ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchSmeDataPlans(String network) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/sme-data-plans/$network'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> buySmeData({
    required String network,
    required String phone,
    required int planId,
    required double rawPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/sme-data'),
      headers: _headers,
      body: jsonEncode({
        'network': network,
        'phone': phone,
        'planId': planId,
        'rawPrice': rawPrice,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Legacy transact (FUND / CONVERT_AIRTIME) ─────────────────────────────

  static Future<Map<String, dynamic>> transact(String type, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/transact'),
      headers: _headers,
      body: jsonEncode({'type': type, 'amount': amount}),
    );
    return _handleResponse(response);
  }

  // ─── Withdraw ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> withdrawFunds({
    required double amount,
    required String bankAccountId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/withdraw'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'bankAccountId': bankAccountId,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Bank Accounts ────────────────────────────────────────────────────────

  static Future<List<dynamic>> getBankAccounts() async {
    final response = await http.get(Uri.parse('$baseUrl/user/bank-accounts'), headers: _headers);
    final data = _handleResponse(response);
    return data['bankAccounts'] ?? [];
  }

  static Future<Map<String, dynamic>> addBankAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/bank-accounts'),
      headers: _headers,
      body: jsonEncode({
        'bankName': bankName,
        'bankCode': bankCode,
        'accountNumber': accountNumber,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteBankAccount(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/user/bank-accounts/$id'), headers: _headers);
    return _handleResponse(response);
  }

  // ─── Airtime ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> buyAirtime({
    required String network,
    required String phone,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/airtime'),
      headers: _headers,
      body: jsonEncode({'network': network, 'phone': phone, 'amount': amount}),
    );
    return _handleResponse(response);
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  /// Fetches live data plans from VTPass for a given network
  static Future<List<dynamic>> getDataPlans(String network) async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/data-plans/$network'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return data['plans'] ?? [];
  }

  static Future<Map<String, dynamic>> buyData({
    required String network,
    required String phone,
    required String variationCode,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/data'),
      headers: _headers,
      body: jsonEncode({
        'network': network,
        'phone': phone,
        'variationCode': variationCode,
        'amount': amount,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Electricity ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> payElectricity({
    required String provider,
    required String meterNumber,
    required String meterType, // 'prepaid' | 'postpaid'
    required double amount,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/electricity'),
      headers: _headers,
      body: jsonEncode({
        'provider': provider,
        'meterNumber': meterNumber,
        'meterType': meterType,
        'amount': amount,
        'phone': phone,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Cable TV ─────────────────────────────────────────────────────────────

  /// Fetches live subscription plans for a cable provider
  static Future<List<dynamic>> getCablePlans(String provider) async {
    final encodedProvider = Uri.encodeComponent(provider);
    final response = await http.get(
      Uri.parse('$baseUrl/services/cable-plans/$encodedProvider'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return data['plans'] ?? [];
  }

  /// Verify smart card / IUC number before payment
  static Future<Map<String, dynamic>> verifySmartCard({
    required String provider,
    required String smartCardNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/verify-smartcard'),
      headers: _headers,
      body: jsonEncode({'provider': provider, 'smartCardNumber': smartCardNumber}),
    );
    return _handleResponse(response);
  }

  /// Verify electricity meter number before payment
  static Future<Map<String, dynamic>> verifyMeter({
    required String provider,
    required String meterNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/verify-meter'),
      headers: _headers,
      body: jsonEncode({'provider': provider, 'meterNumber': meterNumber}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> payCableTV({
    required String provider,
    required String smartCardNumber,
    required String variationCode,
    required double amount,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/cable'),
      headers: _headers,
      body: jsonEncode({
        'provider': provider,
        'smartCardNumber': smartCardNumber,
        'variationCode': variationCode,
        'amount': amount,
        'phone': phone,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('API Error: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<void> saveFcmToken(String token) async {
    if (token.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/user/fcm-token'),
        headers: _headers,
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  static Future<Map<String, dynamic>> submitSupportTicket(String subject, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support/ticket'),
      headers: _headers,
      body: jsonEncode({'subject': subject, 'message': message}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendAiChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support/ai-chat'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(response);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    final msg = body['error'] ?? 'Unknown error';
    if (body['requireKyc'] == true) {
      throw Exception('REQUIRE_KYC');
    }
    throw Exception(msg);
  }

  // ─── News ─────────────────────────────────────────────────────────────────

  static const String newsApiKey = 'e71c0ad4b46a4b9d911ce5c43aac4d0e';

  static Future<List<dynamic>> getNews() async {
    if (newsApiKey != 'YOUR_API_KEY_HERE') {
      try {
        const url =
            'https://newsapi.org/v2/top-headlines?country=us&category=general&apiKey=$newsApiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['articles'] ?? [];
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 600));
    return [
      {'title': 'CBN Raises Interest Rate to 26.75% to Curb Inflation', 'source': {'name': 'Finance'}, 'publishedAt': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(), 'url': 'https://www.businessday.ng'},
      {'title': 'Nigerian Fintechs Raise \$500M in Q1 2026, Surpassing All Records', 'source': {'name': 'Business'}, 'publishedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), 'url': 'https://techcabal.com'},
      {'title': 'Bitcoin Surges Past \$80,000 as Institutional Demand Grows', 'source': {'name': 'Crypto'}, 'publishedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(), 'url': 'https://coindesk.com'},
      {'title': 'AI-Powered Lending Platforms Transform Credit Access in Africa', 'source': {'name': 'Technology'}, 'publishedAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(), 'url': 'https://techcabal.com'},
      {'title': 'NGX All-Share Index Climbs 2.3% on Strong Banking Sector Earnings', 'source': {'name': 'Market'}, 'publishedAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(), 'url': 'https://nairametrics.com'},
    ];
  }
}
