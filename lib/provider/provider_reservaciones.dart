// lib/provider/provider_reservaciones.dart (Asegúrate de que la ruta y el nombre del archivo sean correctos)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import '../main.dart'; // Importar main.dart para acceder a la instancia global de flutterLocalNotificationsPlugin
import 'package:intl/intl.dart'; // Importar para formatear la fecha/hora en la notificación
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReservasProvider with ChangeNotifier {
  final List<Sala> _salas = [
    Sala(
      id: 's1',
      nombre: 'Sala 1',
      imagenAsset: 'assets/sala1.jpeg',
      capacidad: 10,
      ubicacion: 'Planta Baja',
    ),
    Sala(
      id: 's2',
      nombre: 'Sala 2',
      imagenAsset: 'assets/sala2.jpeg',
      capacidad: 8,
      ubicacion: 'Primer Piso',
    ),
    Sala(
      id: 's3',
      nombre: 'Sala 3',
      imagenAsset: 'assets/sala3.jpeg',
      capacidad: 12,
      ubicacion: 'Segundo Piso',
    ),
    Sala(
      id: 's4',
      nombre: 'Sala 4',
      imagenAsset: 'assets/sala4.jpeg',
      capacidad: 6,
      ubicacion: 'Planta Baja',
    ),
  ];

  final List<Reserva> _reservas = [];
  String _filtroTexto = '';
  bool _isDarkTheme = false;

  List<Sala> get salas {
    if (_filtroTexto.isEmpty) {
      return [..._salas];
    }
    return _salas
        .where(
          (sala) =>
              sala.nombre.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
              sala.ubicacion.toLowerCase().contains(
                _filtroTexto.toLowerCase(),
              ) ||
              sala.capacidad.toString().contains(_filtroTexto),
        )
        .toList();
  }

  List<Reserva> get reservas => [..._reservas];

  // Getter específico para el historial (incluye todas las reservas)
  List<Reserva> get historialCompleto => [..._reservas];

  String get filtroTexto => _filtroTexto;
  bool get isDarkTheme => _isDarkTheme;

  // Constructor que carga datos al inicializar
  ReservasProvider() {
    _cargarDatos();
  }

  // Métodos de persistencia
  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    // Guardar salas
    final salasJson = _salas
        .map(
          (sala) => {
            'id': sala.id,
            'nombre': sala.nombre,
            'imagenAsset': sala.imagenAsset,
            'capacidad': sala.capacidad,
            'ubicacion': sala.ubicacion,
            'isReservada': sala.isReservada,
          },
        )
        .toList();
    await prefs.setString('salas', jsonEncode(salasJson));

    // Guardar reservas
    final reservasJson = _reservas
        .map(
          (reserva) => {
            'id': reserva.id,
            'salaId': reserva.salaId,
            'nombreSala': reserva.nombreSala,
            'fechaReserva': reserva.fechaReserva.millisecondsSinceEpoch,
            'horaInicio':
                '${reserva.horaInicio.hour}:${reserva.horaInicio.minute}',
            'horaFin': '${reserva.horaFin.hour}:${reserva.horaFin.minute}',
            'nombreUsuario': reserva.nombreUsuario,
            'isCancelled': reserva.isCancelled, // Guardar estado de cancelación
          },
        )
        .toList();
    await prefs.setString('reservas', jsonEncode(reservasJson));

    // Guardar configuraciones
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar salas
    final salasString = prefs.getString('salas');
    if (salasString != null) {
      final salasJson = jsonDecode(salasString) as List;
      _salas.clear();
      _salas.addAll(
        salasJson
            .map(
              (salaData) => Sala(
                id: salaData['id'],
                nombre: salaData['nombre'],
                imagenAsset: salaData['imagenAsset'],
                capacidad: salaData['capacidad'],
                ubicacion: salaData['ubicacion'],
                isReservada: salaData['isReservada'] ?? false,
              ),
            )
            .toList(),
      );
    }

    // Cargar reservas
    final reservasString = prefs.getString('reservas');
    if (reservasString != null) {
      final reservasJson = jsonDecode(reservasString) as List;
      _reservas.clear();
      _reservas.addAll(
        reservasJson.map((reservaData) {
          final horaInicioParts = reservaData['horaInicio'].split(':');
          final horaFinParts = reservaData['horaFin'].split(':');

          return Reserva(
            id: reservaData['id'],
            salaId: reservaData['salaId'],
            nombreSala: reservaData['nombreSala'],
            fechaReserva: DateTime.fromMillisecondsSinceEpoch(
              reservaData['fechaReserva'],
            ),
            horaInicio: TimeOfDay(
              hour: int.parse(horaInicioParts[0]),
              minute: int.parse(horaInicioParts[1]),
            ),
            horaFin: TimeOfDay(
              hour: int.parse(horaFinParts[0]),
              minute: int.parse(horaFinParts[1]),
            ),
            nombreUsuario: reservaData['nombreUsuario'] ?? 'Usuario',
            isCancelled:
                reservaData['isCancelled'] ??
                false, // Cargar estado de cancelación
          );
        }).toList(),
      );
    }

    // Cargar configuraciones
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;

    notifyListeners();
  }

  // Métodos de filtrado y búsqueda
  void setFiltroTexto(String filtro) {
    _filtroTexto = filtro;
    notifyListeners();
  }

  void clearFiltro() {
    _filtroTexto = '';
    notifyListeners();
  }

  // Método para cambiar tema
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _guardarDatos();
    notifyListeners();
  }

  void reservarSala(
    String salaId,
    DateTime fecha,
    TimeOfDay horaInicio,
    TimeOfDay horaFin,
    BuildContext context, // ¡Ahora recibe el BuildContext!
  ) {
    // Validar si la sala ya está reservada en ese horario
    final conflictoReserva = _reservas.any((reserva) {
      if (reserva.salaId != salaId) return false;

      final fechaReserva = reserva.fechaReserva;
      if (fechaReserva.year != fecha.year ||
          fechaReserva.month != fecha.month ||
          fechaReserva.day != fecha.day)
        return false;

      final inicioMinutos = horaInicio.hour * 60 + horaInicio.minute;
      final finMinutos = horaFin.hour * 60 + horaFin.minute;
      final reservaInicioMinutos =
          reserva.horaInicio.hour * 60 + reserva.horaInicio.minute;
      final reservaFinMinutos =
          reserva.horaFin.hour * 60 + reserva.horaFin.minute;

      return (inicioMinutos < reservaFinMinutos &&
          finMinutos > reservaInicioMinutos);
    });

    if (conflictoReserva) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe una reserva en ese horario para esta sala'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar horarios de negocio (8 AM - 10 PM)
    if (horaInicio.hour < 8 ||
        horaFin.hour > 22 ||
        (horaFin.hour == 22 && horaFin.minute > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Las reservas solo están disponibles de 8:00 AM a 10:00 PM',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final salaIndex = _salas.indexWhere((sala) => sala.id == salaId);
    if (salaIndex != -1) {
      _salas[salaIndex].isReservada = true;
      final nuevaReserva = Reserva(
        id: DateTime.now().toString(),
        salaId: salaId,
        nombreSala: _salas[salaIndex].nombre,
        fechaReserva: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        nombreUsuario: 'Usuario', // Default user name
      );
      _reservas.add(nuevaReserva);
      _guardarDatos(); // Guardar datos
      // Notificación inmediata
      _mostrarNotificacionReservaExitosa(nuevaReserva, context);
      // Notificación programada 5 minutos antes de que termine la reserva
      _programarNotificacionFinReserva(nuevaReserva, context);
      notifyListeners();
      print('Sala ${_salas[salaIndex].nombre} reservada con éxito!');
    } else {
      print('La sala no se encontró.');
    }
  }

  // Nuevo método para mostrar la notificación
  Future<void> _mostrarNotificacionReservaExitosa(
    Reserva reserva,
    BuildContext context,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'reservas_channel_id',
          'Confirmación de Reserva',
          channelDescription:
              'Notificaciones sobre la confirmación de reservas de salas.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Reserva Exitosa',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      reserva.id.hashCode,
      '¡Reserva de ${reserva.nombreSala} Confirmada!',
      // Usar el BuildContext recibido para formatear las horas
      'Tu reserva para el ${DateFormat('dd/MM/yyyy').format(reserva.fechaReserva)} de ${reserva.horaInicio.format(context)} a ${reserva.horaFin.format(context)} ha sido guardada.',
      platformChannelSpecifics,
      payload: reserva.id,
    );
  }

  // Programar notificación para el fin de la reserva
  Future<void> _programarNotificacionFinReserva(
    Reserva reserva,
    BuildContext context,
  ) async {
    try {
      tz.initializeTimeZones();
      final now = DateTime.now();
      final endDateTime = DateTime(
        reserva.fechaReserva.year,
        reserva.fechaReserva.month,
        reserva.fechaReserva.day,
        reserva.horaFin.hour,
        reserva.horaFin.minute,
      );
      final scheduledTime = endDateTime.subtract(const Duration(minutes: 5));

      if (scheduledTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          reserva.id.hashCode + 10000,
          '¡Tu reserva está por terminar!',
          'La sala ${reserva.nombreSala} terminará a las ${reserva.horaFin.format(context)}',
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fin_reserva_channel',
              'Fin de Reserva',
              channelDescription:
                  'Notificación cuando la sala está por terminar',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      // Si hay error con las notificaciones programadas, solo registramos el error
      // pero no bloqueamos el proceso de reserva
      print('Error al programar notificación: $e');
      // Mostrar una notificación simple inmediata en su lugar
      try {
        await flutterLocalNotificationsPlugin.show(
          reserva.id.hashCode,
          'Reserva confirmada',
          'Sala ${reserva.nombreSala} reservada exitosamente',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reservas_channel_id',
              'Reservas',
              channelDescription: 'Notificaciones de reservas de salas',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      } catch (showError) {
        print('Error al mostrar notificación simple: $showError');
      }
    }
  }

  Future<void> liberarSala(String salaId) async {
    final salaIndex = _salas.indexWhere((sala) => sala.id == salaId);
    if (salaIndex != -1 && _salas[salaIndex].isReservada) {
      _salas[salaIndex].isReservada = false;
      _reservas.removeWhere((reserva) => reserva.salaId == salaId);
      _guardarDatos(); // Guardar datos
      notifyListeners();
      await _mostrarNotificacionLiberacionSala(_salas[salaIndex]);
      print('Sala ${_salas[salaIndex].nombre} liberada.');
    }
  }

  // Función para agregar una nueva sala
  void agregarSala({
    required String nombre,
    required String imagenAsset,
    required int capacidad,
    required String ubicacion,
  }) {
    final nuevaSala = Sala(
      id: 's${DateTime.now().millisecondsSinceEpoch}', // ID único basado en timestamp
      nombre: nombre,
      imagenAsset: imagenAsset,
      capacidad: capacidad,
      ubicacion: ubicacion,
    );
    _salas.add(nuevaSala);
    _guardarDatos(); // Guardar datos
    notifyListeners();
  }

  // Función para cancelar una reserva específica
  void cancelarReserva(String reservaId) {
    // Encontrar la reserva
    final reservaIndex = _reservas.indexWhere((r) => r.id == reservaId);
    if (reservaIndex == -1) {
      throw Exception('Reserva no encontrada');
    }

    final reserva = _reservas[reservaIndex];

    // Liberar la sala (marcarla como no reservada)
    final salaIndex = _salas.indexWhere((sala) => sala.id == reserva.salaId);
    if (salaIndex != -1) {
      _salas[salaIndex].isReservada = false;
    }

    // Marcar la reserva como cancelada en lugar de eliminarla
    _reservas[reservaIndex].isCancelled = true;

    _guardarDatos(); // Guardar datos
    notifyListeners();
  }

  // Función para editar una sala existente
  void editarSala(
    String salaId, {
    String? nombre,
    int? capacidad,
    String? ubicacion,
    String? imagenAsset,
  }) {
    final salaIndex = _salas.indexWhere((sala) => sala.id == salaId);
    if (salaIndex != -1) {
      if (nombre != null && nombre.isNotEmpty) {
        _salas[salaIndex].nombre = nombre;
      }
      if (capacidad != null && capacidad > 0) {
        _salas[salaIndex].capacidad = capacidad;
      }
      if (ubicacion != null && ubicacion.isNotEmpty) {
        _salas[salaIndex].ubicacion = ubicacion;
      }
      if (imagenAsset != null && imagenAsset.isNotEmpty) {
        _salas[salaIndex].imagenAsset = imagenAsset;
      }

      _guardarDatos(); // Guardar datos
      notifyListeners();
    }
  }

  // Función para eliminar una sala
  void eliminarSala(String salaId) {
    // Eliminar todas las reservas asociadas a esta sala
    _reservas.removeWhere((reserva) => reserva.salaId == salaId);

    // Eliminar la sala
    _salas.removeWhere((sala) => sala.id == salaId);

    _guardarDatos(); // Guardar datos
    notifyListeners();
  }

  // Notificación al liberar sala
  Future<void> _mostrarNotificacionLiberacionSala(Sala sala) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'liberacion_channel_id',
          'Liberación de Sala',
          channelDescription: 'Notificaciones sobre la liberación de salas.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Sala Liberada',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      sala.id.hashCode,
      'Sala liberada',
      'La sala ${sala.nombre} ha sido liberada y está disponible.',
      platformChannelSpecifics,
      payload: sala.id,
    );
  }
}
