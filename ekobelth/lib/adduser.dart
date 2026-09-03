import 'package:flutter/material.dart';
import 'componentes.dart';
import 'dashboard.dart';

class AdicionarUsuarioScreen extends StatefulWidget {
  const AdicionarUsuarioScreen({Key? key}) : super(key: key);

  @override
  _AdicionarUsuarioScreenState createState() => _AdicionarUsuarioScreenState();
}

class _AdicionarUsuarioScreenState extends State<AdicionarUsuarioScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController inicioController = TextEditingController();
  final TextEditingController fimController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController estoqueController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

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
  String? remedioSelecionado;

  final List<String> listaVias = [
    'Oral (Comprimido)',
    'Oral (Gotas)',
    'Injetável',
    'Tópico (Pomada)',
    'Inalação',
  ];
  String? viaSelecionada;

  final List<String> listaFrequencia = [
    'A cada 4 horas',
    'A cada 6 horas',
    'A cada 8 horas',
    'A cada 12 horas',
    '1 vez ao dia (24h)',
    '2 vez ao dia (24h)',
    '4 vez ao dia (24)',
  ];
  String? frequenciaSelecionada;

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
        ),
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _escolherDataHora(TextEditingController controller) async {
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
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Adicionar Usuário / Tratamento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0056B3),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                buildTextField('Nome do(a) Paciente', nomeController),

                _buildDropdownField(
                  'Selecione o Medicamento',
                  remedioSelecionado,
                  listaRemedios,
                  (val) => setState(() => remedioSelecionado = val),
                ),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDropdownField(
                        'Via',
                        viaSelecionada,
                        listaVias,
                        (val) => setState(() => viaSelecionada = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: buildTextField(
                        'Dose (ex: 2 comp.)',
                        quantidadeController,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildDropdownField(
                        'Frequência',
                        frequenciaSelecionada,
                        listaFrequencia,
                        (val) => setState(() => frequenciaSelecionada = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: estoqueController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: 'Estoque Total',
                            filled: true,
                            fillColor: Colors.white,
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
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3E5F5),
                            foregroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _escolherDataHora(inicioController),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              inicioController.text.isEmpty
                                  ? 'Data/Hora de Início'
                                  : 'Início:\n${inicioController.text}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3E5F5),
                            foregroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _escolherDataHora(fimController),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              fimController.text.isEmpty
                                  ? 'Data/Hora de Fim'
                                  : 'Fim:\n${fimController.text}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
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
                      labelText: 'Observações médicas (ex: em jejum)',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Salvar Tratamento',
                    style: TextStyle(
                      fontSize: 16,
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
    );
  }
}
