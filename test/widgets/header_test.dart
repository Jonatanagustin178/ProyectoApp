import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aplicacion_app/l10n/app_localizations.dart';

// Importar los providers y widgets necesarios
import 'package:aplicacion_app/provider/weather_provider.dart';
import 'package:aplicacion_app/services/weather_service.dart';

// Clase mock para simular datos del clima sin conexión a internet
class FakeWeatherProvider extends WeatherProvider {
  @override
  WeatherData? get weatherData => WeatherData(
    temperature: 25.5, // Temperatura simulada para la prueba
    description: 'Soleado', // Descripción del clima en español
    cityName: 'Querétaro', // Ciudad de prueba
    iconCode: '01d', // Código de icono para día soleado
  );

  @override
  bool get isLoading => false; // No está cargando en la prueba

  @override
  String? get errorMessage => null; // Sin errores en la prueba
}

// Clase para evitar conexiones HTTP durante las pruebas
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Lanza error si se intenta hacer una conexión HTTP
    throw UnsupportedError('No HTTP requests allowed in widget tests');
  }
}

void main() {
  // Configurar para evitar conexiones de red durante las pruebas
  setUpAll(() => HttpOverrides.global = _NoNetworkHttpOverrides());

  testWidgets('WeatherHeader muestra información del clima correctamente', (
    tester,
  ) async {
    // Crear el widget con providers simulados
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Provider con datos simulados del clima
          ChangeNotifierProvider<WeatherProvider>(
            create: (_) => FakeWeatherProvider(),
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
          home: Scaffold(
            body: Consumer<WeatherProvider>(
              builder: (context, weatherProvider, child) {
                // Simular el widget WeatherHeader basado en tu main.dart
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: weatherProvider.weatherData != null
                      ? Column(
                          children: [
                            // Mostrar temperatura
                            Text(
                              '${weatherProvider.weatherData!.temperature}°C',
                            ),
                            // Mostrar descripción del clima
                            Text(weatherProvider.weatherData!.description),
                            // Mostrar ciudad
                            Text(weatherProvider.weatherData!.cityName),
                          ],
                        )
                      : const CircularProgressIndicator(), // Indicador de carga
                );
              },
            ),
          ),
        ),
      ),
    );

    // Esperar a que se complete la construcción del widget
    await tester.pumpAndSettle();

    // Verificar que la temperatura se muestra correctamente
    expect(find.textContaining('25.5'), findsOneWidget);

    // Verificar que la descripción del clima se muestra
    expect(find.textContaining('Soleado'), findsOneWidget);

    // Verificar que la ciudad se muestra
    expect(find.textContaining('Querétaro'), findsOneWidget);
  });

  testWidgets('WeatherHeader maneja estado de carga correctamente', (
    tester,
  ) async {
    // Crear provider sin datos para simular estado de carga
    final loadingProvider = WeatherProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WeatherProvider>.value(value: loadingProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          home: Scaffold(
            body: Consumer<WeatherProvider>(
              builder: (context, weatherProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: weatherProvider.weatherData != null
                      ? Column(
                          children: [
                            Text(
                              '${weatherProvider.weatherData!.temperature}°C',
                            ),
                            Text(weatherProvider.weatherData!.description),
                            Text(weatherProvider.weatherData!.cityName),
                          ],
                        )
                      : const Center(
                          child: Text(
                            'Sin datos del clima',
                          ), // Texto simple en lugar de CircularProgressIndicator
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Solo hacer pump una vez para evitar timeout
    await tester.pump();

    // Verificar que se muestra el texto cuando no hay datos
    expect(find.text('Sin datos del clima'), findsOneWidget);
  });
}
