// lib/provider/provider_reservaciones.dart (Asegúrate de que la ruta y el nombre del archivo sean correctos)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import '../main.dart'; // Importar main.dart para acceder a la instancia global de flutterLocalNotificationsPlugin
import 'package:intl/intl.dart'; // Importar para formatear la fecha/hora en la notificación
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  List<Sala> get salas => [..._salas];
  List<Reserva> get reservas => [..._reservas];

  void reservarSala(
    String salaId,
    DateTime fecha,
    TimeOfDay horaInicio,
    TimeOfDay horaFin,
    BuildContext context, // ¡Ahora recibe el BuildContext!
  ) {
    final salaIndex = _salas.indexWhere((sala) => sala.id == salaId);
    if (salaIndex != -1 && !_salas[salaIndex].isReservada) {
      _salas[salaIndex].isReservada = true;
      final nuevaReserva = Reserva(
        id: DateTime.now().toString(),
        salaId: salaId,
        nombreSala: _salas[salaIndex].nombre,
        fechaReserva: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
      );
      _reservas.add(nuevaReserva);
      // Notificación inmediata
      _mostrarNotificacionReservaExitosa(nuevaReserva, context);
      // Notificación programada 5 minutos antes de que termine la reserva
      _programarNotificacionFinReserva(nuevaReserva, context);
      notifyListeners();
      print('Sala ${_salas[salaIndex].nombre} reservada con éxito!');
    } else {
      print('La sala ya está reservada o no se encontró.');
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
            channelDescription: 'Notificación cuando la sala está por terminar',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> liberarSala(String salaId) async {
    final salaIndex = _salas.indexWhere((sala) => sala.id == salaId);
    if (salaIndex != -1 && _salas[salaIndex].isReservada) {
      _salas[salaIndex].isReservada = false;
      _reservas.removeWhere((reserva) => reserva.salaId == salaId);
      notifyListeners();
      await _mostrarNotificacionLiberacionSala(_salas[salaIndex]);
      print('Sala ${_salas[salaIndex].nombre} liberada.');
    }
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
