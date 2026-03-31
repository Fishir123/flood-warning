import 'dart:convert';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService();

  // Login dengan MariaDB
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _dbService.loginUser(email: email, password: password);

    if (result['success'] == true) {
      // Generate JWT token
      final token = _generateJWT(
        result['data']['id'],
        result['data']['email'],
        result['data']['name'],
      );

      return {
        'success': true,
        'data': {
          'id': result['data']['id'],
          'email': result['data']['email'],
          'name': result['data']['name'],
          'token': token,
        },
        'message': result['message'],
      };
    } else {
      return {'success': false, 'data': null, 'message': result['message']};
    }
  }

  // Register user baru
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _dbService.registerUser(
      email: email,
      password: password,
      name: name,
    );
  }

  // Generate JWT token
  String _generateJWT(String id, String email, String name) {
    // Header
    final header = base64Url.encode(
      utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
    );

    // Payload
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({
          'sub': id,
          'email': email,
          'name': name,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'exp':
              DateTime.now()
                  .add(const Duration(days: 7))
                  .millisecondsSinceEpoch ~/
              1000,
        }),
      ),
    );

    // Signature (untuk production, gunakan secret key yang aman)
    final signature = base64Url.encode(utf8.encode('flood_warning_secret'));

    return '$header.$payload.$signature';
  }

  // Decode JWT token untuk mendapatkan data user
  UserModel? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);

      return UserModel(
        id: data['sub'] ?? '',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        token: token,
      );
    } catch (e) {
      return null;
    }
  }
}
