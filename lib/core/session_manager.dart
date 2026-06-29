import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;
  final int expiresIn;
  final String deviceId;

  Session({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.expiresIn,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'role': role,
    'expiresIn': expiresIn,
    'deviceId': deviceId,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['accessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
    userId: json['userId'] ?? '',
    role: json['role'] ?? '',
    expiresIn: json['expiresIn'] ?? 0,
    deviceId: json['deviceId'] ?? '',
  );
}

class SessionManager {
  final FlutterSecureStorage _storage;

  SessionManager(this._storage);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: 'accessToken');
  Future<String?> getRefreshToken() async => await _storage.read(key: 'refreshToken');

  Future<void> clearSessionInstance() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'session_data');
  }

  static Future<void> saveSession({
    String? accessToken,
    String? authToken,
    String? refreshToken,
    String? email,
    String? name,
    String? mobileNumber,
    String? gender,
    String? dob,
    String? profilePhotoUrl,
    double? walletBalance,
    dynamic selectedBranch,
    String? userId,
    String? role,
    int? expiresIn,
    String? deviceId,
  }) async {
    final token = accessToken ?? authToken ?? '';
    final refresh = refreshToken ?? '';
    const storage = FlutterSecureStorage();
    final session = Session(
      accessToken: token,
      refreshToken: refresh,
      userId: userId ?? 'unknown_user',
      role: role ?? 'ROLE_CUSTOMER',
      expiresIn: expiresIn ?? 3600,
      deviceId: deviceId ?? 'unknown_device',
    );
    await storage.write(key: 'accessToken', value: token);
    await storage.write(key: 'refreshToken', value: refresh);
    await storage.write(key: 'session_data', value: json.encode(session.toJson()));
  }

  static Future<void> clearSession() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'session_data');
  }

  static Future<void> updateWalletBalance(double balance) async {
    // No-op: Profile loads dynamically via API
  }

  static Future<Session?> loadSession() async {
    const storage = FlutterSecureStorage();
    final data = await storage.read(key: 'session_data');
    if (data == null) return null;
    try {
      return Session.fromJson(json.decode(data));
    } catch (_) {
      return null;
    }
  }
}
