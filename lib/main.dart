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
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;

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

  // Solicitar permisos de notificación en Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('es'); // Idioma por defecto español

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale ?? const Locale('es');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ReservasProvider()),
        ChangeNotifierProvider(create: (context) => WeatherProvider()),
      ],
      child: Consumer<ReservasProvider>(
        builder: (context, reservasProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: reservasProvider.isDarkTheme
                ? ThemeMode.dark
                : ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _locale,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            home: SalasScreen(
              onLocaleChanged: _setLocale,
              currentLocale: _locale,
            ),
          );
        },
      ),
    );
  }
}

class SalasScreen extends StatefulWidget {
  final void Function(Locale?)? onLocaleChanged;
  final Locale currentLocale;
  const SalasScreen({
    super.key,
    this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservasProvider = Provider.of<ReservasProvider>(context);
    final salas = reservasProvider.salas.where((sala) {
      if (_searchQuery.isEmpty) return true;
      return sala.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sala.ubicacion.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.availableRooms,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogoAgregarSala(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _mostrarCalendarioReservas(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  Provider.of<ReservasProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                  break;
                case 'language':
                  _mostrarDialogoIdioma(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      Provider.of<ReservasProvider>(
                            context,
                            listen: false,
                          ).isDarkTheme
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.capacity.contains('Capacity')
                          ? 'Toggle Theme'
                          : 'Cambiar Tema',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 8),
                    Text(
                      l10n.capacity.contains('Capacity')
                          ? 'Change Language'
                          : 'Cambiar Idioma',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Partículas flotantes de fondo
            const FloatingParticles(),
            Column(
              children: [
                // Header con información del clima
                const WeatherHeader(),
                // Barra de búsqueda compacta
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    height: 45,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: l10n.capacity.contains('Capacity')
                            ? 'Search rooms...'
                            : 'Buscar salas...',
                        hintStyle: const TextStyle(fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                // Lista de salas
                Expanded(
                  child: salas.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? (l10n.capacity.contains('Capacity')
                                      ? 'No rooms available'
                                      : 'No hay salas disponibles')
                                : (l10n.capacity.contains('Capacity')
                                      ? 'No rooms found'
                                      : 'No se encontraron salas'),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: salas.length,
                          itemBuilder: (context, index) {
                            final sala = salas[index];
                            return AnimatedContainer(
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
                              curve: Curves.easeOutBack,
                              transform: Matrix4.identity()
                                ..translate(
                                  0.0,
                                  -20.0 * (1 - (index + 1) / salas.length),
                                )
                                ..scale(0.8 + 0.2 * (index + 1) / salas.length),
                              child: SalaCard(sala: sala, index: index),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.9, end: 1.1),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const MisReservasScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.elasticOut;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt_rounded),
                label: Text(l10n.myReservations),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 8,
              ),
            );
          },
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarSala(BuildContext context) {
    final nombreController = TextEditingController();
    final capacidadController = TextEditingController();
    final ubicacionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? selectedImagePath;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            l10n.capacity.contains('Capacity')
                ? 'Add New Room'
                : 'Agregar Nueva Sala',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: l10n.capacity.contains('Capacity')
                        ? 'Room Name'
                        : 'Nombre de la Sala',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: capacidadController,
                  decoration: InputDecoration(labelText: l10n.capacity),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: ubicacionController,
                  decoration: InputDecoration(labelText: l10n.location),
                ),
                SizedBox(height: 16),
                // Sección de imagen
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.image, size: 40, color: Colors.grey.shade600),
                      SizedBox(height: 8),
                      Text(
                        selectedImagePath != null
                            ? (l10n.capacity.contains('Capacity')
                                  ? 'Image selected'
                                  : 'Imagen seleccionada')
                            : (l10n.capacity.contains('Capacity')
                                  ? 'No image selected'
                                  : 'No hay imagen seleccionada'),
                        style: TextStyle(
                          color: selectedImagePath != null
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 800,
                                  maxHeight: 600,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setStateDialog(() {
                                    selectedImagePath = image.path;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.capacity.contains('Capacity')
                                          ? 'Error accessing camera'
                                          : 'Error al acceder a la cámara',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.camera_alt, size: 18),
                            label: Text(
                              l10n.capacity.contains('Capacity')
                                  ? 'Camera'
                                  : 'Cámara',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 800,
                                  maxHeight: 600,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setStateDialog(() {
                                    selectedImagePath = image.path;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.capacity.contains('Capacity')
                                          ? 'Error accessing gallery'
                                          : 'Error al acceder a la galería',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.photo_library, size: 18),
                            label: Text(
                              l10n.capacity.contains('Capacity')
                                  ? 'Gallery'
                                  : 'Galería',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedImagePath != null) ...[
                        SizedBox(height: 12),
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(selectedImagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.capacity.contains('Capacity') ? 'Cancel' : 'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreController.text.isEmpty ||
                    capacidadController.text.isEmpty ||
                    ubicacionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Please fill all fields'
                            : 'Por favor completa todos los campos',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final capacidad = int.tryParse(capacidadController.text);
                if (capacidad == null || capacidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Capacity must be a number greater than 0'
                            : 'La capacidad debe ser un número mayor a 0',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final provider = Provider.of<ReservasProvider>(
                  context,
                  listen: false,
                );
                provider.agregarSala(
                  nombre: nombreController.text,
                  imagenAsset: selectedImagePath ?? 'assets/sala1.jpeg',
                  capacidad: capacidad,
                  ubicacion: ubicacionController.text,
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.capacity.contains('Capacity')
                          ? 'Room ${nombreController.text} added successfully'
                          : 'Sala ${nombreController.text} agregada exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                l10n.capacity.contains('Capacity') ? 'Add' : 'Agregar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoIdioma(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          widget.currentLocale.languageCode == 'es'
              ? 'Seleccionar Idioma'
              : 'Select Language',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇪🇸'),
              title: const Text('Español'),
              trailing: widget.currentLocale.languageCode == 'es'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.onLocaleChanged?.call(const Locale('es'));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma cambiado a Español'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: widget.currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.onLocaleChanged?.call(const Locale('en'));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language changed to English'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCalendarioReservas(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CalendarioScreen()));
  }
}

// Floating Particles Widget
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({Key? key}) : super(key: key);

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<Particle> _particles = [];
  final int particleCount = 20;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];

    for (int i = 0; i < particleCount; i++) {
      final controller = AnimationController(
        duration: Duration(seconds: (3 + math.Random().nextInt(4))),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);

      _particles.add(
        Particle(
          x: math.Random().nextDouble(),
          y: math.Random().nextDouble(),
          size: 1 + math.Random().nextDouble() * 3,
          color: [
            Colors.blue.withOpacity(0.2),
            Colors.lightBlue.withOpacity(0.15),
            Colors.cyan.withOpacity(0.1),
            Colors.indigo.withOpacity(0.25),
          ][math.Random().nextInt(4)],
          speedX: (math.Random().nextDouble() - 0.5) * 0.015,
          speedY: (math.Random().nextDouble() - 0.5) * 0.015,
        ),
      );

      // Stagger the animation start times
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_animations),
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final Color color;
  final double speedX;
  final double speedY;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speedX,
    required this.speedY,
  });

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1) x = math.Random().nextDouble();
    if (y < 0 || y > 1) y = math.Random().nextDouble();
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Historial Screen
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.capacity.contains('Capacity') ? 'History' : 'Historial',
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<ReservasProvider>(
        builder: (context, provider, child) {
          final historialReservas =
              provider.historialCompleto.where((reserva) {
                final fechaFin = DateTime(
                  reserva.fechaReserva.year,
                  reserva.fechaReserva.month,
                  reserva.fechaReserva.day,
                  reserva.horaFin.hour,
                  reserva.horaFin.minute,
                );
                // Incluir reservas terminadas o canceladas
                return fechaFin.isBefore(DateTime.now()) || reserva.isCancelled;
              }).toList()..sort((a, b) {
                final fechaFinA = DateTime(
                  a.fechaReserva.year,
                  a.fechaReserva.month,
                  a.fechaReserva.day,
                  a.horaFin.hour,
                  a.horaFin.minute,
                );
                final fechaFinB = DateTime(
                  b.fechaReserva.year,
                  b.fechaReserva.month,
                  b.fechaReserva.day,
                  b.horaFin.hour,
                  b.horaFin.minute,
                );
                return fechaFinB.compareTo(fechaFinA);
              });

          if (historialReservas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.capacity.contains('Capacity')
                        ? 'No history available'
                        : 'No hay historial disponible',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historialReservas.length,
            itemBuilder: (context, index) {
              final reserva = historialReservas[index];
              final isCompleted =
                  DateTime(
                    reserva.fechaReserva.year,
                    reserva.fechaReserva.month,
                    reserva.fechaReserva.day,
                    reserva.horaFin.hour,
                    reserva.horaFin.minute,
                  ).isBefore(DateTime.now()) &&
                  !reserva.isCancelled;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reserva.isCancelled
                        ? Colors.red
                        : (isCompleted ? Colors.green : Colors.orange),
                    child: Icon(
                      reserva.isCancelled
                          ? Icons.cancel
                          : (isCompleted ? Icons.check_circle : Icons.history),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    reserva.nombreSala,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: reserva.isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reserva.nombreUsuario),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(reserva.fechaReserva)} ${reserva.horaInicio.format(context)} - ${reserva.horaFin.format(context)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      // Mostrar estado de la reserva
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: reserva.isCancelled
                              ? Colors.red.shade100
                              : (isCompleted
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reserva.isCancelled
                              ? 'Cancelada'
                              : (isCompleted ? 'Completada' : 'En progreso'),
                          style: TextStyle(
                            fontSize: 12,
                            color: reserva.isCancelled
                                ? Colors.red.shade700
                                : (isCompleted
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    reserva.isCancelled ? Icons.cancel : Icons.check_circle,
                    color: reserva.isCancelled
                        ? Colors.red[600]
                        : Colors.green[600],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Calendario Screen
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.capacity.contains('Capacity') ? 'Calendar' : 'Calendario',
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Consumer<ReservasProvider>(
              builder: (context, provider, child) {
                final reservasDelDia =
                    provider.reservas
                        .where(
                          (reserva) =>
                              reserva.fechaReserva.year == selectedDate.year &&
                              reserva.fechaReserva.month ==
                                  selectedDate.month &&
                              reserva.fechaReserva.day == selectedDate.day,
                        )
                        .toList()
                      ..sort((a, b) {
                        final fechaInicioA = DateTime(
                          a.fechaReserva.year,
                          a.fechaReserva.month,
                          a.fechaReserva.day,
                          a.horaInicio.hour,
                          a.horaInicio.minute,
                        );
                        final fechaInicioB = DateTime(
                          b.fechaReserva.year,
                          b.fechaReserva.month,
                          b.fechaReserva.day,
                          b.horaInicio.hour,
                          b.horaInicio.minute,
                        );
                        return fechaInicioA.compareTo(fechaInicioB);
                      });

                if (reservasDelDia.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.capacity.contains('Capacity')
                              ? 'No reservations for this date'
                              : 'No hay reservas para esta fecha',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservasDelDia.length,
                  itemBuilder: (context, index) {
                    final reserva = reservasDelDia[index];
                    final fechaFin = DateTime(
                      reserva.fechaReserva.year,
                      reserva.fechaReserva.month,
                      reserva.fechaReserva.day,
                      reserva.horaFin.hour,
                      reserva.horaFin.minute,
                    );
                    final isActive = fechaFin.isAfter(DateTime.now());

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green
                              : Colors.grey,
                          child: Icon(
                            isActive ? Icons.event : Icons.event_busy,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          reserva.nombreSala,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reserva.nombreUsuario),
                            Text(
                              '${reserva.horaInicio.format(context)} - ${reserva.horaFin.format(context)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: isActive
                            ? Icon(Icons.access_time, color: Colors.orange[600])
                            : Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SalaCard extends StatefulWidget {
  final Sala sala;
  final int? index;

  const SalaCard({super.key, required this.sala, this.index});

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
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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

  // Función para manejar la imagen de la sala correctamente
  Widget _buildSalaImage() {
    try {
      // Si la imagen es una ruta de archivo (del picker)
      if (widget.sala.imagenAsset.startsWith('/') ||
          widget.sala.imagenAsset.contains('cache')) {
        return Image.file(
          File(widget.sala.imagenAsset),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si falla cargar la imagen del archivo, usar imagen por defecto
            return _buildDefaultImage();
          },
        );
      } else {
        // Si es un asset normal
        return Image.asset(
          widget.sala.imagenAsset,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultImage();
          },
        );
      }
    } catch (e) {
      return _buildDefaultImage();
    }
  }

  Widget _buildDefaultImage() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room, size: 50, color: Colors.grey[600]),
          SizedBox(height: 8),
          Text(
            widget.sala.nombre,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      initialEntryMode: TimePickerEntryMode.dial, // Usar dial para mejor UX
      helpText: 'Seleccionar hora de inicio',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minutos',
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
              hour: (_horaInicioSeleccionada!.hour + 1) % 24,
              minute: _horaInicioSeleccionada!.minute,
            )
          : TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial, // Usar dial para mejor UX
      helpText: 'Seleccionar hora de fin',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minutos',
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

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + ((widget.index ?? 0) * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 5 + (animationValue * 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Stack(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(15.0),
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
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'sala_${widget.sala.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: _buildSalaImage(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                child: Text(widget.sala.nombre),
                              ),
                              const SizedBox(height: 5),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  widget.sala.isReservada
                                      ? l10n.stateReserved
                                      : l10n.stateAvailable,
                                  key: ValueKey(widget.sala.isReservada),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
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
                              // Botones de acción
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AnimatedScale(
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
                                  if (widget.sala.isReservada)
                                    AnimatedScale(
                                      scale: 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: TextButton(
                                        onPressed: () async {
                                          await _controller.forward();
                                          await _controller.reverse();
                                          reservasProvider.liberarSala(
                                            widget.sala.id,
                                          );
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
                                ],
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
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditarSala(BuildContext context) {
    final nombreController = TextEditingController(text: widget.sala.nombre);
    final capacidadController = TextEditingController(
      text: widget.sala.capacidad.toString(),
    );
    final ubicacionController = TextEditingController(
      text: widget.sala.ubicacion,
    );
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker _picker = ImagePicker();
    String? nuevaImagenPath;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('${l10n.editRoom}: ${widget.sala.nombre}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: l10n.capacity.contains('Capacity')
                          ? 'Room Name'
                          : 'Nombre de la Sala',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: capacidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.capacity,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: ubicacionController,
                    decoration: InputDecoration(
                      labelText: l10n.location,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Sección de imagen
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(height: 8),
                        Text(
                          nuevaImagenPath != null
                              ? (l10n.capacity.contains('Capacity')
                                    ? 'New image selected'
                                    : 'Nueva imagen seleccionada')
                              : (l10n.capacity.contains('Capacity')
                                    ? 'Current image'
                                    : 'Imagen actual'),
                          style: TextStyle(
                            color: nuevaImagenPath != null
                                ? Colors.green
                                : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.camera,
                                    maxWidth: 800,
                                    maxHeight: 600,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    setStateDialog(() {
                                      nuevaImagenPath = image.path;
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.capacity.contains('Capacity')
                                            ? 'Error accessing camera'
                                            : 'Error al acceder a la cámara',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.camera_alt, size: 18),
                              label: Text(
                                l10n.capacity.contains('Capacity')
                                    ? 'Camera'
                                    : 'Cámara',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 800,
                                    maxHeight: 600,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    setStateDialog(() {
                                      nuevaImagenPath = image.path;
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.capacity.contains('Capacity')
                                            ? 'Error accessing gallery'
                                            : 'Error al acceder a la galería',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.photo_library, size: 18),
                              label: Text(
                                l10n.capacity.contains('Capacity')
                                    ? 'Gallery'
                                    : 'Galería',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (nuevaImagenPath != null) ...[
                          SizedBox(height: 12),
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(nuevaImagenPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10n.capacity.contains('Capacity') ? 'Cancel' : 'Cancelar',
                ),
              ),
              // Botón para eliminar sala
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (deleteCtx) => AlertDialog(
                      title: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Delete Room'
                            : 'Eliminar Sala',
                      ),
                      content: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Are you sure you want to delete ${widget.sala.nombre}?'
                            : '¿Estás seguro de que quieres eliminar ${widget.sala.nombre}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(deleteCtx).pop(),
                          child: Text(
                            l10n.capacity.contains('Capacity')
                                ? 'Cancel'
                                : 'Cancelar',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<ReservasProvider>(
                              context,
                              listen: false,
                            ).eliminarSala(widget.sala.id);
                            Navigator.of(deleteCtx).pop();
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.capacity.contains('Capacity')
                                      ? 'Room ${widget.sala.nombre} deleted'
                                      : 'Sala ${widget.sala.nombre} eliminada',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: Text(
                            l10n.capacity.contains('Capacity')
                                ? 'Delete'
                                : 'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  l10n.capacity.contains('Capacity') ? 'Delete' : 'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nombreController.text.isEmpty ||
                      capacidadController.text.isEmpty ||
                      ubicacionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.capacity.contains('Capacity')
                              ? 'Please fill all fields'
                              : 'Por favor completa todos los campos',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final capacidad = int.tryParse(capacidadController.text);
                  if (capacidad == null || capacidad <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.capacity.contains('Capacity')
                              ? 'Capacity must be a number greater than 0'
                              : 'La capacidad debe ser un número mayor a 0',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final provider = Provider.of<ReservasProvider>(
                    context,
                    listen: false,
                  );
                  provider.editarSala(
                    widget.sala.id,
                    nombre: nombreController.text,
                    capacidad: capacidad,
                    ubicacion: ubicacionController.text,
                    imagenAsset: nuevaImagenPath ?? widget.sala.imagenAsset,
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Room ${nombreController.text} updated successfully'
                            : 'Sala ${nombreController.text} actualizada exitosamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
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
class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen>
    with TickerProviderStateMixin {
  late AnimationController _walkController;
  late AnimationController _armController;
  late AnimationController _bobController;
  late Animation<double> _walkAnimation;
  late Animation<double> _leftArmAnimation;
  late Animation<double> _rightArmAnimation;
  late Animation<double> _leftLegAnimation;
  late Animation<double> _rightLegAnimation;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();

    // Animación principal de caminar
    _walkController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Animación de los brazos
    _armController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _leftArmAnimation = Tween<double>(
      begin: -0.5,
      end: 0.5,
    ).animate(_armController);

    _rightArmAnimation = Tween<double>(
      begin: 0.5,
      end: -0.5,
    ).animate(_armController);

    // Animación de las piernas (opuesta a los brazos)
    _leftLegAnimation = Tween<double>(
      begin: 0.3,
      end: -0.3,
    ).animate(_armController);

    _rightLegAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3,
    ).animate(_armController);

    // Animación de rebote vertical
    _bobController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Configurar la animación de caminar usando MediaQuery aquí
    _walkAnimation =
        Tween<double>(
          begin: -MediaQuery.of(context).size.width * 0.4,
          end: MediaQuery.of(context).size.width * 0.4,
        ).animate(
          CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _walkController.dispose();
    _armController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservasProvider = Provider.of<ReservasProvider>(context);
    // Filtrar solo las reservas activas (no canceladas)
    final reservas = reservasProvider.reservas
        .where((reserva) => !reserva.isCancelled)
        .toList();

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReservations)),
      body: reservas.isEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.green.shade50,
                    Colors.yellow.shade50,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Mensaje principal
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 15),
                              AnimatedBuilder(
                                animation: _bobAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _bobAnimation.value),
                                    child: Text(
                                      l10n.noReservations,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 10),
                              Text(
                                '🐵 ¡Mira este mono caminando! 🚶‍♂️',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.brown.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mono de palitos caminando
                  AnimatedBuilder(
                    animation: _walkAnimation,
                    builder: (context, child) {
                      // Determinar la dirección del caminar
                      bool walkingRight = _walkController.value < 0.5;

                      return Positioned(
                        bottom: 120,
                        left:
                            _walkAnimation.value +
                            MediaQuery.of(context).size.width / 2,
                        child: AnimatedBuilder(
                          animation: _bobAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -_bobAnimation.value),
                              child: Transform.scale(
                                scaleX: walkingRight
                                    ? 1
                                    : -1, // Voltear cuando camina hacia la izquierda
                                child: CustomPaint(
                                  size: Size(60, 80),
                                  painter: StickMonkeyPainter(
                                    leftArmAngle: _leftArmAnimation.value,
                                    rightArmAngle: _rightArmAnimation.value,
                                    leftLegAngle: _leftLegAnimation.value,
                                    rightLegAngle: _rightLegAnimation.value,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Huellas del mono
                  AnimatedBuilder(
                    animation: _walkController,
                    builder: (context, child) {
                      return Positioned(
                        bottom: 100,
                        left:
                            (_walkAnimation.value +
                                MediaQuery.of(context).size.width / 2) -
                            10,
                        child: Opacity(
                          opacity: 0.4,
                          child: Text('👣', style: TextStyle(fontSize: 16)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
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
                        const SizedBox(height: 8),
                        // Botón para cancelar reserva
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (cancelCtx) => AlertDialog(
                                    title: Text(
                                      l10n.capacity.contains('Capacity')
                                          ? 'Cancel Reservation'
                                          : 'Cancelar Reserva',
                                    ),
                                    content: Text(
                                      l10n.capacity.contains('Capacity')
                                          ? 'Are you sure you want to cancel the reservation for ${reserva.nombreSala}?'
                                          : '¿Estás seguro de que quieres cancelar la reserva de ${reserva.nombreSala}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(cancelCtx).pop(),
                                        child: Text(
                                          l10n.capacity.contains('Capacity')
                                              ? 'No'
                                              : 'No',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          reservasProvider.cancelarReserva(
                                            reserva.id,
                                          );
                                          Navigator.of(cancelCtx).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.capacity.contains(
                                                      'Capacity',
                                                    )
                                                    ? 'Reservation for ${reserva.nombreSala} canceled'
                                                    : 'Reserva de ${reserva.nombreSala} cancelada',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          l10n.capacity.contains('Capacity')
                                              ? 'Yes, Cancel'
                                              : 'Sí, Cancelar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: Icon(Icons.cancel, size: 16),
                              label: Text(
                                l10n.capacity.contains('Capacity')
                                    ? 'Cancel'
                                    : 'Cancelar',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade700,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
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
class WeatherHeader extends StatefulWidget {
  const WeatherHeader({super.key});

  @override
  State<WeatherHeader> createState() => _WeatherHeaderState();
}

class _WeatherHeaderState extends State<WeatherHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weather = weatherProvider.weatherData;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blue[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      if (weatherProvider.isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[600]!,
                            ),
                          ),
                        )
                      else if (weather != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weather.cityName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.network(
                              'https://openweathermap.org/img/wn/${weather.iconCode}@2x.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.wb_sunny,
                                  color: Colors.orange[600],
                                  size: 20,
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${weather.temperature.toStringAsFixed(0)}°C',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Sin datos del clima',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Clase para dibujar el mono de palitos animado
class StickMonkeyPainter extends CustomPainter {
  final double leftArmAngle;
  final double rightArmAngle;
  final double leftLegAngle;
  final double rightLegAngle;

  StickMonkeyPainter({
    required this.leftArmAngle,
    required this.rightArmAngle,
    required this.leftLegAngle,
    required this.rightLegAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Cabeza
    canvas.drawCircle(Offset(center.dx, center.dy - 25), 12, headPaint);

    // Ojos
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx - 4, center.dy - 28), 2, eyePaint);
    canvas.drawCircle(Offset(center.dx + 4, center.dy - 28), 2, eyePaint);

    // Sonrisa
    final smilePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 22),
        width: 8,
        height: 6,
      ),
      0,
      math.pi,
      false,
      smilePaint,
    );

    // Cuerpo
    canvas.drawLine(
      Offset(center.dx, center.dy - 13),
      Offset(center.dx, center.dy + 10),
      paint,
    );

    // Brazo izquierdo
    final leftArmEnd = Offset(
      center.dx - 15 * math.cos(leftArmAngle),
      center.dy - 5 + 15 * math.sin(leftArmAngle),
    );
    canvas.drawLine(Offset(center.dx, center.dy - 5), leftArmEnd, paint);

    // Brazo derecho
    final rightArmEnd = Offset(
      center.dx + 15 * math.cos(rightArmAngle),
      center.dy - 5 + 15 * math.sin(rightArmAngle),
    );
    canvas.drawLine(Offset(center.dx, center.dy - 5), rightArmEnd, paint);

    // Pierna izquierda
    final leftLegEnd = Offset(
      center.dx - 10 * math.cos(leftLegAngle),
      center.dy + 10 + 20 * math.sin(leftLegAngle + math.pi / 2),
    );
    canvas.drawLine(Offset(center.dx, center.dy + 10), leftLegEnd, paint);

    // Pierna derecha
    final rightLegEnd = Offset(
      center.dx + 10 * math.cos(rightLegAngle),
      center.dy + 10 + 20 * math.sin(rightLegAngle + math.pi / 2),
    );
    canvas.drawLine(Offset(center.dx, center.dy + 10), rightLegEnd, paint);

    // Manos (círculos pequeños)
    final handPaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftArmEnd, 3, handPaint);
    canvas.drawCircle(rightArmEnd, 3, handPaint);

    // Pies (círculos pequeños)
    canvas.drawCircle(leftLegEnd, 3, handPaint);
    canvas.drawCircle(rightLegEnd, 3, handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
