import 'package:flutter/material.dart';
import 'models/remedio_estoque.dart';
import 'services/api_service.dart';
import 'constants/medical_data.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

class AddEstoqueScreen extends StatefulWidget {
  const AddEstoqueScreen({super.key});

  @override
  _AddEstoqueScreenState createState() => _AddEstoqueScreenState();
}

class _AddEstoqueScreenState extends State<AddEstoqueScreen> {
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController validadeController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  
  final List<String> listaRemedios = kMedicamentos;
  String? remedioSelecionado;
  
  final List<String> listaVias = kVias;
  String? viaSelecionada;

  bool _isLoading = false;

  InputDecoration _customDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.blue[300] : const Color(0xFF0056B3)),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : const Color(0xFFF5FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : const Color(0xFF81D4FA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _customDecoration(label, isDark),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return DropdownButtonFormField<String>(
      decoration: _customDecoration(label, isDark),
      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4CAF50)),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, bool isDark) {
    return InkWell(
      onTap: () async {
        DateTime? dataEscolhida = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark 
                    ? const ColorScheme.dark(
                        primary: Color(0xFF4CAF50),
                        onPrimary: Colors.white,
                        onSurface: Colors.white,
                      )
                    : const ColorScheme.light(
                        primary: Color(0xFF4CAF50),
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (dataEscolhida != null && mounted) {
          setState(() {
            String dia = dataEscolhida.day.toString().padLeft(2, '0');
            String mes = dataEscolhida.month.toString().padLeft(2, '0');
            String ano = dataEscolhida.year.toString();
            controller.text = "$dia/$mes/$ano";
          });
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: InputDecorator(
        decoration: _customDecoration(label, isDark).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF4CAF50),
          ),
        ),
        child: Text(
          controller.text.isEmpty ? 'Selecionar Validade' : controller.text,
          style: TextStyle(
            color: controller.text.isEmpty
                ? (isDark ? Colors.grey[400] : Colors.grey.shade600)
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(Widget child1, Widget child2, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child1, const SizedBox(height: 16), child2],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 16),
          Expanded(child: child2),
        ],
      );
    }
  }

  void _salvarEstoque() async {
    if (remedioSelecionado == null || quantidadeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text('Preencha pelo menos o medicamento e a quantidade.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final novoRemedio = RemedioEstoque(
      medicamento: remedioSelecionado!,
      quantidade: quantidadeController.text,
      via: viaSelecionada ?? '',
      dataValidade: validadeController.text,
      observacoes: observacoesController.text,
    );

    final api = ApiService();
    bool sucesso = await api.addRemedioEstoque(novoRemedio.toJson());

    setState(() {
      _isLoading = false;
    });

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text('Remédio adicionado ao estoque com sucesso!'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text('Erro ao salvar no servidor.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final backgroundColor = isDark ? Colors.grey[900]! : const Color(0xFFEAF5E1);
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0056B3);

    return Scaffold(
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
              ],
            ),
            child: BackButton(color: isDark ? Colors.white : const Color(0xFF0056B3)),
          ),
        ),
        title: Text(
          'Estoque de Remédios',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20.0 : 40.0,
                    vertical: 20.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isMobile ? 24 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Adicionar Novo Remédio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildDropdownField(
                          'Selecione o Medicamento',
                          remedioSelecionado,
                          listaRemedios,
                          (val) => setState(() => remedioSelecionado = val),
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          _buildDropdownField(
                            'Via de Administração',
                            viaSelecionada,
                            listaVias,
                            (val) => setState(() => viaSelecionada = val),
                            isDark,
                          ),
                          _buildTextField(
                            'Quantidade',
                            quantidadeController,
                            isDark,
                            keyboardType: TextInputType.number,
                          ),
                          isMobile,
                        ),
                        const SizedBox(height: 16),
                        _buildDatePickerField(
                          'Data de Validade',
                          validadeController,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Observações (Opcional)',
                          observacoesController,
                          isDark,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 4,
                            shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                          ),
                          onPressed: _isLoading ? null : _salvarEstoque,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Adicionar ao Estoque',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
