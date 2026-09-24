import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'componentes.dart';
import 'adduser.dart';
import 'editinfo.dart';
import 'settings.dart';
import 'models/tratamento.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Tratamento>> futureTratamentos;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      futureTratamentos = apiService.getTratamentos();
    });

    final tratamentos = await futureTratamentos;
    final notificationService = NotificationService();
    await notificationService.cancelAllNotifications();

    for (int i = 0; i < tratamentos.length; i++) {
      final t = tratamentos[i];
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

          if (scheduledDate.isAfter(DateTime.now())) {
            await notificationService.scheduleNotification(
              id: i,
              title: 'Hora do Medicamento: ${t.medicamento}',
              body: 'Paciente: ${t.paciente} - Dose: ${t.dose}',
              scheduledDate: scheduledDate,
            );
          }
        }
      } catch (e) {
        debugPrint('Erro ao agendar notificação: $e');
      }
    }
  }

  void _atualizarDashboard() {
    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color backgroundColor = isDark
        ? Colors.grey[900]!
        : const Color(0xFFEAF8E5);
    final Color cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(textColor),
                                const SizedBox(height: 32),
                                Expanded(
                                  child: _buildListaMedicamentos(
                                    cardColor,
                                    textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildActionMenu(context, cardColor, textColor),
                                const SizedBox(height: 32),
                                _buildLembretesCustom(cardColor, textColor),
                              ],
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
    );
  }

  Widget _buildTopBar(BuildContext context, Color cardColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
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
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirCalendarioLembretes() async {
    try {
      final tratamentos = await apiService.getLembretes();
      if (!mounted) return;

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDark = themeProvider.isDarkMode;
      final Color cardColor = isDark ? Colors.grey[850]! : Colors.white;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 470,
              width: 350,
              child: _CalendarioLembretes(tratamentos: tratamentos),
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

  Widget _buildWelcomeSection(Color textColor) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
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
        const SizedBox(width: 16),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 32,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(text: 'Bem-vinda, '),
              TextSpan(
                text: 'Iza',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListaMedicamentos(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximos Medicamentos',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF0050A0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Tratamento>>(
            future: futureTratamentos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Erro ao carregar dados: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Nenhum tratamento cadastrado.');
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final t = snapshot.data![index];
                  String horaExibicao = t.inicio.isNotEmpty
                      ? t.inicio.split(' ').last
                      : '--:--';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: patientRow(
                      'assets/idoso1.png',
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

  Widget _buildActionMenu(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          actionItem(Icons.group_add, 'Adicionar', Colors.green, () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdicionarUsuarioScreen(),
              ),
            );
            if (result == true) _atualizarDashboard();
          }, textColor: textColor),
          const SizedBox(height: 16),
          actionItem(Icons.person, 'Editar', Colors.green, () async {
            final alterou = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditarInfoScreen()),
            );
            if (alterou == true) {
              _atualizarDashboard();
            }
          }, textColor: textColor),
        ],
      ),
    );
  }

  Widget _buildLembretesCustom(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lembretes',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF0050A0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum lembrete cadastrado.',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    mesAtual = DateTime(hoje.year, hoje.month);
    diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day);
  }

  DateTime? _parseData(String valor) {
    final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(valor);
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

  List<Tratamento> _tratamentosDoDia(DateTime dia) {
    return widget.tratamentos.where((tratamento) {
      final inicio = _parseData(tratamento.inicio);
      if (inicio == null) return false;

      final fim = _parseData(tratamento.fim) ?? inicio;
      final dataInicio = DateTime(inicio.year, inicio.month, inicio.day);
      final dataFim = DateTime(fim.year, fim.month, fim.day);
      final dataDia = DateTime(dia.year, dia.month, dia.day);

      return !dataDia.isBefore(dataInicio) && !dataDia.isAfter(dataFim);
    }).toList();
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
            Text(
              '${nomesMeses[mesAtual.month - 1]} ${mesAtual.year}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
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
            ),
            itemBuilder: (context, index) {
              if (index < espacosAntes) return const SizedBox.shrink();

              final dia = DateTime(
                mesAtual.year,
                mesAtual.month,
                index - espacosAntes + 1,
              );
              final temLembrete = _tratamentosDoDia(dia).isNotEmpty;
              final selecionado = _mesmoDia(dia, diaSelecionado);

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => diaSelecionado = dia),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: selecionado ? Colors.green.withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(24),
                    border: selecionado
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${dia.day}', style: TextStyle(color: textColor)),
                      const SizedBox(height: 3),
                      Container(
                        width: 7,
                        height: 7,
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
                        tratamento.paciente,
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        '${tratamento.medicamento} • ${tratamento.dose}\n${tratamento.via} • ${tratamento.frequencia}',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
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
