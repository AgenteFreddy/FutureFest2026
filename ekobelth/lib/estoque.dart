import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'models/remedio_estoque.dart';
import 'addestoque.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  _EstoqueScreenState createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final ApiService apiService = ApiService();
  late Future<List<RemedioEstoque>> futureEstoque;
  final TextEditingController _searchController = TextEditingController();
  bool? _preferTableView;
  bool _houveMudanca = false;

  @override
  void initState() {
    super.initState();
    futureEstoque = apiService.getEstoque();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recarregarEstoque() {
    setState(() {
      futureEstoque = apiService.getEstoque();
    });
  }

  void _confirmarDelecao(RemedioEstoque item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir ${item.medicamento} do estoque?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (item.id != null) {
                  final sucesso = await apiService.deleteRemedioEstoque(item.id!);
                  if (sucesso) {
                    _houveMudanca = true;
                    _recarregarEstoque();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao deletar do servidor.')),
                      );
                    }
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final backgroundColor = isDark ? Colors.grey[900]! : const Color(0xFFFBF8EF);
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _houveMudanca);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                ],
              ),
              child: BackButton(color: isDark ? Colors.white : const Color(0xFF0056B3)),
            ),
          ),
          title: Text(
            'Estoque de Remédios',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0050A0), fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final alterou = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEstoqueScreen()),
                  );
                  if (alterou == true) {
                    _houveMudanca = true;
                    _recarregarEstoque();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Adicionar',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 720;
            final useTableView = _preferTableView ?? !isSmallScreen;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 32.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Pesquisar medicamento...',
                              hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onChanged: (value) {
                              // We could update _searchQuery and setState here if _searchQuery is not final.
                              // Wait, I made it final above in a previous fix attempt.
                              // Let's ignore _searchQuery and use _searchController.text
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            useTableView ? Icons.view_agenda_outlined : Icons.table_chart_outlined,
                            color: isDark ? Colors.white : const Color(0xFF0056B3),
                            size: 24,
                          ),
                          tooltip: useTableView ? 'Mudar para visualização em Cards' : 'Mudar para visualização em Tabela',
                          onPressed: () {
                            setState(() {
                              _preferTableView = !useTableView;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<RemedioEstoque>>(
                    future: futureEstoque,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar o estoque.\n${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'O estoque está vazio.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      // Normaliza a busca uma vez (antes era por item).
                      final busca = _searchController.text.toLowerCase();
                      final estoqueTotal = busca.isEmpty
                          ? snapshot.data!
                          : snapshot.data!.where((item) {
                              return item.medicamento.toLowerCase().contains(busca);
                            }).toList();

                      if (estoqueTotal.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum medicamento encontrado na pesquisa.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      return useTableView 
                          ? _buildTableView(estoqueTotal, isDark, cardColor, textColor, isSmallScreen)
                          : _buildCardListView(estoqueTotal, isDark, cardColor, textColor, isSmallScreen);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableView(List<RemedioEstoque> estoqueTotal, bool isDark, Color cardColor, Color textColor, bool isSmallScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 32.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DataTable(
              columnSpacing: isSmallScreen ? 24.0 : 48.0,
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => isDark ? Colors.grey[800] : const Color(0xFFEAF5E1),
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0056B3),
                fontSize: 15,
              ),
              dataTextStyle: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              columns: const [
                DataColumn(label: Text('Medicamento')),
                DataColumn(label: Text('Quantidade')),
                DataColumn(label: Text('Validade')),
                DataColumn(label: Text('Via')),
                DataColumn(label: Text('Ações')),
              ],
              rows: estoqueTotal.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.medicamento, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.quantidade,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(Text(item.dataValidade.isNotEmpty ? item.dataValidade : 'N/A')),
                    DataCell(Text(item.via.isNotEmpty ? item.via : 'N/A')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmarDelecao(item),
                        tooltip: 'Deletar',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardListView(List<RemedioEstoque> estoqueTotal, bool isDark, Color cardColor, Color textColor, bool isSmallScreen) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 32.0, vertical: 8.0),
      itemCount: estoqueTotal.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = estoqueTotal[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.grey[700]! : const Color(0xFF81D4FA).withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.medicamento,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0056B3),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.quantidade,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarDelecao(item),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Validade: ${item.dataValidade.isNotEmpty ? item.dataValidade : 'N/A'}',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Via: ${item.via.isNotEmpty ? item.via : 'N/A'}',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
