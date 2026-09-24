import 'package:flutter/material.dart';
import 'models/tratamento.dart';
import 'services/api_service.dart';

class EditarInfoScreen extends StatefulWidget {
  const EditarInfoScreen({super.key});

  @override
  State<EditarInfoScreen> createState() => _EditarInfoScreenState();
}

class _EditarInfoScreenState extends State<EditarInfoScreen> {
  final List<String> listaRemedios = [
    'Paracetamol',
    'Ibuprofeno',
    'Amoxicilina',
    'Losartana',
    'Dipirona',
    'Omeprazol',
    'Simeticona',
    'Loratadina',
    'Azitromicina',
    'AAS (Ácido Acetilsalicílico)',
    'Prednisona',
    'Cefalexina',
    'Metformina',
    'Enalapril',
    'Clonazepam',
    'Fluoxetina',
    'Pantoprazol',
    'Diclofenaco',
    'Nimesulida',
    'Cetirizina',
    'Dexametasona',
    'Levotiroxina',
    'Sinvastatina',
    'Atenolol',
    'Diazepam',
  ];

  final List<String> listaVias = [
    'Oral (Comprimido)',
    'Oral (Gotas)',
    'Injetável',
    'Tópico (Pomada)',
    'Inalação',
  ];

  final List<String> listaFrequencia = [
    'A cada 4 horas',
    'A cada 6 horas',
    'A cada 8 horas',
    'A cada 12 horas',
    '1 vez ao dia (24h)',
    '2 vezes ao dia (24h)',
    '4 vezes ao dia (24h)',
  ];

  final ApiService apiService = ApiService();
  late Future<List<Tratamento>> futureTratamentos;

  @override
  void initState() {
    super.initState();
    futureTratamentos = apiService.getTratamentos();
  }

  void _recarregarTratamentos() {
    setState(() {
      futureTratamentos = apiService.getTratamentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5E1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Text(
                      "Editar Informações",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0056B3),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 20 : 32),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: FutureBuilder<List<Tratamento>>(
                    future: futureTratamentos,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar tratamentos: ${snapshot.error}',
                          ),
                        );
                      }

                      final tratamentos = snapshot.data ?? [];

                      if (tratamentos.isEmpty) {
                        return const Center(
                          child: Text('Nenhum tratamento cadastrado.'),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: isSmallScreen ? 8.0 : 16.0,
                              ),
                              child: DataTable(
                                columnSpacing: isSmallScreen ? 20.0 : 40.0,
                                horizontalMargin: isSmallScreen ? 12.0 : 24.0,
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0056B3),
                                  fontSize: 15,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Paciente')),
                                  DataColumn(label: Text('Medicamento')),
                                  DataColumn(label: Text('Dose')),
                                  DataColumn(label: Text('Frequência')),
                                  DataColumn(label: Text('Início')),
                                  DataColumn(label: Text('Fim')),
                                  DataColumn(label: Text('Ações')),
                                ],
                                rows: tratamentos.map((tratamento) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tratamento.paciente)),
                                      DataCell(Text(tratamento.medicamento)),
                                      DataCell(Text(tratamento.dose)),
                                      DataCell(Text(tratamento.frequencia)),
                                      DataCell(
                                        Text(
                                          tratamento.inicio.isEmpty
                                              ? '-'
                                              : tratamento.inicio,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          tratamento.fim.isEmpty
                                              ? '-'
                                              : tratamento.fim,
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Color(0xFF4CAF50),
                                            size: 20,
                                          ),
                                          onPressed: () => _mostrarPopUpEdicao(
                                            context,
                                            tratamento,
                                            isSmallScreen,
                                          ),
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPopUpEdicao(
    BuildContext context,
    Tratamento tratamento,
    bool isSmallScreen,
  ) {
    TextEditingController nomeController = TextEditingController(
      text: tratamento.paciente,
    );
    TextEditingController quantidadeController = TextEditingController(
      text: tratamento.dose,
    );
    TextEditingController estoqueController = TextEditingController(
      text: tratamento.estoque,
    );
    TextEditingController observacoesController = TextEditingController(
      text: tratamento.obs,
    );
    TextEditingController inicioController = TextEditingController(
      text: tratamento.inicio,
    );
    TextEditingController fimController = TextEditingController(
      text: tratamento.fim,
    );

    String? remedioSelecionado = listaRemedios.contains(tratamento.medicamento)
        ? tratamento.medicamento
        : null;
    String? viaSelecionada = listaVias.contains(tratamento.via)
        ? tratamento.via
        : null;
    String? frequenciaSelecionada =
        listaFrequencia.contains(tratamento.frequencia)
        ? tratamento.frequencia
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.all(isSmallScreen ? 12 : 24),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Editar Usuário / Tratamento',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0056B3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    _buildTextFieldLocal('Nome do(a) Paciente', nomeController),

                    _buildDropdownField(
                      'Selecione o Medicamento',
                      remedioSelecionado,
                      listaRemedios,
                      (val) => setStateDialog(() => remedioSelecionado = val),
                    ),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildDropdownField(
                            'Via',
                            viaSelecionada,
                            listaVias,
                            (val) => setStateDialog(() => viaSelecionada = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildTextFieldLocal(
                            'Dose',
                            quantidadeController,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDropdownField(
                            'Frequência',
                            frequenciaSelecionada,
                            listaFrequencia,
                            (val) => setStateDialog(
                              () => frequenciaSelecionada = val,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: estoqueController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelText: 'Estoque',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3E5F5),
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => _escolherDataHora(
                                builderContext,
                                inicioController,
                                setStateDialog,
                              ),
                              child: Text(
                                inicioController.text.isEmpty
                                    ? 'Início'
                                    : 'Início:\n${inicioController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3E5F5),
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => _escolherDataHora(
                                builderContext,
                                fimController,
                                setStateDialog,
                              ),
                              child: Text(
                                fimController.text.isEmpty
                                    ? 'Fim'
                                    : 'Fim:\n${fimController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: observacoesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: 'Observações médicas',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(builderContext),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                          ),
                          onPressed: () async {
                            if (tratamento.id == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tratamento sem id para editar.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final tratamentoAtualizado = Tratamento(
                              id: tratamento.id,
                              paciente: nomeController.text,
                              medicamento: remedioSelecionado ?? '',
                              via: viaSelecionada ?? '',
                              dose: quantidadeController.text,
                              frequencia: frequenciaSelecionada ?? '',
                              estoque: estoqueController.text,
                              inicio: inicioController.text,
                              fim: fimController.text,
                              obs: observacoesController.text,
                            );

                            final sucesso = await apiService.updateTratamento(
                              tratamento.id!,
                              tratamentoAtualizado,
                            );

                            if (!builderContext.mounted) return;

                            if (sucesso) {
                              _recarregarTratamentos();
                              Navigator.pop(builderContext, true);
                            } else {
                              Navigator.pop(builderContext, false);
                            }
                          },
                          child: Text(
                            'Salvar',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        initialValue: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextFieldLocal(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _escolherDataHora(
    BuildContext builderContext,
    TextEditingController controller,
    StateSetter setStateDialog,
  ) async {
    DateTime? dataEscolhida = await showDatePicker(
      context: builderContext,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (dataEscolhida != null && builderContext.mounted) {
      TimeOfDay? horaEscolhida = await showTimePicker(
        context: builderContext,
        initialTime: TimeOfDay.now(),
      );

      if (horaEscolhida != null && builderContext.mounted) {
        setStateDialog(() {
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
}
