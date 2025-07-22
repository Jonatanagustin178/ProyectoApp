// lib/main.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_app/models/models.dart';
import 'package:aplicacion_app/provider/provider_reservaciones.dart';
import 'package:aplicacion_app/provider/weather_provider.dart';
import 'package:intl/intl.dart';
import 'package:aplicacion_app/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Instancia global del plugin de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Función para manejar la respuesta a la notificación (cuando se toca la notificación)
void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
  }
  //añadir lógica para navegar a una pantalla específica aquí
}

void onDidReceiveLocalNotification(
  int id,
  String? title,
  String? body,
  String? payload,
) async {
  debugPrint('Old iOS notification received: $title, $body, $payload');
}

Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de inicialización para Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Configuración de inicialización para iOS/macOS
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  // Inicializar el plugin de notificaciones
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        onDidReceiveNotificationResponse, // Para manejar toques en la notificación
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ReservasProvider()),
        ChangeNotifierProvider(create: (context) => WeatherProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        home: SalasScreen(onLocaleChanged: _setLocale, currentLocale: _locale),
      ),
    );
  }
}

class SalasScreen extends StatefulWidget {
  final void Function(Locale?)? onLocaleChanged;
  final Locale? currentLocale;
  const SalasScreen({super.key, this.onLocaleChanged, this.currentLocale});

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar el clima al inicializar la pantalla
    Future.microtask(() {
      // Coordenadas de Querétaro
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).loadWeather(20.5888, -100.3899);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservasProvider = Provider.of<ReservasProvider>(context);
    final salas = reservasProvider.salas;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.availableRooms),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              if (widget.onLocaleChanged != null)
                widget.onLocaleChanged!(locale);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('es'),
                child: const Text('Español'),
                enabled: widget.currentLocale?.languageCode != 'es',
              ),
              PopupMenuItem(
                value: const Locale('en'),
                child: const Text('English'),
                enabled: widget.currentLocale?.languageCode != 'en',
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información del clima
          const WeatherHeader(),
          // Lista de salas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: salas.length,
              itemBuilder: (context, index) {
                final sala = salas[index];
                return SalaCard(sala: sala);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const MisReservasScreen()),
          );
        },
        child: const Icon(Icons.list),
        tooltip: l10n.myReservations,
      ),
    );
  }
}

class SalaCard extends StatefulWidget {
  final Sala sala;

  const SalaCard({super.key, required this.sala});

  @override
  State<SalaCard> createState() => _SalaCardState();
}

class _SalaCardState extends State<SalaCard>
    with SingleTickerProviderStateMixin {
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicioSeleccionada;
  TimeOfDay? _horaFinSeleccionada;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.05,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Función para mostrar el selector de fecha
  Future<void> _presentDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Permite reservar hasta un año en el futuro
    );
    if (pickedDate != null) {
      setState(() {
        _fechaSeleccionada = pickedDate;
      });
    }
  }

  // Función para mostrar el selector de hora de inicio
  Future<void> _presentStartTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode:
          TimePickerEntryMode.input, // Opcional: para teclado en vez de reloj
    );
    if (pickedTime != null) {
      setState(() {
        _horaInicioSeleccionada = pickedTime;
      });
    }
  }

  // Función para mostrar el selector de hora de fin
  Future<void> _presentEndTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _horaInicioSeleccionada != null
          ? TimeOfDay(
              hour:
                  _horaInicioSeleccionada!.hour +
                  1, // Sugiere una hora después de la de inicio
              minute: _horaInicioSeleccionada!.minute,
            )
          : TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, // Opcional
    );
    if (pickedTime != null) {
      setState(() {
        _horaFinSeleccionada = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasProvider = Provider.of<ReservasProvider>(
      context,
      listen: false,
    );
    final Color cardColor = widget.sala.isReservada
        ? Colors.red.withOpacity(0.7)
        : Colors.green.withOpacity(0.7);
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Stack(
          children: [
            InkWell(
              onTap: () async {
                await _controller.forward();
                await _controller.reverse();
                if (!widget.sala.isReservada) {
                  _mostrarDialogoReserva(
                    context,
                    widget.sala,
                    reservasProvider,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.stateReserved.replaceFirst(
                          'Estado: ',
                          'La ${widget.sala.nombre} ',
                        ),
                      ),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.asset(
                          widget.sala.imagenAsset,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.sala.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.sala.isReservada
                            ? l10n.stateReserved
                            : l10n.stateAvailable,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${l10n.capacity}: ${widget.sala.capacidad}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${l10n.location}: ${widget.sala.ubicacion}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      // ...existing code...
                      Align(
                        alignment: Alignment.bottomRight,
                        child: AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () async {
                              await _controller.forward();
                              await _controller.reverse();
                              _mostrarDialogoEditarSala(context);
                            },
                            child: Text(
                              l10n.editRoom,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.sala.isReservada)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: TextButton(
                              onPressed: () async {
                                await _controller.forward();
                                await _controller.reverse();
                                reservasProvider.liberarSala(widget.sala.id);
                                _confettiController.play();
                              },
                              child: Text(
                                l10n.releaseRoom,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    // ...existing code...
  }

  void _mostrarDialogoEditarSala(BuildContext context) {
    final capacidadController = TextEditingController(
      text: widget.sala.capacidad.toString(),
    );
    final ubicacionController = TextEditingController(
      text: widget.sala.ubicacion,
    );
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${l10n.editRoom}: ${widget.sala.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: capacidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.capacity),
              ),
              TextField(
                controller: ubicacionController,
                decoration: InputDecoration(labelText: l10n.location),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.sala.capacidad =
                      int.tryParse(capacidadController.text) ??
                      widget.sala.capacidad;
                  widget.sala.ubicacion = ubicacionController.text;
                });
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoReserva(
    BuildContext context,
    Sala sala,
    ReservasProvider provider,
  ) {
    _fechaSeleccionada = null;
    _horaInicioSeleccionada = null;
    _horaFinSeleccionada = null;

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('${l10n.reserveRoom} ${sala.nombre}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de Fecha
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fechaSeleccionada == null
                                ? l10n.selectDate
                                : '${l10n.selectDate}: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                          ),
                        ),
                        AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () async {
                              await _presentDatePicker();
                              setStateDialog(() {});
                            },
                            child: Text(l10n.selectDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Selector de Hora de Inicio
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _horaInicioSeleccionada == null
                                ? l10n.selectStart
                                : '${l10n.selectStart}: ${_horaInicioSeleccionada!.format(context)}',
                          ),
                        ),
                        AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () async {
                              await _presentStartTimePicker();
                              setStateDialog(() {});
                            },
                            child: Text(l10n.selectStart),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Selector de Hora de Fin
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _horaFinSeleccionada == null
                                ? l10n.selectEnd
                                : '${l10n.selectEnd}: ${_horaFinSeleccionada!.format(context)}',
                          ),
                        ),
                        AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () async {
                              await _presentEndTimePicker();
                              setStateDialog(() {});
                            },
                            child: Text(l10n.selectEnd),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      // Validaciones antes de reservar
                      if (_fechaSeleccionada == null ||
                          _horaInicioSeleccionada == null ||
                          _horaFinSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.pleaseSelectDateTime)),
                        );
                        return;
                      }

                      // Asegurarse de que la hora de fin sea posterior a la hora de inicio
                      final now = DateTime.now();
                      final startDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _horaInicioSeleccionada!.hour,
                        _horaInicioSeleccionada!.minute,
                      );
                      final endDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _horaFinSeleccionada!.hour,
                        _horaFinSeleccionada!.minute,
                      );

                      if (endDateTime.isBefore(startDateTime) ||
                          endDateTime.isAtSameMomentAs(startDateTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.endAfterStart)),
                        );
                        return;
                      }

                      // Pasar el BuildContext actual al método reservarSala
                      provider.reservarSala(
                        sala.id,
                        _fechaSeleccionada!,
                        _horaInicioSeleccionada!,
                        _horaFinSeleccionada!,
                        context,
                      );
                      Navigator.of(ctx).pop();
                      // Lanzar confetti
                      _confettiController.play();
                    },
                    child: Text(l10n.reserveRoom),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Pantalla para ver las reservas hechas
class MisReservasScreen extends StatelessWidget {
  const MisReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservasProvider = Provider.of<ReservasProvider>(context);
    final reservas = reservasProvider.reservas;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReservations)),
      body: reservas.isEmpty
          ? Center(child: Text(l10n.noReservations))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reservas.length,
              itemBuilder: (context, index) {
                final reserva = reservas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.nombreSala,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.selectDate}: ${DateFormat('yyyy-MM-dd').format(reserva.fechaReserva)}\n${l10n.selectStart}: ${reserva.horaInicio.format(context)} - ${l10n.selectEnd}: ${reserva.horaFin.format(context)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ReservaProgressBar(reserva: reserva),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Widget para la barra de progreso de la reserva
class ReservaProgressBar extends StatelessWidget {
  final dynamic reserva;
  const ReservaProgressBar({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = reserva.fechaReserva;
    final TimeOfDay inicio = reserva.horaInicio;
    final TimeOfDay fin = reserva.horaFin;
    final DateTime start = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      inicio.hour,
      inicio.minute,
    );
    final DateTime end = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      fin.hour,
      fin.minute,
    );
    final DateTime now = DateTime.now();

    double progress = 1.0;
    if (now.isBefore(start)) {
      progress = 0.0;
    } else if (now.isAfter(end)) {
      progress = 1.0;
    } else {
      final total = end.difference(start).inSeconds;
      final elapsed = now.difference(start).inSeconds;
      progress = (elapsed / total).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso de la reserva',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Widget Header con información del clima
class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weatherData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestiona tus reservas de salas',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Información del clima
          if (weatherProvider.isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Cargando clima...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          else if (weatherProvider.errorMessage != null)
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  weatherProvider.errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          else if (weather != null)
            Row(
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.iconCode}@2x.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 30,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        weather.cityName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
