import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = MaskedTextController(mask: '000.000.000-00');
  final _emailController = TextEditingController();
  final _mobileController = MaskedTextController(mask: '(00) 00000-0000');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
      final cleanMobile = _mobileController.text.replaceAll(RegExp(r'\D'), '');

      try {
        final result = await _authService.register(
          cpf: cleanCpf,
          email: _emailController.text,
          mobile: cleanMobile,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

        if (result['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conta criada com sucesso!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result['message'])));
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
    _confirmPasswordVisible = false;
  }

  @override
  Widget build(BuildContext context) => initWidget();

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
                  _buildTextField( // Campo CPF
                    controller: _cpfController,
                    hintText: "CPF (Obrigatório)",
                    icon: Icons.person,
                    keyboardType: TextInputType.number,
                    topMargin: 70, // Maior margem para o primeiro campo
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 14) {
                        return 'Por favor, insira um CPF válido.';
                      }
                      return null;
                    },
                  ),

                  _buildTextField( // Campo Email
                    controller: _emailController,
                    hintText: "Email (Obrigatório)",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, insira um email válido.';
                      }
                      return null;
                    },
                  ),

                  _buildTextField( // Campo Celular
                    controller: _mobileController,
                    hintText: "Celular (Obrigatório)",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 14) {
                        return 'Por favor, insira um celular válido (XX) XXXXX-XXXX.';
                      }
                      return null;
                    },
                  ),

                  _buildPasswordField( // Campo Senha
                    controller: _passwordController,
                    hintText: "Senha",
                    isVisible: _passwordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha.';
                      }
                      return null;
                    },
                  ),

                  _buildPasswordField( // Campo Confirmar Senha
                    controller: _confirmPasswordController,
                    hintText: "Confirmar Senha",
                    isVisible: _confirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }
                      return null;
                    },
                  ),

                  _buildButton( // Botão REGISTRAR
                    text: "REGISTRAR",
                    onTap: () {
                      if (!_isLoading) {
                        _register(); // Chama a lógica de registro
                      }
                    },
                  ),
                  if (_isLoading) const CircularProgressIndicator(), // Indicador de carregamento

                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Já tem uma conta?  "),
                        GestureDetector(
                          child: const Text(
                            "Faça o login",
                            style: TextStyle(color: Color(0xffF5591F)),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
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
              // Usando ícone placeholder, substitua pela imagem real do app se disponível
              child: const Icon(
                Icons.person_add,
                size: 90,
                color: Colors.white,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 20, top: 20),
              alignment: Alignment.bottomRight,
              child: const Text(
                "Crie sua conta",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Funções Auxiliares (Modularização) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
    double topMargin = 20, // Padrão de 20 para campos subsequentes
  }) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(left: 20, right: 20, top: topMargin),
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
    required bool isVisible,
    required VoidCallback onToggleVisibility,
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
        obscureText: !isVisible,
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          focusColor: const Color(0xffF5591F),
          icon: const Icon(Icons.vpn_key, color: Color(0xffF5591F)),
          hintText: hintText,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: const Color(0xffF5591F),
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onTap,
  }) {
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
              ? null
              : LinearGradient(
            colors: [const Color(0xffF5591F), const Color(0xffF2861E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isDisabled ? Colors.grey : null,
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