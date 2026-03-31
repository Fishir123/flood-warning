import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySqlConnection? _connection;

  // Database configuration
  final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'flood_warning',
  );

  // Connect to database
  Future<MySqlConnection> getConnection() async {
    _connection ??= await MySqlConnection.connect(_settings);
    return _connection!;
  }

  // Close connection
  Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }

  // Hash password dengan SHA256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register user baru
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final conn = await getConnection();

      // Check apakah email sudah terdaftar
      final checkEmail = await conn.query(
        'SELECT id FROM users WHERE email = ?',
        [email],
      );

      if (checkEmail.isNotEmpty) {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }

      // Hash password
      final hashedPassword = hashPassword(password);

      // Insert user baru
      final result = await conn.query(
        'INSERT INTO users (email, password, name) VALUES (?, ?, ?)',
        [email, hashedPassword, name],
      );

      if (result.insertId != null && result.insertId! > 0) {
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'userId': result.insertId,
        };
      } else {
        return {'success': false, 'message': 'Gagal menyimpan data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Database error: ${e.toString()}'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final conn = await getConnection();

      // Hash password
      final hashedPassword = hashPassword(password);

      // Query user
      final results = await conn.query(
        'SELECT id, email, name FROM users WHERE email = ? AND password = ?',
        [email, hashedPassword],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'success': true,
          'message': 'Login berhasil',
          'data': {
            'id': row['id'].toString(),
            'email': row['email'],
            'name': row['name'],
          },
        };
      } else {
        return {'success': false, 'message': 'Email atau password salah'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Database error: ${e.toString()}'};
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      final conn = await getConnection();

      final results = await conn.query(
        'SELECT id, email, name, created_at FROM users WHERE id = ?',
        [id],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id': row['id'].toString(),
          'email': row['email'],
          'name': row['name'],
          'created_at': row['created_at'].toString(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
