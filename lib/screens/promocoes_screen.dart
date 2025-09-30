import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../components/menu_drawer.dart';

class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
  List<dynamic> _promocoesData = [];
  List<dynamic> _promocoesFiltradas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchPromocoesData();
  }

  Future<void> _fetchPromocoesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Token de autenticação não encontrado';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://webconvenio.online/api/apk/promocao'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _promocoesData = data['data'] ?? [];
          _promocoesFiltradas = List.from(_promocoesData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar promoções: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão: $e';
      });
    }
  }


  void _filtrarPromocoes(String query) {
    setState(() {
      if (query.isEmpty) {
        _promocoesFiltradas = List.from(_promocoesData);
        _isSearching = false;
      } else {
        _isSearching = true;

        // CORREÇÃO: Filtro mais robusto
        _promocoesFiltradas = _promocoesData.map((promocao) {
          final produtos = promocao['produtos'] as List? ?? [];

          // CORREÇÃO: Filtra produtos que contenham o termo de busca
          final produtosFiltrados = produtos.where((produto) {
            final nomeProduto = produto['NomeProduto']?.toString().toLowerCase() ?? '';
            final termoBusca = query.toLowerCase().trim();

            // CORREÇÃO: Verifica se o termo está contido no nome do produto
            return nomeProduto.contains(termoBusca);
          }).toList();

          // CORREÇÃO: Retorna promoção apenas se tiver produtos após o filtro
          if (produtosFiltrados.isNotEmpty) {
            return {
              ...promocao,
              'produtos': produtosFiltrados,
            };
          }
          return null;
        }).where((promocao) => promocao != null).toList();
      }
    });
  }

  void _limparPesquisa() {
    _searchController.clear();
    setState(() {
      _promocoesFiltradas = List.from(_promocoesData);
      _isSearching = false;
    });
  }

  void _abrirPesquisa() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pesquisar Produto'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do produto...',
            border: OutlineInputBorder(),
          ),
          onChanged: _filtrarPromocoes,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _limparPesquisa();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  /*Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
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

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt, color: Color(0xffF5591F)),
                  title: const Text('Minhas Faturas'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Volta para a home
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.local_offer, color: Color(0xffF5591F)),
                  title: const Text(
                    'Promoções',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  tileColor: Colors.orange[50],
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context);
                  },
                ),

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
  }*/

  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchPromocoesData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    /*if (_promocoesData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Nenhuma promoção disponível',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }*/
    if (_promocoesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.local_offer,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _isSearching
                  ? 'Nenhum produto encontrado\npara "${_searchController.text}"'
                  : 'Nenhuma promoção disponível',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isSearching) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _limparPesquisa,
                child: const Text('Limpar Pesquisa'),
              ),
            ],
          ],
        ),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final crossAxisCount = orientation == Orientation.landscape ? 4 : 2;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _promocoesData.length,
          itemBuilder: (context, index) {
            final promocao = _promocoesData[index];
            final produtos = promocao['produtos'] as List? ?? [];

            if (produtos.isEmpty) {
              return Container();
            }

            return _buildPromocaoSection(promocao, produtos, crossAxisCount);
          },
        );
      },
    );
  }

  Widget _buildPromocaoSection(Map<String, dynamic> promocao, List<dynamic> produtos, int crossAxisCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da Promoção
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffF5591F), Color(0xffF2861E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promocao['nomeFarmacia']?.toString() ?? 'Farmácia',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                promocao['NomePromocao']?.toString() ?? 'Promoção',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Válida até: ${_formatDate(promocao['DataFim']?.toString())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Grid de Produtos
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: produtos.length,
          itemBuilder: (context, index) {
            return _buildProductCard(produtos[index]);
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produto) {
    final precoVenda = double.tryParse(produto['PrecoVenda']?.toString() ?? '0') ?? 0;
    final precoPromocao = double.tryParse(produto['PrecoPromocao']?.toString() ?? '0') ?? 0;
    final desconto = precoVenda > 0 ? ((precoVenda - precoPromocao) / precoVenda * 100) : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container da Imagem com Badge
            Stack(
              children: [
                // Imagem do Produto
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(produto['imagemProduto']?.toString() ?? ''),
                      fit: BoxFit.cover,
                      /*errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },*/
                    ),
                  ),
                ),

                // Badge de Desconto
                if (desconto > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${desconto.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Informações do Produto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do Produto
                  Text(
                    produto['NomeProduto']?.toString() ?? 'Produto',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Preço Original (riscado)
                  if (precoVenda > precoPromocao)
                    Text(
                      'De: R\$${precoVenda.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),

                  // Preço Promocional
                  Text(
                    'Por: R\$${precoPromocao.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffF5591F),
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

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promoções'),
        backgroundColor: const Color(0xffF5591F),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _abrirPesquisa,
            tooltip: 'Pesquisar produtos',
          ),
          /*IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPromocoesData,
            tooltip: 'Recarregar promoções',
          ),*/
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      drawer: MenuDrawer(
        currentScreen: 'promocoes',
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onPromocoesTap: () {
          Navigator.pop(context);
        },
      ),
      body: _buildContent(),
    );
  }
}