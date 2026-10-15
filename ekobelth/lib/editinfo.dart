import 'package:flutter/material.dart';
import 'models/tratamento.dart';
import 'services/api_service.dart';
import 'constants/medical_data.dart';

class EditarInfoScreen extends StatefulWidget {
  const EditarInfoScreen({super.key});
  @override
  State<EditarInfoScreen> createState() => _EditarInfoScreenState();
}

class _EditarInfoScreenState extends State<EditarInfoScreen> {
  final List<String> listaRemedios = kMedicamentos;
  final List<String> listaVias = kVias;
  final List<String> listaFrequencia = kFrequencias;
  final ApiService apiService = ApiService();
  late Future<List<Tratamento>> futureTratamentos;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _preferTableView;
  bool _houveMudanca = false;
  @override
  void initState() {
    super.initState();
    futureTratamentos = apiService.getTratamentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recarregarTratamentos() {
    setState(() {
      futureTratamentos = apiService.getTratamentos();
    });
  }

  InputDecoration _customDecoration(
    String label, {
    bool isSmallScreen = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF0056B3)),
      filled: true,
      fillColor: const Color(0xFFF5FAFF),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 14 : 18,
      ),
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
    bool isSmallScreen = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
      decoration: _customDecoration(label, isSmallScreen: isSmallScreen),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool isSmallScreen = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: _customDecoration(label, isSmallScreen: isSmallScreen),
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4CAF50)),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
    StateSetter setStateDialog, {
    bool isSmallScreen = false,
  }) {
    return InkWell(
      onTap: () => _escolherDataHora(context, controller, setStateDialog),
      borderRadius: BorderRadius.circular(30),
      child: InputDecorator(
        decoration: _customDecoration(label, isSmallScreen: isSmallScreen)
            .copyWith(
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
            fontSize: isSmallScreen ? 14 : 16,
          ),
          overflow: TextOverflow.ellipsis,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0056B3)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF0056B3),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
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

  Widget _buildCardListView(List<Tratamento> tratamentos, bool isSmallScreen) {
    return ListView.separated(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      itemCount: tratamentos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tratamento = tratamentos[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF81D4FA).withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEAF5E1),
                      foregroundColor: Color(0xFF4CAF50),
                      radius: 18,
                      child: Icon(Icons.person, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tratamento.paciente,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0056B3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF5E1),
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      onPressed: () => _mostrarPopUpEdicao(
                        context,
                        tratamento,
                        isSmallScreen,
                      ),
                      tooltip: 'Editar Tratamento',
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      onPressed: () => _confirmarExclusao(context, tratamento),
                      tooltip: 'Excluir Tratamento',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF81D4FA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.medication_rounded,
                            size: 15,
                            color: Color(0xFF0056B3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tratamento.medicamento,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0056B3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tratamento.dose.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.vaccines_outlined,
                              size: 15,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tratamento.dose,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (tratamento.via.isNotEmpty)
                        _buildInfoRow(
                          Icons.route_outlined,
                          'Via',
                          tratamento.via,
                        ),
                      if (tratamento.via.isNotEmpty &&
                          tratamento.frequencia.isNotEmpty)
                        const SizedBox(height: 6),
                      if (tratamento.frequencia.isNotEmpty)
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          'Frequência',
                          tratamento.frequencia,
                        ),
                      if (tratamento.inicio.isNotEmpty ||
                          tratamento.fim.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'Período',
                          '${tratamento.inicio.isEmpty ? '-' : tratamento.inicio} ➔ ${tratamento.fim.isEmpty ? '-' : tratamento.fim}',
                        ),
                      ],
                      if (tratamento.obs.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          Icons.notes_rounded,
                          'Observações',
                          tratamento.obs,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(List<Tratamento> tratamentos, bool isSmallScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: isSmallScreen ? 16.0 : 32.0,
          ),
          child: DataTable(
            columnSpacing: isSmallScreen ? 20.0 : 36.0,
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
                  DataCell(
                    Text(
                      tratamento.paciente,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tratamento.medicamento,
                        style: const TextStyle(
                          color: Color(0xFF0056B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(tratamento.dose)),
                  DataCell(Text(tratamento.frequencia)),
                  DataCell(
                    Text(tratamento.inicio.isEmpty ? '-' : tratamento.inicio),
                  ),
                  DataCell(Text(tratamento.fim.isEmpty ? '-' : tratamento.fim)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF4CAF50),
                            size: 22,
                          ),
                          tooltip: 'Editar',
                          onPressed: () => _mostrarPopUpEdicao(
                            context,
                            tratamento,
                            isSmallScreen,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 22,
                          ),
                          tooltip: 'Excluir',
                          onPressed: () =>
                              _confirmarExclusao(context, tratamento),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 720;
        final useTableView = _preferTableView ?? !isSmallScreen;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pop(context, _houveMudanca);
          },
          child: Scaffold(
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0056B3),
                    ),
                    onPressed: () => Navigator.pop(context, _houveMudanca),
                  ),
                ),
              ),
              title: Text(
                "Editar Informações",
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0056B3),
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0056B3)),
                  tooltip: 'Recarregar',
                  onPressed: _recarregarTratamentos,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 24.0,
                      vertical: isSmallScreen ? 8.0 : 16.0,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val),
                                  decoration: InputDecoration(
                                    hintText: isSmallScreen
                                        ? 'Buscar paciente/medicamento...'
                                        : 'Buscar por nome do paciente ou medicamento...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF0056B3),
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: const Color(
                                          0xFF81D4FA,
                                        ).withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF4CAF50),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF81D4FA,
                                    ).withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    useTableView
                                        ? Icons.view_agenda_outlined
                                        : Icons.table_chart_outlined,
                                    color: const Color(0xFF0056B3),
                                    size: 20,
                                  ),
                                  tooltip: useTableView
                                      ? 'Mudar para visualização em Cards'
                                      : 'Mudar para visualização em Tabela',
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
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                isSmallScreen ? 24 : 32,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: FutureBuilder<List<Tratamento>>(
                              future: futureTratamentos,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4CAF50),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.redAccent,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Erro ao carregar tratamentos:\n${snapshot.error}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: _recarregarTratamentos,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text(
                                              'Tentar novamente',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4CAF50,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final todosTratamentos = snapshot.data ?? [];
                                // Normaliza a busca uma vez (antes era por item).
                                final q = _searchQuery.toLowerCase().trim();
                                final tratamentos = q.isEmpty
                                    ? todosTratamentos
                                    : todosTratamentos.where((t) {
                                        return t.paciente.toLowerCase().contains(q) ||
                                            t.medicamento.toLowerCase().contains(q);
                                      }).toList();
                                if (todosTratamentos.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Nenhum tratamento cadastrado.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                if (tratamentos.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Nenhum tratamento encontrado para "$_searchQuery".',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 24 : 32,
                                  ),
                                  child: useTableView
                                      ? _buildTableView(
                                          tratamentos,
                                          isSmallScreen,
                                        )
                                      : _buildCardListView(
                                          tratamentos,
                                          isSmallScreen,
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarExclusao(BuildContext context, Tratamento tratamento) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Excluir Tratamento',
            style: TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir o tratamento de ${tratamento.medicamento} para ${tratamento.paciente}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (tratamento.id != null) {
                  bool sucesso = await apiService.deleteTratamento(
                    tratamento.id!,
                  );
                  if (!mounted) return;
                  if (sucesso) {
                    _houveMudanca = true;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Tratamento excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _recarregarTratamentos();
                  } else {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao excluir tratamento.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
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
            final dialogWidth = MediaQuery.of(dialogContext).size.width;
            final dialogHeight = MediaQuery.of(dialogContext).size.height;
            final isDialogMobile = dialogWidth < 600;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDialogMobile ? 24 : 32),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isDialogMobile ? 12 : 32,
                vertical: isDialogMobile ? 16 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 750,
                  maxHeight: dialogHeight * 0.9,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDialogMobile ? 16.0 : 32.0,
                    vertical: isDialogMobile ? 20.0 : 32.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF5E1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Editar Tratamento',
                              style: TextStyle(
                                fontSize: isDialogMobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0056B3),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(builderContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                'Nome do(a) Paciente',
                                nomeController,
                                isSmallScreen: isDialogMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                'Selecione o Medicamento',
                                remedioSelecionado,
                                listaRemedios,
                                (val) => setStateDialog(
                                  () => remedioSelecionado = val,
                                ),
                                isSmallScreen: isDialogMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildResponsiveRow(
                                _buildDropdownField(
                                  'Via',
                                  viaSelecionada,
                                  listaVias,
                                  (val) => setStateDialog(
                                    () => viaSelecionada = val,
                                  ),
                                  isSmallScreen: isDialogMobile,
                                ),
                                _buildTextField(
                                  'Dose',
                                  quantidadeController,
                                  isSmallScreen: isDialogMobile,
                                ),
                                isDialogMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                'Frequência',
                                frequenciaSelecionada,
                                listaFrequencia,
                                (val) => setStateDialog(
                                  () => frequenciaSelecionada = val,
                                ),
                                isSmallScreen: isDialogMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildResponsiveRow(
                                _buildDatePickerField(
                                  'Data/Hora de Início',
                                  inicioController,
                                  builderContext,
                                  setStateDialog,
                                  isSmallScreen: isDialogMobile,
                                ),
                                _buildDatePickerField(
                                  'Data/Hora de Fim',
                                  fimController,
                                  builderContext,
                                  setStateDialog,
                                  isSmallScreen: isDialogMobile,
                                ),
                                isDialogMobile,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Observações médicas',
                                observacoesController,
                                maxLines: 3,
                                isSmallScreen: isDialogMobile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(builderContext),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDialogMobile ? 16 : 24,
                                vertical: isDialogMobile ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Salvar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isDialogMobile ? 12 : 16,
                                horizontal: isDialogMobile ? 24 : 32,
                              ),
                              elevation: 3,
                              shadowColor: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.4),
                            ),
                            onPressed: () async {
                              if (tratamento.id == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    content: const Text(
                                      'Erro: Tratamento sem ID para editar.',
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
                                _houveMudanca = true;
                                _recarregarTratamentos();
                                Navigator.pop(builderContext, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    content: const Text(
                                      'Tratamento atualizado com sucesso!',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    content: const Text(
                                      'Erro ao atualizar o tratamento.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
