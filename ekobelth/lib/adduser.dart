import 'package:flutter/material.dart';
import 'models/tratamento.dart';
import 'services/api_service.dart';
import 'constants/medical_data.dart';

class AdicionarUsuarioScreen extends StatefulWidget {
  const AdicionarUsuarioScreen({super.key});
  @override
  _AdicionarUsuarioScreenState createState() => _AdicionarUsuarioScreenState();
}

class _AdicionarUsuarioScreenState extends State<AdicionarUsuarioScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController inicioController = TextEditingController();
  final TextEditingController fimController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  final List<String> listaRemedios = kMedicamentos;
  String? remedioSelecionado;
  final List<String> listaVias = kVias;
  String? viaSelecionada;
  final List<String> listaFrequencia = kFrequencias;
  String? frequenciaSelecionada;
  InputDecoration _customDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF0056B3)),
      filled: true,
      fillColor: const Color(0xFFF5FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.5),
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
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _customDecoration(label),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: _customDecoration(label),
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4CAF50)),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return InkWell(
      onTap: () => _escolherDataHora(controller),
      borderRadius: BorderRadius.circular(30),
      child: InputDecorator(
        decoration: _customDecoration(label).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF4CAF50),
          ),
        ),
        child: Text(
          controller.text.isEmpty ? 'Selecionar' : controller.text,
          style: TextStyle(
            color: controller.text.isEmpty
                ? Colors.grey.shade600
                : Colors.black87,
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

  Future<void> _escolherDataHora(TextEditingController controller) async {
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      TimeOfDay? horaEscolhida = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (horaEscolhida != null && mounted) {
        setState(() {
          String dia = dataEscolhida.day.toString().padLeft(2, '0');
          String mes = dataEscolhida.month.toString().padLeft(2, '0');
          String ano = dataEscolhida.year.toString();
          String hora = horaEscolhida.hour.toString().padLeft(2, '0');
          String minuto = horaEscolhida.minute.toString().padLeft(2, '0');
          controller.text = "$dia/$mes/$ano $hora:$minuto";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
              ],
            ),
            child: const BackButton(color: Color(0xFF0056B3)),
          ),
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
                      color: Colors.white,
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
                        const Text(
                          'Adicionar Usuário / Tratamento',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0056B3),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildTextField('Nome do(a) Paciente', nomeController),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          'Selecione o Medicamento',
                          remedioSelecionado,
                          listaRemedios,
                          (val) => setState(() => remedioSelecionado = val),
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          _buildDropdownField(
                            'Via',
                            viaSelecionada,
                            listaVias,
                            (val) => setState(() => viaSelecionada = val),
                          ),
                          _buildTextField('Dose', quantidadeController),
                          isMobile,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          'Frequência',
                          frequenciaSelecionada,
                          listaFrequencia,
                          (val) => setState(() => frequenciaSelecionada = val),
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          _buildDatePickerField(
                            'Data/Hora de Início',
                            inicioController,
                          ),
                          _buildDatePickerField(
                            'Data/Hora de Fim',
                            fimController,
                          ),
                          isMobile,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Observações médicas (ex: em jejum)',
                          observacoesController,
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
                            shadowColor: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.5),
                          ),
                          onPressed: () async {
                            if (nomeController.text.isEmpty ||
                                remedioSelecionado == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  content: const Text(
                                    'Preencha pelo menos o nome e o medicamento.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final novoTratamento = Tratamento(
                              paciente: nomeController.text,
                              medicamento: remedioSelecionado!,
                              via: viaSelecionada ?? '',
                              dose: quantidadeController.text,
                              frequencia: frequenciaSelecionada ?? '',
                              inicio: inicioController.text,
                              fim: fimController.text,
                              obs: observacoesController.text,
                            );
                            final api = ApiService();
                            bool sucesso = await api.addTratamento(
                              novoTratamento,
                            );
                            if (sucesso && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  content: const Text(
                                    'Tratamento salvo com sucesso!',
                                  ),
                                ),
                              );
                              Navigator.pop(context, true);
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  content: const Text(
                                    'Erro ao salvar no servidor.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Salvar Tratamento',
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
