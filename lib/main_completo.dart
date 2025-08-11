import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_app/models/models.dart';
import 'package:aplicacion_app/provider/provider_reservaciones.dart';
import 'package:aplicacion_app/provider/weather_provider.dart';
import 'package:intl/intl.dart';
import 'package:aplicacion_app/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

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

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  // Solicitar permisos de notificación para Android 13+
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
  final Locale? currentLocale;
  const SalasScreen({super.key, this.onLocaleChanged, this.currentLocale});

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
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

  void _mostrarDialogoAgregarSala(BuildContext context) {
    final nombreController = TextEditingController();
    final capacidadController = TextEditingController();
    final ubicacionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    File? imagenSeleccionada;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                        : 'Nombre de la sala',
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
                TextField(
                  controller: ubicacionController,
                  decoration: InputDecoration(labelText: l10n.location),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final imagen = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (imagen != null) {
                            setState(() {
                              imagenSeleccionada = File(imagen.path);
                            });
                          }
                        },
                        icon: Icon(Icons.camera_alt),
                        label: Text(
                          l10n.capacity.contains('Capacity')
                              ? 'Camera'
                              : 'Cámara',
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final imagen = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (imagen != null) {
                            setState(() {
                              imagenSeleccionada = File(imagen.path);
                            });
                          }
                        },
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          l10n.capacity.contains('Capacity')
                              ? 'Gallery'
                              : 'Galería',
                        ),
                      ),
                    ),
                  ],
                ),
                if (imagenSeleccionada != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Text(
                          l10n.capacity.contains('Capacity')
                              ? 'Selected image:'
                              : 'Imagen seleccionada:',
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            imagenSeleccionada!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.capacity.contains('Capacity')
                            ? 'Please enter the room name'
                            : 'Por favor ingresa el nombre de la sala',
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
                  imagenAsset: imagenSeleccionada?.path ?? 'assets/sala1.jpeg',
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

  void _mostrarHistorial(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => HistorialScreen()));
  }

  void _mostrarCalendarioReservas(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CalendarioScreen()));
  }

  void _mostrarDialogoIdioma(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language / Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇪🇸'),
              title: const Text('Español'),
              onTap: () {
                widget.onLocaleChanged?.call(const Locale('es'));
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        SalasScreen(currentLocale: const Locale('es')),
                  ),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              onTap: () {
                widget.onLocaleChanged?.call(const Locale('en'));
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => SalasScreen(
                      onLocaleChanged: widget.onLocaleChanged,
                      currentLocale: const Locale('en'),
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
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
                  reservasProvider.toggleTheme();
                  break;
                case 'language':
                  _mostrarDialogoIdioma(context);
                  break;
                case 'history':
                  _mostrarHistorial(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      reservasProvider.isDarkTheme
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
              PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: 8),
                    Text(
                      l10n.capacity.contains('Capacity')
                          ? 'History'
                          : 'Historial',
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
            const FloatingParticles(),
            Column(
              children: [
                const WeatherHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
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
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
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
                          itemCount: salas.length,
                          itemBuilder: (context, index) =>
                              SalaCard(sala: salas[index]),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MisReservasScreen()),
          );
        },
        icon: const Icon(Icons.list_alt_rounded),
        label: Text(l10n.myReservations),
      ),
    );
  }
}

// Resto del código en el siguiente archivo...
