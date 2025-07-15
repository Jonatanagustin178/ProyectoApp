import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aplicacion_app/main.dart';

void main() {
  testWidgets('Smoke test SalaApp', (WidgetTester tester) async {
    // Construimos la app
    await tester.pumpWidget(const MyApp());

    // Verificamos que el título 'Reserva de Salas' esté en pantalla
    expect(find.text('Reserva de Salas'), findsOneWidget);

    // Verificamos que haya botones para las salas
    expect(find.text('RESERVAR'), findsWidgets);
  });
}
