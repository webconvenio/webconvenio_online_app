import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart'; // Importação adicionada

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = MaskedTextController(mask: '000.000.000-00');
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _passwordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      try {
        final result = await _authService.login(
          cpf: cleanCpf,
          password: _passwordController.text,
        );

        if (result['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login bem-sucedido!')),
            );
            // Navegar para a Home e remover todas as rotas anteriores
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Erro no login')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceAll(
            'Exception: ',
            'Atenção: ',
          );
          ScaffoldMessenger.of(
            context,
            //).showSnackBar(SnackBar(content: Text(e.toString())));
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return initWidget();
  }

  Widget initWidget() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context), // Header modularizado

            Form( // FORM APLICADO CORRETAMENTE
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField( // Campo CPF modularizado
                    controller: _cpfController,
                    hintText: "CPF",
                    icon: Icons.person,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 14) {
                        return 'Por favor, insira um CPF válido.';
                      }
                      return null;
                    },
                  ),
                  _buildPasswordField( // Campo Senha modularizado
                    controller: _passwordController,
                    hintText: "Senha",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha.';
                      }
                      return null;
                    },
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            )
                        );
                      },
                      child: const Text("Esqueceu a senha?"),
                    ),
                  ),

                  _buildButton( // Botão LOGIN modularizado
                    text: "LOGIN",
                    onTap: () {
                      if (!_isLoading) {
                        _login();
                      }
                    },
                  ),
                  if (_isLoading) const CircularProgressIndicator(), // Indicador de carregamento

                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Primeiro acesso?  "),
                        GestureDetector(
                          child: const Text(
                            "Crie sua conta",
                            style: TextStyle(color: Color(0xffF5591F)),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                )
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(90),
        ),
        color: const Color(0xffF5591F),
        gradient: LinearGradient(
          colors: [const Color(0xffF5591F), const Color(0xffF2861E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: const Icon( // Usando ícone placeholder, remova se usar imagem
                Icons.account_circle,
                size: 90,
                color: Colors.white,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 20, top: 20),
              alignment: Alignment.bottomRight,
              child: const Text(
                "Login",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Funções Auxiliares (Copiadas para manter o tema) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 70), // Ajuste de margem superior para o primeiro campo
      padding: const EdgeInsets.only(left: 20, right: 20),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.grey[200],
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 50,
            color: Color(0xffEEEEEE),
          ),
        ],
      ),
      child: TextFormField(
        cursorColor: const Color(0xffF5591F),
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xffF5591F)),
          hintText: hintText,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      padding: const EdgeInsets.only(left: 20, right: 20),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.grey[200],
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 50,
            color: Color(0xffEEEEEE),
          ),
        ],
      ),
      child: TextFormField(
        cursorColor: const Color(0xffF5591F),
        obscureText: !_passwordVisible,
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          icon: const Icon(Icons.vpn_key, color: Color(0xffF5591F)),
          hintText: hintText,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: const Color(0xffF5591F),
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
      ),
    );
  }


  Widget _buildButton({
    required String text,
    required VoidCallback onTap,
  }) {
    // Se estiver carregando, mostra um botão desabilitado visualmente
    final bool isDisabled = _isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 20, right: 20, top: 70),
        padding: const EdgeInsets.only(left: 20, right: 20),
        height: 54,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null // Remove gradient se desabilitado
              : LinearGradient(
            colors: [const Color(0xffF5591F), const Color(0xffF2861E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isDisabled ? Colors.grey : null, // Cor cinza se desabilitado
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 10),
              blurRadius: 50,
              color: Color(0xffEEEEEE),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDisabled ? Colors.black54 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}