import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'promocoes_screen.dart';
import '../components/menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _financeiroData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFinanceiroData();
  }

  Future<void> _fetchFinanceiroData() async {
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
        Uri.parse('https://webconvenio.online/api/apk/financeiro'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _financeiroData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão: $e';
      });
    }
  }

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

  Widget _buildFinanceiroContent() {
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
              onPressed: _fetchFinanceiroData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_financeiroData == null || _financeiroData!['data'] == null) {
      return const Center(
        child: Text('Nenhum dado disponível'),
      );
    }

    final dataList = _financeiroData!['data'] as List;
    if (dataList.isEmpty) {
      return const Center(
        child: Text('Nenhum dado financeiro disponível'),
      );
    }

    return ListView.builder(
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        final data = dataList[index];
        final farmacias = data['farmacias'] as List;
        return Column(
          children: farmacias.map<Widget>((farmacia) {
            return _buildFarmaciaCard(farmacia, data['limiteCredito']?.toString() ?? '0');
          }).toList(),
        );
      },
    );
  }

  Widget _buildFarmaciaCard(Map<String, dynamic> farmacia, String limiteCredito) {
    final nomeFarmacia = farmacia['nomeFarmacia']?.toString() ?? 'N/A';
    final convenios = farmacia['convenios'] as List? ?? [];

    // CORREÇÃO: Coletar todos os títulos dos convênios
    final allTitulos = <Map<String, dynamic>>[];
    for (var convenio in convenios) {
      final titulos = convenio['titulos'] as List? ?? [];
      for (var titulo in titulos) {
        if (titulo is Map<String, dynamic>) {
          allTitulos.add(titulo);
        }
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Nome da Farmácia
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xffF5591F), Color(0xffF2861E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Text(
                nomeFarmacia,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Tabela de Títulos
            _buildTitulosTable(allTitulos),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulosTable(List<Map<String, dynamic>> titulos) {
    if (titulos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhum lançamento disponível',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Agrupar títulos por mês/ano baseado na dataVencimento
    final Map<String, List<Map<String, dynamic>>> titulosPorMes = {};

    for (var titulo in titulos) {
      final dataVencimento = _safeGetString(titulo['dataVencimento']);
      final mesAno = _extrairMesAno(dataVencimento);

      if (!titulosPorMes.containsKey(mesAno)) {
        titulosPorMes[mesAno] = [];
      }
      titulosPorMes[mesAno]!.add(titulo);
    }

    // Ordenar os meses (do mais recente para o mais antigo)
    final mesesOrdenados = titulosPorMes.keys.toList()
      ..sort((a, b) => _compararMeses(b, a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lançamentos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: mesesOrdenados.map((mes) {
              return _buildMesGroup(mes, titulosPorMes[mes]!);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMesGroup(String mes, List<Map<String, dynamic>> titulosDoMes) {
    // Calcular total do mês
    double totalMes = 0.0;
    for (var titulo in titulosDoMes) {
      final saldo = _safeGetDynamic(titulo['saldo']);
      if (saldo is String) {
        totalMes += double.tryParse(saldo) ?? 0.0;
      } else if (saldo is int) {
        totalMes += saldo.toDouble();
      } else if (saldo is double) {
        totalMes += saldo;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do mês
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mes,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total: R\$${totalMes.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabela do mês
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) => Colors.grey[100],
                ),
                columns: const [
                  DataColumn(label: Text('Farmácia')),
                  DataColumn(label: Text('Lançamento')),
                  DataColumn(label: Text('Parcela')),
                  DataColumn(label: Text('Vencimento')),
                  DataColumn(label: Text('Valor (R\$)')),
                ],
                rows: titulosDoMes.map((titulo) {
                  return DataRow(cells: [
                    DataCell(Text(_safeGetString(titulo['nomeLoja']))),
                    DataCell(Text(_formatDate(_safeGetString(titulo['dataLancamento'])))),
                    DataCell(Text(_safeGetString(titulo['parcela']))),
                    DataCell(Text(_formatDate(_safeGetString(titulo['dataVencimento'])))),
                    DataCell(Text(_formatCurrency(_safeGetDynamic(titulo['saldo'])))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extrairMesAno(String dataVencimento) {
    if (dataVencimento == 'N/A' || dataVencimento.isEmpty) {
      return 'Data não informada';
    }

    try {
      final date = DateTime.parse(dataVencimento);
      final meses = [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
      ];
      return '${meses[date.month - 1]} ${date.year}';
    } catch (e) {
      // Se não conseguir parsear, tentar extrair manualmente
      final parts = dataVencimento.split('-');
      if (parts.length >= 2) {
        final ano = parts[0];
        final mes = int.tryParse(parts[1]) ?? 1;
        final meses = [
          'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
          'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
        ];
        return '${meses[mes - 1]} $ano';
      }
      return dataVencimento;
    }
  }

  int _compararMeses(String a, String b) {
    // Converter nomes dos meses para números para ordenação
    final meses = {
      'Janeiro': 1, 'Fevereiro': 2, 'Março': 3, 'Abril': 4,
      'Maio': 5, 'Junho': 6, 'Julho': 7, 'Agosto': 8,
      'Setembro': 9, 'Outubro': 10, 'Novembro': 11, 'Dezembro': 12
    };

    try {
      final partsA = a.split(' ');
      final partsB = b.split(' ');

      if (partsA.length >= 2 && partsB.length >= 2) {
        final mesA = meses[partsA[0]] ?? 1;
        final anoA = int.tryParse(partsA[1]) ?? 0;
        final mesB = meses[partsB[0]] ?? 1;
        final anoB = int.tryParse(partsB[1]) ?? 0;

        if (anoA != anoB) {
          return anoA.compareTo(anoB);
        }
        return mesA.compareTo(mesB);
      }
    } catch (e) {
      // Em caso de erro, ordenar alfabeticamente
    }

    return a.compareTo(b);
  }

  // Função segura para obter strings
  String _safeGetString(dynamic value) {
    if (value == null) return 'N/A';
    return value.toString();
  }

  // Função segura para obter qualquer tipo de dado
  dynamic _safeGetDynamic(dynamic value) {
    return value;
  }

  // Formatar valor monetário
  String _formatCurrency(dynamic value) {
    if (value == null) return '0.00';

    try {
      if (value is String) {
        final parsed = double.tryParse(value) ?? 0.0;
        return parsed.toStringAsFixed(2);
      } else if (value is int) {
        return value.toDouble().toStringAsFixed(2);
      } else if (value is double) {
        return value.toStringAsFixed(2);
      } else {
        return '0.00';
      }
    } catch (e) {
      return '0.00';
    }
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
        title: const Text('Minhas Faturas'),
        backgroundColor: const Color(0xffF5591F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFinanceiroData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      //drawer: _buildDrawer(context),
      drawer: MenuDrawer(
        currentScreen: 'home',
        onHomeTap: () {
          Navigator.pop(context);
        },
        onPromocoesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromocoesScreen()),
          );
        },
      ),
      body: _buildFinanceiroContent(),
    );
  }
}