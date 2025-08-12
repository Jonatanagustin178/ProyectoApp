import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aplicacion_app/l10n/app_localizations.dart';

// Importar providers y widgets necesarios
import 'package:aplicacion_app/provider/provider_reservaciones.dart';
import 'package:aplicacion_app/provider/weather_provider.dart';

// Clase para evitar conexiones HTTP durante las pruebas
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw UnsupportedError('No HTTP requests allowed in widget tests');
  }
}

void main() {
  // Configurar para evitar conexiones de red durante las pruebas
  setUpAll(() => HttpOverrides.global = _NoNetworkHttpOverrides());

  testWidgets('Componentes básicos se renderizan correctamente', (
    WidgetTester tester,
  ) async {
    // Crear widget simple para probar componentes básicos
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservasProvider>(
            create: (_) => ReservasProvider(),
          ),
          ChangeNotifierProvider<WeatherProvider>(
            create: (_) => WeatherProvider(),
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
          home: Scaffold(
            appBar: AppBar(title: const Text('Salas Disponibles')),
            body: const Center(child: Text('Test Widget')),
            floatingActionButton: FloatingActionButton(
              onPressed: null,
              child: const Icon(Icons.list),
            ),
          ),
        ),
      ),
    );

    // Solo hacer pump una vez para evitar timeout
    await tester.pump();

    // Verificar que los componentes básicos están presentes
    expect(find.text('Salas Disponibles'), findsOneWidget);
    expect(find.text('Test Widget'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('AppBar y FloatingActionButton se muestran', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        locale: const Locale('es'),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Prueba'),
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'idioma',
                    child: Text('Cambiar Idioma'),
                  ),
                ],
              ),
            ],
          ),
          body: const Center(child: Text('Contenido de prueba')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Mis Reservas'),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verificar elementos de la interfaz
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Mis Reservas'), findsOneWidget);
  });

  testWidgets('TextField de búsqueda funciona correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        locale: Locale('es'),
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar salas...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verificar que el TextField está presente
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar salas...'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Probar escritura en el TextField
    await tester.enterText(find.byType(TextField), 'Sala A');
    await tester.pump();

    expect(find.text('Sala A'), findsOneWidget);
  });

  testWidgets('Providers se inicializan correctamente', (
    WidgetTester tester,
  ) async {
    late ReservasProvider reservasProvider;
    late WeatherProvider weatherProvider;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservasProvider>(
            create: (_) => ReservasProvider(),
          ),
          ChangeNotifierProvider<WeatherProvider>(
            create: (_) => WeatherProvider(),
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
          home: Builder(
            builder: (context) {
              // Obtener referencias a los providers
              reservasProvider = Provider.of<ReservasProvider>(
                context,
                listen: false,
              );
              weatherProvider = Provider.of<WeatherProvider>(
                context,
                listen: false,
              );

              return const Scaffold(body: Center(child: Text('Provider Test')));
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verificar que los providers no son null
    expect(reservasProvider, isNotNull);
    expect(weatherProvider, isNotNull);

    // Verificar estados iniciales
    expect(reservasProvider.salas, isNotEmpty); // Debe tener salas por defecto
    expect(
      weatherProvider.weatherData,
      isNull,
    ); // Sin datos iniciales del clima
  });
}
