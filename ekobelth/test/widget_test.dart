import 'package:flutter_test/flutter_test.dart';

import 'package:ekobelth/main.dart';

void main() {
  testWidgets('Mostra a tela inicial do Ekobelth', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ekobelth'), findsOneWidget);
    expect(find.text('cuidador'), findsOneWidget);
  });
}
