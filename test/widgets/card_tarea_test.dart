import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aplicacion_app/l10n/app_localizations.dart';

// Importar los modelos y providers necesarios
import 'package:aplicacion_app/models/models.dart';
import 'package:aplicacion_app/provider/provider_reservaciones.dart';
import 'package:aplicacion_app/main.dart'; // Para acceder a SalaCard

void main() {
  testWidgets('SalaCard muestra información de la sala correctamente', (
    WidgetTester tester,
  ) async {
    // Crear una sala de prueba con datos conocidos
    final salaTest = Sala(
      id: '1', // ID como String según el modelo
      nombre: 'Sala de Juntas A', // Nombre específico para la prueba
      capacidad: 10, // Capacidad conocida
      ubicacion: 'Piso 2', // Ubicación específica
      imagenAsset: 'assets/sala1.jpeg', // Imagen por defecto
      isReservada: false, // Estado inicial: disponible
    );

    // Crear provider con datos de prueba
    final reservasProvider = ReservasProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Provider con datos simulados de reservas
          ChangeNotifierProvider<ReservasProvider>.value(
            value: reservasProvider,
          ),
        ],
        child: MaterialApp(
          // Configurar localizaciones para español
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')], // Solo español para la prueba
          locale: const Locale('es'),
          home: Scaffold(
            body: SalaCard(sala: salaTest), // Widget bajo prueba
          ),
        ),
      ),
    );

    // Esperar a que se complete la construcción del widget
    await tester.pumpAndSettle();

    // Verificar que el nombre de la sala se muestra correctamente
    expect(find.text('Sala de Juntas A'), findsOneWidget);

    // Verificar que la capacidad se muestra con el formato correcto
    expect(find.textContaining('10'), findsAtLeastNWidgets(1));

    // Verificar que la ubicación se muestra
    expect(find.textContaining('Piso 2'), findsAtLeastNWidgets(1));

    // Verificar que se muestra el estado "Disponible" cuando no está reservada
    expect(find.textContaining('Disponible'), findsAtLeastNWidgets(1));
  });

  testWidgets('SalaCard muestra estado reservado correctamente', (
    WidgetTester tester,
  ) async {
    // Crear una sala de prueba en estado reservado
    final salaReservada = Sala(
      id: '2', // ID como String
      nombre: 'Sala de Conferencias B',
      capacidad: 20,
      ubicacion: 'Piso 3',
      imagenAsset: 'assets/sala2.jpeg',
      isReservada: true, // Estado: reservada
    );

    final reservasProvider = ReservasProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservasProvider>.value(
            value: reservasProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          locale: const Locale('es'),
          home: Scaffold(body: SalaCard(sala: salaReservada)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verificar que el nombre de la sala reservada se muestra
    expect(find.text('Sala de Conferencias B'), findsOneWidget);

    // Verificar que se muestra el estado "Reservada"
    expect(find.textContaining('Reservada'), findsAtLeastNWidgets(1));

    // Verificar que aparece el botón "Liberar Sala" para salas reservadas
    expect(find.textContaining('Liberar'), findsAtLeastNWidgets(1));
  });

  testWidgets('SalaCard responde a interacciones del usuario', (
    WidgetTester tester,
  ) async {
    final salaInteractiva = Sala(
      id: '3', // ID como String
      nombre: 'Sala Interactiva',
      capacidad: 15,
      ubicacion: 'Piso 1',
      imagenAsset: 'assets/sala3.jpeg',
      isReservada: false,
    );

    final reservasProvider = ReservasProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservasProvider>.value(
            value: reservasProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          locale: const Locale('es'),
          home: Scaffold(body: SalaCard(sala: salaInteractiva)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Buscar la tarjeta de la sala (Card widget)
    final cardFinder = find.byType(Card);
    expect(cardFinder, findsOneWidget);

    // Simular tap en la tarjeta para abrir diálogo de reserva
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verificar que aparece el diálogo de reserva o alguna respuesta visual
    // Nota: Esto depende de la implementación específica del diálogo
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('SalaCard muestra botón de editar sala', (
    WidgetTester tester,
  ) async {
    final salaEditable = Sala(
      id: '4', // ID como String
      nombre: 'Sala Editable',
      capacidad: 8,
      ubicacion: 'Sótano',
      imagenAsset: 'assets/sala4.jpeg',
      isReservada: false,
    );

    final reservasProvider = ReservasProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservasProvider>.value(
            value: reservasProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          locale: const Locale('es'),
          home: Scaffold(body: SalaCard(sala: salaEditable)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verificar que existe el botón de editar sala
    expect(find.textContaining('Editar'), findsAtLeastNWidgets(1));
  });
}
