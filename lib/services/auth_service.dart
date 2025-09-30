import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'https://webconvenio.online/api';

  Future<Map<String, dynamic>> checkCpf(String cpf) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/check-cpf'),
      headers: {"Accept": "application/json"},
      body: {'cpf': cpf},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register({
    required String cpf,
    required String email,
    required String mobile,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {"Accept": "application/json"},
      body: {
        'cpf': cpf,
        'email': email,
        'celular': mobile,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login({
    required String cpf,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {"Accept": "application/json"},
      body: {'cpf': cpf, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Erro de login');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String cpf,
    String? email,
    String? mobile,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgotpassword'),
      headers: {"Accept": "application/json"},
      body: {
        'cpf': cpf,
        'email': email,
        'celular': mobile,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao solicitar código de recuperação.');
    }
  }

  Future<Map<String, dynamic>> loginWithCode({
    required String cpf,
    required String validationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/loginwithcode'),
      headers: {"Accept": "application/json"},
      body: {
        'cpf': cpf,
        'code': validationCode,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Salva o token da mesma forma que o login normal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Código de validação incorreto.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}