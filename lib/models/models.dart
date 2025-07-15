// lib/models/models.dart
import 'package:flutter/material.dart';

class Sala {
  final String id;
  final String nombre;
  final String imagenAsset;
  int capacidad;
  String ubicacion;
  bool isReservada; // Indicador de si la sala está reservada

  Sala({
    required this.id,
    required this.nombre,
    required this.imagenAsset,
    required this.capacidad,
    required this.ubicacion,
    this.isReservada = false,
  });
}

class Reserva {
  final String id;
  final String salaId;
  final String nombreSala;
  final DateTime fechaReserva;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  Reserva({
    required this.id,
    required this.salaId,
    required this.nombreSala,
    required this.fechaReserva,
    required this.horaInicio,
    required this.horaFin,
  });
}
