import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../screens/promocoes_screen.dart';

class MenuDrawer extends StatelessWidget {
  final String currentScreen;
  final VoidCallback onHomeTap;
  final VoidCallback onPromocoesTap;

  const MenuDrawer({
    super.key,
    required this.currentScreen,
    required this.onHomeTap,
    required this.onPromocoesTap,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header do Drawer
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffF5591F), Color(0xffF2861E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  'Bem-vindo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Itens do Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Item Minhas Faturas
                ListTile(
                  leading: const Icon(Icons.receipt, color: Color(0xffF5591F)),
                  title: const Text('Minhas Faturas'),
                  onTap: onHomeTap,
                  tileColor: currentScreen == 'home' ? Colors.orange[50] : null,
                ),

                // Item Promoções
                ListTile(
                  leading: const Icon(Icons.local_offer, color: Color(0xffF5591F)),
                  title: const Text('Promoções'),
                  onTap: onPromocoesTap,
                  tileColor: currentScreen == 'promocoes' ? Colors.orange[50] : null,
                ),

                const Divider(),

                // Configurações
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context);
                  },
                ),

                // Ajuda
                ListTile(
                  leading: const Icon(Icons.help, color: Colors.grey),
                  title: const Text('Ajuda'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context);
                  },
                ),
              ],
            ),
          ),

          // Footer do Drawer com Logout
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}