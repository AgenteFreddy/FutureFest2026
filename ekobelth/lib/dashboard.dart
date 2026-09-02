import 'package:flutter/material.dart';
import 'componentes.dart';
import 'adduser.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFFEAF8E5);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 40),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 32),
                          buildProximosMedicamentos(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActionMenu(context), // Passando o context aqui
                          const SizedBox(height: 32),
                          buildLembretes(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                prefixIcon: Icon(Icons.search, color: Colors.transparent),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  print("Abrir Notificações");
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 24),
                onPressed: () {
                  print("Abrir Calendário");
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 28),
                onPressed: () {
                  print("Abrir Configurações");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
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
                  const Icon(Icons.person, size: 40),
            ),
          ),
        ),
        const SizedBox(width: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: 'Bem-vindx, '),
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

  // Recebendo o context como parâmetro aqui
  Widget _buildActionMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          actionItem(Icons.group_add, 'Adicionar Usuario', Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdicionarUsuarioScreen(),
              ),
            );
          }),
          const SizedBox(height: 16),
          actionItem(Icons.settings, 'Editar Info', Colors.green, () {
            print("Editar Info Clicado");
          }),
          const SizedBox(height: 16),
          actionItem(
            Icons.medication,
            'Adicionar medicamento',
            Colors.greenAccent.shade400,
            () {
              print("Adicionar Medicamento Clicado");
            },
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}