import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'adduser.dart';
import 'editinfo.dart';
import 'estoque.dart';
import 'settings.dart';
import 'models/tratamento.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/sessao.dart';
import 'iaeko.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Tratamento>> futureTratamentos;
  late Future<List<Tratamento>> futureLembretes;
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final tratamentos = apiService.getTratamentos();
    setState(() {
      futureTratamentos = tratamentos;
      // Lembretes = tratamentos com data de início (mesmo filtro e ordem do
      // backend em /lembretes). Reaproveita a resposta de /tratamentos e só
      // consulta /lembretes se essa requisição falhar.
      futureLembretes = tratamentos
          .then((lista) => lista.where((t) => t.inicio.isNotEmpty).toList())
          .catchError((_) => apiService.getLembretes());
    });
    final List<Tratamento> lista;
    try {
      lista = await tratamentos;
    } catch (e) {
      // O erro já é exibido pelo FutureBuilder.
      debugPrint('Erro ao carregar tratamentos: $e');
      return;
    }
    final notificationService = NotificationService();
    try {
      await notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Erro ao cancelar notificações: $e');
    }
    final agora = DateTime.now();
    final agendamentos = <Future<void>>[];
    for (int i = 0; i < lista.length; i++) {
      final t = lista[i];
      try {
        final partes = t.inicio.split(' ');
        if (partes.length == 2) {
          final dataPartes = partes[0].split('/');
          final horaPartes = partes[1].split(':');
          final scheduledDate = DateTime(
            int.parse(dataPartes[2]),
            int.parse(dataPartes[1]),
            int.parse(dataPartes[0]),
            int.parse(horaPartes[0]),
            int.parse(horaPartes[1]),
          );
          if (scheduledDate.isAfter(agora)) {
            agendamentos.add(
              notificationService
                  .scheduleNotification(
                    id: i,
                    title: 'Hora do Medicamento: ${t.medicamento}',
                    body: 'Paciente: ${t.paciente} - Dose: ${t.dose}',
                    scheduledDate: scheduledDate,
                  )
                  .catchError((Object e) {
                    debugPrint('Erro ao agendar notificação: $e');
                  }),
            );
          }
        }
      } catch (e) {
        debugPrint('Erro ao agendar notificação: $e');
      }
    }
    await Future.wait(agendamentos);
  }

  Future<void> _atualizarDashboard() async {
    await _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color backgroundColor = isDark
        ? Colors.grey[900]!
        : const Color(0xFFFBF8EF);
    final Color cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          if (!isDark) ...[
            Positioned(
              top: 0,
              left: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/canto2ekobelth.png',
                  width: 500,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/cantoekobelth.png',
                  width: 500,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/folhaekobelth.png',
                  width: 110,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTopBar(context, cardColor),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 800;
                        if (isMobile) {
                          return ListView(
                            children: [
                              _buildWelcomeSection(textColor),
                              const SizedBox(height: 24),
                              _buildIaEkoBadge(context),
                              const SizedBox(height: 16),
                              _buildActionMenu(context, cardColor, textColor),
                              const SizedBox(height: 24),
                              _buildListaMedicamentos(cardColor, textColor),
                              const SizedBox(height: 24),
                              _buildLembretesCustom(cardColor, textColor),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildWelcomeSection(textColor),
                                      const SizedBox(height: 32),
                                      _buildListaMedicamentos(
                                        cardColor,
                                        textColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildIaEkoBadge(context),
                                      const SizedBox(height: 16),
                                      _buildActionMenu(
                                        context,
                                        cardColor,
                                        textColor,
                                      ),
                                      const SizedBox(height: 32),
                                      _buildLembretesCustom(
                                        cardColor,
                                        textColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notificações",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "As notificações automáticas estão ativas para seus medicamentos.",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 24),
                onPressed: _abrirCalendarioLembretes,
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirCalendarioLembretes() async {
    try {
      List<Tratamento> tratamentos;
      try {
        // Reaproveita os lembretes já carregados pelo dashboard (abre na hora).
        tratamentos = await futureLembretes;
      } catch (_) {
        // Se o carregamento do dashboard falhou, busca direto no servidor.
        tratamentos = await apiService.getLembretes();
      }
      if (!mounted) return;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDark = themeProvider.isDarkMode;
      final Color cardColor = isDark ? Colors.grey[850]! : Colors.white;
      final screenHeight = MediaQuery.of(context).size.height;
      final dialogHeight = (screenHeight * 0.8).clamp(0.0, 520.0);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: SizedBox(
                height: dialogHeight,
                child: _CalendarioLembretes(tratamentos: tratamentos),
              ),
            ),
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar lembretes: $erro')),
      );
    }
  }

  Widget _buildIaEkoBadge(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IaEkoScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDFF3D8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/ekologo.png',
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.water_drop,
                color: Color(0xFF4A9FD1),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'EkoIA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF4A9FD1),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estreito = constraints.maxWidth < 400;
        final double avatar = estreito ? 56 : 80;
        return Row(
          children: [
            Container(
              width: avatar,
              height: avatar,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/cuidadora.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: estreito ? 12 : 16),
            Expanded(
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: estreito ? 24 : 32,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Bem-vinda, '),
                    TextSpan(
                      text: Sessao.usuarioAtual?.primeiroNome ?? 'Cuidadora',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientListCard({
    required String title,
    required Future<List<Tratamento>> future,
    required Color cardColor,
    required Color textColor,
    required String emptyMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF0050A0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Tratamento>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Erro ao carregar dados: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 14, color: textColor),
                );
              }
              final dados = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dados.length,
                itemBuilder: (context, index) {
                  final t = dados[index];
                  final horaExibicao = t.inicio.isNotEmpty
                      ? t.inicio.split(' ').last
                      : '--:--';
                  final imagePath = index % 2 == 0
                      ? 'assets/idoso1.png'
                      : 'assets/idoso2.jpg';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: patientRow(
                      imagePath,
                      t.paciente,
                      t.medicamento,
                      horaExibicao,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListaMedicamentos(Color cardColor, Color textColor) {
    return _buildPatientListCard(
      title: 'Próximos Medicamentos',
      future: futureTratamentos,
      cardColor: cardColor,
      textColor: textColor,
      emptyMessage: 'Nenhum tratamento cadastrado.',
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: actionItem(
            Icons.group_add,
            'Adicionar Usuario',
            Colors.green,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdicionarUsuarioScreen(),
                ),
              );
              if (result == true) _atualizarDashboard();
            },
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: actionItem(
            Icons.person,
            'Editar Info',
            Colors.green,
            () async {
              final alterou = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditarInfoScreen(),
                ),
              );
              if (alterou == true) {
                _atualizarDashboard();
              }
            },
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: actionItem(
            Icons.assignment,
            'Estoque',
            Colors.green,
            () async {
              final alterou = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EstoqueScreen()),
              );
              if (alterou == true) {
                _atualizarDashboard();
              }
            },
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLembretesCustom(Color cardColor, Color textColor) {
    return _buildPatientListCard(
      title: 'Lembretes',
      future: futureLembretes,
      cardColor: cardColor,
      textColor: textColor,
      emptyMessage: 'Nenhum lembrete cadastrado.',
    );
  }

  Widget patientRow(
    String imagePath,
    String name,
    String medicamento,
    String time,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage(imagePath),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                medicamento,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget actionItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _CalendarioLembretes extends StatefulWidget {
  final List<Tratamento> tratamentos;
  const _CalendarioLembretes({required this.tratamentos});
  @override
  State<_CalendarioLembretes> createState() => _CalendarioLembretesState();
}

class _CalendarioLembretesState extends State<_CalendarioLembretes> {
  late DateTime mesAtual;
  late DateTime diaSelecionado;

  /// Compilado uma única vez (antes era recriado para cada célula).
  static final RegExp _regexData = RegExp(r'^(\d{2})/(\d{2})/(\d{4})');

  /// Intervalos (início/fim em formato yyyymmdd) já interpretados,
  /// na mesma ordem de [widget.tratamentos]. null = data inválida.
  late List<(int, int)?> _intervalos;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    mesAtual = DateTime(hoje.year, hoje.month);
    diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day);
    _intervalos = _calcularIntervalos();
  }

  @override
  void didUpdateWidget(covariant _CalendarioLembretes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tratamentos, widget.tratamentos)) {
      _intervalos = _calcularIntervalos();
    }
  }

  List<(int, int)?> _calcularIntervalos() {
    return widget.tratamentos.map<(int, int)?>((tratamento) {
      final inicio = _parseData(tratamento.inicio);
      if (inicio == null) return null;
      final fim = _parseData(tratamento.fim) ?? inicio;
      return (_chave(inicio), _chave(fim));
    }).toList(growable: false);
  }

  /// Converte uma data em um inteiro comparável (yyyymmdd).
  static int _chave(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  DateTime? _parseData(String valor) {
    final partes = _regexData.firstMatch(valor);
    if (partes == null) return null;
    return DateTime(
      int.parse(partes.group(3)!),
      int.parse(partes.group(2)!),
      int.parse(partes.group(1)!),
    );
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _temLembrete(DateTime dia) {
    final chave = _chave(dia);
    for (final intervalo in _intervalos) {
      if (intervalo != null && chave >= intervalo.$1 && chave <= intervalo.$2) {
        return true;
      }
    }
    return false;
  }

  List<Tratamento> _tratamentosDoDia(DateTime dia) {
    final chave = _chave(dia);
    final resultado = <Tratamento>[];
    for (int i = 0; i < _intervalos.length; i++) {
      final intervalo = _intervalos[i];
      if (intervalo != null && chave >= intervalo.$1 && chave <= intervalo.$2) {
        resultado.add(widget.tratamentos[i]);
      }
    }
    return resultado;
  }

  void _mudarMes(int quantidade) {
    setState(() {
      mesAtual = DateTime(mesAtual.year, mesAtual.month + quantidade);
      diaSelecionado = DateTime(mesAtual.year, mesAtual.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    const nomesMeses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    const diasSemana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final primeiroDiaMes = DateTime(mesAtual.year, mesAtual.month, 1);
    final totalDiasMes = DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
    final espacosAntes = primeiroDiaMes.weekday % 7;
    final tratamentosSelecionados = _tratamentosDoDia(diaSelecionado);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _mudarMes(-1),
              icon: Icon(Icons.chevron_left, color: textColor),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${nomesMeses[mesAtual.month - 1]} ${mesAtual.year}',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _mudarMes(1),
              icon: Icon(Icons.chevron_right, color: textColor),
            ),
          ],
        ),
        Row(
          children: diasSemana
              .map(
                (dia) => Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: GridView.builder(
            itemCount: espacosAntes + totalDiasMes,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < espacosAntes) return const SizedBox.shrink();
              final dia = DateTime(
                mesAtual.year,
                mesAtual.month,
                index - espacosAntes + 1,
              );
              final temLembrete = _temLembrete(dia);
              final selecionado = _mesmoDia(dia, diaSelecionado);
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => diaSelecionado = dia),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? Colors.green.withValues(alpha: 0.2)
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    border: selecionado
                        ? Border.all(color: Colors.green, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${dia.day}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              height: 1.1,
                              fontWeight: selecionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: temLembrete
                                  ? Colors.green
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: tratamentosSelecionados.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum remédio para este dia.',
                    style: TextStyle(color: textColor),
                  ),
                )
              : ListView.builder(
                  itemCount: tratamentosSelecionados.length,
                  itemBuilder: (context, index) {
                    final tratamento = tratamentosSelecionados[index];
                    final horario = tratamento.inicio.contains(' ')
                        ? tratamento.inicio.split(' ').last
                        : '--:--';
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.medication,
                        color: Colors.green,
                      ),
                      title: Text(
                        '${tratamento.paciente} - ${tratamento.medicamento}',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        '${tratamento.dose}\n${tratamento.via} • ${tratamento.frequencia}',
                        style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      ),
                      trailing: Text(
                        horario,
                        style: TextStyle(color: textColor),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
