import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'componentes.dart';
import 'dashboard.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/sessao.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa as notificações em segundo plano, sem atrasar a abertura do app.
  unawaited(NotificationService().init());
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
    return MaterialApp(
      title: 'Ekobelth Cuidador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha email e senha.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuario = await _apiService.login(email, senha);
      Sessao.entrar(usuario);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 750;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              width: isWide ? size.width * 0.47 : size.width * 0.60,
              child: Image.asset(
                'assets/canto2ekobelth.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topLeft,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              width: isWide ? size.width * 0.28 : size.width * 0.50,
              child: Image.asset(
                'assets/cantoekobelth.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomRight,
              ),
            ),
            Positioned(
              top: isWide ? size.height * 0.18 : size.height * 0.15,
              bottom: isWide ? size.height * 0.28 : size.height * 0.15,
              left: isWide ? size.width * 0.32 : size.width * 0.10,
              width: isWide ? size.width * 0.25 : size.width * 0.65,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/folhaekobelth.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: -size.height * 0.05,
              bottom: -size.height * 0.05,
              right: isWide ? -size.width * 0.035 : -size.width * 0.15,
              width: isWide ? size.width * 0.54 : size.width * 0.85,
              child: Image.asset(
                'assets/bolinhaekobelth.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 750) {
                    return _buildLandscapeLayout(context, size, isWide);
                  } else {
                    return _buildPortraitLayout(context, size, isWide);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, Size size, bool isWide) {
    return SizedBox(
      height: size.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: size.width * 0.04),
                child: _buildLogoSection(size.height * 0.15, size, isWide),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.center,
              child: _buildFormSection(context, size, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, Size size, bool isWide) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoSection(0, size, isWide),
            const SizedBox(height: 40),
            _buildFormSection(context, size, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(double topPadding, Size size, bool isWide) {
    final logoSize = isWide ? size.width * 0.24 : size.width * 0.45;
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/LogoCool.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 5),
          Text(
            'Ekobelth',
            style: TextStyle(
              fontSize: isWide ? size.width * 0.040 : 38.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A4EDF),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'cuidador',
            style: TextStyle(
              fontSize: isWide ? size.width * 0.019 : 20.0,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A4EDF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, Size size, bool isWide) {
    return Padding(
      padding: EdgeInsets.only(right: isWide ? size.width * 0.03 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? size.width * 0.47 : size.width * 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TransparentTextField(
              hint: 'Email:',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TransparentTextField(
              hint: 'Senha:',
              isPassword: true,
              controller: _senhaController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _fazerLogin(),
            ),
            SizedBox(height: isWide ? size.height * 0.08 : 32),
            SizedBox(
              width: isWide ? size.width * 0.31 : size.width * 0.85,
              child: TransparentButton(
                text: 'Entrar',
                isLoading: _isLoading,
                onPressed: _fazerLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
