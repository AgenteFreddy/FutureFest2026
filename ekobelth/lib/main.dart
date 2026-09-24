import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'componentes.dart';
import 'dashboard.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const Ekobelth(),
        );
      },
    );
  }
}

class Ekobelth extends StatefulWidget {
  const Ekobelth({super.key});

  @override
  State<Ekobelth> createState() => _EkobelthState();
}

class _EkobelthState extends State<Ekobelth> {
  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _senhaEditingController = TextEditingController();

  void _handleLogin() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/LogoCool.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 100),
                ),
                const Text(
                  'Ekobelth',
                  style: TextStyle(color: Colors.blue, fontSize: 24),
                ),
                const Text('cuidador', style: TextStyle(color: Colors.blue)),
                const SizedBox(height: 20),

                buildTextField('Email', _emailEditingController),
                buildTextField('Senha', _senhaEditingController),

                const SizedBox(height: 10),
                buildButton(
                  context,
                  'Entrar',
                  const DashboardScreen(),
                  _handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
