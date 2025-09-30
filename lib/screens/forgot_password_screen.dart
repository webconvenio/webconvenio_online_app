import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart'; // Importação adicionada
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _pageController = PageController();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final _cpfController = MaskedTextController(mask: '000.000.000-00');
  final _emailController = TextEditingController();
  final _mobileController = MaskedTextController(mask: '(00) 00000-0000');
  final _codeController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // --- Lógica da Etapa 1: Solicitar Código ---
  Future<void> _requestCode() async {
    // Agora todos os campos são validados pelo FormKey
    if (!_formKeyStep1.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final mobile = _mobileController.text.replaceAll(RegExp(r'\D'), '');

    setState(() {
      _isLoading = true;
    });
    final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

    try {
      // Passando Email e Mobile, agora obrigatórios
      final result = await _authService.forgotPassword(
        cpf: cleanCpf,
        email: email,
        mobile: mobile,
      );

      if (result['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
                'Código enviado com sucesso para seu Email/Celular! Prossiga para a próxima etapa.')),
          );
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Erro ao enviar código.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll(
            'Exception: ', 'Atenção: ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// --- Lógica da Etapa 2: Login com Código ---
  Future<void> _loginWithCode() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    final code = _codeController.text;

    try {
      final result = await _authService.loginWithCode(
        cpf: cleanCpf,
        validationCode: code,
      );

      if (result['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autenticação bem-sucedida!')),
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
            SnackBar(content: Text(
                result['message'] ?? 'Erro na validação do código.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll(
            'Exception: ', 'Atenção: ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
    return Column(
      children: [
        _header(context),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Impede deslizar
            children: [
              _step1RequestCode(context),
              _step2LoginWithCode(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    // Corrigido o texto do header
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
              // Idealmente, você deve ter uma imagem de reset de senha aqui
              child: const Icon(
                Icons.lock_reset,
                size: 90,
                color: Colors.white,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 20, top: 20),
              alignment: Alignment.bottomRight,
              child: const Text(
                "Recuperar Senha", // Texto corrigido
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Etapa 1 UI: Solicitar Código ---
  Widget _step1RequestCode(BuildContext context) {
    return SingleChildScrollView(
      child: Form( // FORM APLICADO CORRETAMENTE
        key: _formKeyStep1,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
              child: Text(
                "Informe seu CPF, e-mail e celular para receber o código de validação.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            _buildTextField(
              controller: _cpfController,
              hintText: "CPF (Obrigatório)",
              icon: Icons.person,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 14) {
                  return 'Por favor, insira um CPF válido.';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _emailController,
              hintText: "Email (Obrigatório)", // Dica alterada
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                // Validação de email se torna obrigatória aqui
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Por favor, insira um email válido.';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _mobileController,
              hintText: "Celular (Obrigatório)", // Dica alterada
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Validação de celular se torna obrigatória aqui (mínimo de 14 caracteres com a máscara)
                if (value == null || value.isEmpty || value.length < 14) {
                  return 'Por favor, insira um celular válido (XX) XXXXX-XXXX.';
                }
                return null;
              },
            ),
            _buildButton(
              text: "SOLICITAR CÓDIGO",
              onTap: () { // Lógica onTap corrigida
                if (!_isLoading) {
                  _requestCode();
                }
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Já tem uma conta?  "),
                  GestureDetector(
                    child: const Text(
                      "Voltar para o login",
                      style: TextStyle(color: Color(0xffF5591F)),
                    ),
                    onTap: () {
                      // Navega para a tela de login
                      Navigator.pushReplacement(
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
            if (_isLoading) const CircularProgressIndicator(), // Indicador de carregamento
          ],
        ),
      ),
    );
  }


  // --- Etapa 2 UI: Login com Código ---
  Widget _step2LoginWithCode(BuildContext context) {
    return SingleChildScrollView(
      child: Form( // FORM APLICADO CORRETAMENTE
        key: _formKeyStep2,
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 20),
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: const Text(
                "Insira o CPF e o código de validação que você recebeu para fazer o login temporário.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            _buildTextField(
              controller: _cpfController,
              hintText: "CPF (Obrigatório)",
              icon: Icons.person,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 14) {
                  return 'Por favor, insira um CPF válido.';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _codeController,
              hintText: "Código de Validação (6 dígitos)",
              icon: Icons.vpn_key,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty || value.length != 6) {
                  return 'O código deve ter 6 dígitos.';
                }
                return null;
              },
            ),
            _buildButton(
              text: "ACESSAR COM CÓDIGO",
              onTap: () { // Lógica onTap corrigida
                if (!_isLoading) {
                  _loginWithCode();
                }
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não recebeu o código? "),
                  GestureDetector(
                    child: const Text(
                      "Voltar e reenviar código",
                      style: TextStyle(color: Color(0xffF5591F)),
                    ),
                    onTap: () {
                      // Ação de voltar para a etapa 1
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_isLoading) const CircularProgressIndicator(), // Indicador de carregamento
          ],
        ),
      ),
    );
  }

  // --- Funções Auxiliares para o Novo Tema ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
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