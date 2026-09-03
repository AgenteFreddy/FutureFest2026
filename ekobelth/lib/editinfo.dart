import 'package:flutter/material.dart';

class EditarInfoScreen extends StatefulWidget {
  const EditarInfoScreen({Key? key}) : super(key: key);

  @override
  _EditarInfoScreenState createState() => _EditarInfoScreenState();
}

class _EditarInfoScreenState extends State<EditarInfoScreen> {
  final List<String> listaRemedios = [
    'Paracetamol', 'Ibuprofeno', 'Amoxicilina', 'Losartana', 'Dipirona',
    'Omeprazol', 'Simeticona', 'Loratadina', 'Azitromicina', 'AAS (Ácido Acetilsalicílico)',
    'Prednisona', 'Cefalexina', 'Metformina', 'Enalapril', 'Clonazepam',
    'Fluoxetina', 'Pantoprazol', 'Diclofenaco', 'Nimesulida', 'Cetirizina',
    'Dexametasona', 'Levotiroxina', 'Sinvastatina', 'Atenolol', 'Diazepam',
  ];

  final List<String> listaVias = [
    'Oral (Comprimido)', 'Oral (Gotas)', 'Injetável', 'Tópico (Pomada)', 'Inalação',
  ];

  final List<String> listaFrequencia = [
    'A cada 4 horas', 'A cada 6 horas', 'A cada 8 horas', 'A cada 12 horas',
    '1 vez ao dia (24h)', '2 vez ao dia (24h)', '4 vez ao dia (24)',
  ];

  List<Map<String, dynamic>> tratamentos = [
    {
      "paciente": "Sr. Joaquin",
      "medicamento": "Paracetamol",
      "via": "Oral (Comprimido)",
      "dose": "2 comp.",
      "frequencia": "A cada 8 horas",
      "estoque": "30",
      "inicio": "10/09/2026 08:00",
      "fim": "15/09/2026 08:00",
      "obs": "Após as refeições"
    },
    {
      "paciente": "Dona Maria",
      "medicamento": "Losartana",
      "via": "Oral (Comprimido)",
      "dose": "1 comp.",
      "frequencia": "1 vez ao dia (24h)",
      "estoque": "60",
      "inicio": "01/09/2026 07:00",
      "fim": "",
      "obs": "Em jejum"
    },
    {
      "paciente": "Sr. Carlos",
      "medicamento": "Dipirona",
      "via": "Oral (Gotas)",
      "dose": "40 gotas",
      "frequencia": "A cada 6 horas",
      "estoque": "1 frasco",
      "inicio": "02/09/2026 14:00",
      "fim": "",
      "obs": "Apenas se tiver febre ou dor"
    },
    {
      "paciente": "Dona Ana",
      "medicamento": "Amoxicilina",
      "via": "Oral (Comprimido)",
      "dose": "1 comp.",
      "frequencia": "A cada 8 horas",
      "estoque": "21",
      "inicio": "02/09/2026 08:00",
      "fim": "09/09/2026 08:00",
      "obs": "Tomar com bastante água"
    },
    {
      "paciente": "Sr. Pedro",
      "medicamento": "Omeprazol",
      "via": "Oral (Comprimido)",
      "dose": "1 comp.",
      "frequencia": "1 vez ao dia (24h)",
      "estoque": "30",
      "inicio": "03/09/2026 06:00",
      "fim": "",
      "obs": "30 minutos antes do café da manhã"
    },
  ];

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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.0, 
                            horizontal: isSmallScreen ? 8.0 : 16.0
                          ),
                          child: DataTable(
                            columnSpacing: isSmallScreen ? 20.0 : 40.0,
                            horizontalMargin: isSmallScreen ? 12.0 : 24.0,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0056B3),
                              fontSize: 15,
                            ),
                            // ADICIONADAS AS NOVAS COLUNAS AQUI
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
                                  DataCell(Text(tratamento['paciente'])),
                                  DataCell(Text(tratamento['medicamento'])),
                                  DataCell(Text(tratamento['dose'])),
                                  DataCell(Text(tratamento['frequencia'])),
                                  DataCell(Text(tratamento['inicio']?.isEmpty ?? true ? '-' : tratamento['inicio'])),
                                  DataCell(Text(tratamento['fim']?.isEmpty ?? true ? '-' : tratamento['fim'])),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF4CAF50), size: 20),
                                      onPressed: () => _mostrarPopUpEdicao(context, tratamento, isSmallScreen),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPopUpEdicao(BuildContext context, Map<String, dynamic> tratamento, bool isSmallScreen) {
    TextEditingController nomeController = TextEditingController(text: tratamento['paciente']);
    TextEditingController quantidadeController = TextEditingController(text: tratamento['dose']);
    TextEditingController estoqueController = TextEditingController(text: tratamento['estoque']);
    TextEditingController observacoesController = TextEditingController(text: tratamento['obs']);
    TextEditingController inicioController = TextEditingController(text: tratamento['inicio']);
    TextEditingController fimController = TextEditingController(text: tratamento['fim']);

    String? remedioSelecionado = listaRemedios.contains(tratamento['medicamento']) ? tratamento['medicamento'] : null;
    String? viaSelecionada = listaVias.contains(tratamento['via']) ? tratamento['via'] : null;
    String? frequenciaSelecionada = listaFrequencia.contains(tratamento['frequencia']) ? tratamento['frequencia'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          child: _buildTextFieldLocal('Dose', quantidadeController),
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
                            (val) => setStateDialog(() => frequenciaSelecionada = val),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                labelText: 'Estoque',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _escolherDataHora(inicioController, setStateDialog),
                              child: Text(
                                inicioController.text.isEmpty ? 'Início' : 'Início:\n${inicioController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _escolherDataHora(fimController, setStateDialog),
                              child: Text(
                                fimController.text.isEmpty ? 'Fim' : 'Fim:\n${fimController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          ),
                          onPressed: () {
                            setState(() {
                              tratamento['paciente'] = nomeController.text;
                              tratamento['medicamento'] = remedioSelecionado ?? '';
                              tratamento['via'] = viaSelecionada ?? '';
                              tratamento['dose'] = quantidadeController.text;
                              tratamento['frequencia'] = frequenciaSelecionada ?? '';
                              tratamento['estoque'] = estoqueController.text;
                              tratamento['inicio'] = inicioController.text;
                              tratamento['fim'] = fimController.text;
                              tratamento['obs'] = observacoesController.text;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Salvar',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white
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

  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis));
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _escolherDataHora(TextEditingController controller, StateSetter setStateDialog) async {
    DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (dataEscolhida != null && context.mounted) {
      TimeOfDay? horaEscolhida = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (horaEscolhida != null && context.mounted) {
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