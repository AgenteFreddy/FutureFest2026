import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ekobelth/dashboard.dart';
import 'package:ekobelth/providers/theme_provider.dart';

/// Renderiza o dashboard em vários tamanhos de tela. Qualquer
/// "RenderFlex overflowed" faz o teste falhar.
void main() {
  const tamanhos = <Size>[
    Size(320, 568), // celular pequeno
    Size(360, 640),
    Size(412, 915),
    Size(600, 900), // tablet retrato
    Size(800, 600), // limite do layout desktop
    Size(1280, 720),
    Size(1920, 1080),
  ];

  for (final tamanho in tamanhos) {
    for (final escala in [1.0, 1.3]) {
      testWidgets('Dashboard sem overflow em $tamanho (texto x$escala)', (
        tester,
      ) async {
        tester.view.physicalSize = tamanho;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escala)),
                child: child!,
              ),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        // Abre o calendário também.
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
      });
    }
  }
}
