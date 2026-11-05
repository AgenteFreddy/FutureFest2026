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
import 'constants/medical_data.dart';

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
      futureLembretes = tratamentos
          .then((lista) => lista.where((t) => t.inicio.isNotEmpty).toList())
          .catchError((_) => apiService.getLembretes());
    });
    final List<Tratamento> lista;
    try {
      lista = await tratamentos;
    } catch (e) {
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
                  errorBuilder: (context, error, stackTrace) => SizedBox(),
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
                  errorBuilder: (context, error, stackTrace) => SizedBox(),
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
                  errorBuilder: (context, error, stackTrace) => SizedBox(),
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
                  SizedBox(height: 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 800;
                        if (isMobile) {
                          return ListView(
                            children: [
                              _buildWelcomeSection(textColor),
                              SizedBox(height: 24),
                              _buildIaEkoBadge(context),
                              SizedBox(height: 16),
                              _buildActionMenu(context, cardColor, textColor),
                              SizedBox(height: 24),
                              _buildListaMedicamentos(cardColor, textColor, isDark),
                              SizedBox(height: 24),
                              _buildLembretesCustom(cardColor, textColor, isDark),
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
                                      SizedBox(height: 32),
                                      _buildListaMedicamentos(
                                        cardColor,
                                        textColor,
                                        isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildIaEkoBadge(context),
                                      SizedBox(height: 16),
                                      _buildActionMenu(
                                        context,
                                        cardColor,
                                        textColor,
                                      ),
                                      SizedBox(height: 32),
                                      _buildLembretesCustom(
                                        cardColor,
                                        textColor,
                                        isDark,
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
                            SizedBox(height: 16),
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
        tratamentos = await futureLembretes;
      } catch (_) {
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
                child: _CalendarioLembretes(
                  tratamentos: tratamentos,
                  onEditarTratamento: (tratamento) {
                    Navigator.pop(context);
                    _mostrarPopUpEdicao(this.context, tratamento);
                  },
                ),
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
            SizedBox(width: 10),
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
    required bool isDark,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF0050A0),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF0050A0)),
                tooltip: 'Atualizar dados',
                onPressed: _atualizarDashboard,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dados.length,
                separatorBuilder: (context, index) => Divider(
                  color: isDark ? Colors.grey[800] : const Color(0xFFEDF2F7),
                  height: 20,
                ),
                itemBuilder: (context, index) {
                  final t = dados[index];
                  final imagePath = index % 2 == 0
                      ? 'assets/idoso1.png'
                      : 'assets/idoso2.jpg';
                  return patientRow(
                    t,
                    imagePath,
                    cardColor,
                    textColor,
                    isDark,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListaMedicamentos(Color cardColor, Color textColor, bool isDark) {
    return _buildPatientListCard(
      title: 'Próximos Medicamentos',
      future: futureTratamentos,
      cardColor: cardColor,
      textColor: textColor,
      isDark: isDark,
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdicionarUsuarioScreen(),
                ),
              );
              // Atualiza o dashboard automaticamente ao retornar
              _atualizarDashboard();
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditarInfoScreen(),
                ),
              );
              // Atualiza TUDO no dashboard automaticamente ao voltar da tela de edição
              _atualizarDashboard();
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
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EstoqueScreen()),
              );
              // Atualiza o dashboard automaticamente ao retornar
              _atualizarDashboard();
            },
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLembretesCustom(Color cardColor, Color textColor, bool isDark) {
    return _buildPatientListCard(
      title: 'Lembretes',
      future: futureLembretes,
      cardColor: cardColor,
      textColor: textColor,
      isDark: isDark,
      emptyMessage: 'Nenhum lembrete cadastrado.',
    );
  }

  Widget patientRow(
    Tratamento t,
    String imagePath,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final horaExibicao = t.inicio.isNotEmpty
        ? t.inicio.split(' ').last
        : '--:--';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _mostrarDetalhesTratamento(t, isDark),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage(imagePath),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do Paciente
                  Text(
                    t.paciente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Medicamento + Dose + Via
                  Text(
                    '${t.medicamento}${t.dose.isNotEmpty ? " • ${t.dose}" : ""}${t.via.isNotEmpty ? " (${t.via})" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF81D4FA) : const Color(0xFF0056B3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Frequência e Observações
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      if (t.frequencia.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat, size: 12, color: Colors.green),
                            const SizedBox(width: 3),
                            Text(
                              t.frequencia,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      if (t.obs.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 12, color: Colors.orange),
                            const SizedBox(width: 3),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                t.obs,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge com Horário
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, size: 13, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        horaExibicao,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Botão Rápido de Editar Informações do Paciente
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0056B3)),
                  tooltip: 'Editar informações',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _mostrarPopUpEdicao(context, t),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhesTratamento(Tratamento t, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.paciente,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Informações do Paciente e Tratamento',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoItem(Icons.person_outline, 'Paciente', t.paciente, isDark),
                _buildInfoItem(Icons.medication, 'Medicamento', t.medicamento, isDark),
                _buildInfoItem(Icons.medical_services, 'Dose', t.dose.isEmpty ? 'Não informada' : t.dose, isDark),
                _buildInfoItem(Icons.route, 'Via de Administração', t.via.isEmpty ? 'Não informada' : t.via, isDark),
                _buildInfoItem(Icons.repeat, 'Frequência', t.frequencia.isEmpty ? 'Não informada' : t.frequencia, isDark),
                _buildInfoItem(Icons.calendar_today, 'Início', t.inicio.isEmpty ? 'Não informado' : t.inicio, isDark),
                if (t.fim.isNotEmpty)
                  _buildInfoItem(Icons.event_busy, 'Término', t.fim, isDark),
                if (t.obs.isNotEmpty)
                  _buildInfoItem(Icons.notes, 'Observações', t.obs, isDark),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Fechar', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar Informações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _mostrarPopUpEdicao(context, t);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.grey[300] : const Color(0xFF0056B3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[200] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarPopUpEdicao(BuildContext context, Tratamento tratamento) {
    final TextEditingController nomeController =
        TextEditingController(text: tratamento.paciente);
    final TextEditingController doseController =
        TextEditingController(text: tratamento.dose);
    final TextEditingController observacoesController =
        TextEditingController(text: tratamento.obs);
    final TextEditingController inicioController =
        TextEditingController(text: tratamento.inicio);
    final TextEditingController fimController =
        TextEditingController(text: tratamento.fim);

    String? remedioSelecionado = kMedicamentos.contains(tratamento.medicamento)
        ? tratamento.medicamento
        : null;
    String? viaSelecionada =
        kVias.contains(tratamento.via) ? tratamento.via : null;
    String? frequenciaSelecionada =
        kFrequencias.contains(tratamento.frequencia)
            ? tratamento.frequencia
            : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateDialog) {
            final isSmallScreen =
                MediaQuery.of(dialogContext).size.width < 600;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                          const Expanded(
                            child: Text(
                              'Editar Informações do Paciente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0056B3),
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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDialogTextField(
                                label: 'Nome do(a) Paciente',
                                controller: nomeController,
                              ),
                              const SizedBox(height: 14),
                              _buildDialogDropdown(
                                label: 'Medicamento',
                                value: remedioSelecionado,
                                items: kMedicamentos,
                                onChanged: (val) => setStateDialog(
                                  () => remedioSelecionado = val,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDialogDropdown(
                                      label: 'Via',
                                      value: viaSelecionada,
                                      items: kVias,
                                      onChanged: (val) => setStateDialog(
                                        () => viaSelecionada = val,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDialogTextField(
                                      label: 'Dose',
                                      controller: doseController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildDialogDropdown(
                                label: 'Frequência',
                                value: frequenciaSelecionada,
                                items: kFrequencias,
                                onChanged: (val) => setStateDialog(
                                  () => frequenciaSelecionada = val,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDialogDatePicker(
                                      label: 'Início',
                                      controller: inicioController,
                                      context: builderContext,
                                      setStateDialog: setStateDialog,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDialogDatePicker(
                                      label: 'Fim',
                                      controller: fimController,
                                      context: builderContext,
                                      setStateDialog: setStateDialog,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildDialogTextField(
                                label: 'Observações médicas',
                                controller: observacoesController,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(builderContext),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Salvar Alterações'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              if (tratamento.id == null) {
                                Navigator.pop(builderContext);
                                return;
                              }
                              final atualizado = Tratamento(
                                id: tratamento.id,
                                paciente: nomeController.text.trim(),
                                medicamento: remedioSelecionado ?? tratamento.medicamento,
                                via: viaSelecionada ?? tratamento.via,
                                dose: doseController.text.trim(),
                                frequencia: frequenciaSelecionada ?? tratamento.frequencia,
                                inicio: inicioController.text.trim(),
                                fim: fimController.text.trim(),
                                obs: observacoesController.text.trim(),
                              );
                              final sucesso = await apiService.updateTratamento(
                                tratamento.id!,
                                atualizado,
                              );
                              if (!builderContext.mounted) return;
                              Navigator.pop(builderContext);
                              if (sucesso) {
                                await _atualizarDashboard();
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    content: const Text(
                                      'Informações do paciente atualizadas com sucesso no Dashboard!',
                                    ),
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    content: const Text(
                                      'Erro ao atualizar informações do paciente.',
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

  Future<void> _escolherDataHora(
    BuildContext builderContext,
    TextEditingController controller,
    StateSetter setStateDialog,
  ) async {
    final DateTime agora = DateTime.now();
    DateTime? dataEscolhida = await showDatePicker(
      context: builderContext,
      initialDate: agora,
      firstDate: DateTime(2020),
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
          controller.text = '$dia/$mes/$ano $hora:$minuto';
        });
      }
    }
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF0056B3), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF0056B3), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDialogDatePicker({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    required StateSetter setStateDialog,
  }) {
    return InkWell(
      onTap: () => _escolherDataHora(context, controller, setStateDialog),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF0056B3), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF5FAFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.2),
          ),
          suffixIcon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF4CAF50)),
        ),
        child: Text(
          controller.text.isEmpty ? 'Selecionar' : controller.text,
          style: TextStyle(
            fontSize: 13,
            color: controller.text.isEmpty ? Colors.grey : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
  final void Function(Tratamento)? onEditarTratamento;
  const _CalendarioLembretes({
    required this.tratamentos,
    this.onEditarTratamento,
  });
  @override
  State<_CalendarioLembretes> createState() => _CalendarioLembretesState();
}

class _CalendarioLembretesState extends State<_CalendarioLembretes> {
  late DateTime mesAtual;
  late DateTime diaSelecionado;

  static final RegExp _regexData = RegExp(r'^(\d{2})/(\d{2})/(\d{4})');

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
    return widget.tratamentos
        .map<(int, int)?>((tratamento) {
          final inicio = _parseData(tratamento.inicio);
          if (inicio == null) return null;
          final fim = _parseData(tratamento.fim) ?? inicio;
          return (_chave(inicio), _chave(fim));
        })
        .toList(growable: false);
  }

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
        SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: GridView.builder(
            itemCount: espacosAntes + totalDiasMes,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < espacosAntes) return SizedBox.shrink();
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
                          SizedBox(height: 2),
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
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${tratamento.dose} • ${tratamento.via}\n${tratamento.frequencia}${tratamento.obs.isNotEmpty ? "\nObs: ${tratamento.obs}" : ""}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Text(
                        horario,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                      onTap: widget.onEditarTratamento != null
                          ? () => widget.onEditarTratamento!(tratamento)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
