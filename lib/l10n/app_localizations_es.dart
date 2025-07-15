// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gestión de Salas';

  @override
  String get availableRooms => 'Salas Disponibles';

  @override
  String get myReservations => 'Mis Reservas';

  @override
  String get editRoom => 'Editar Sala';

  @override
  String get releaseRoom => 'Liberar Sala';

  @override
  String get reserveRoom => 'Reservar Sala';

  @override
  String get capacity => 'Capacidad';

  @override
  String get location => 'Ubicación';

  @override
  String get stateReserved => 'Estado: Reservada';

  @override
  String get stateAvailable => 'Estado: Disponible';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get selectDate => 'Seleccionar Fecha';

  @override
  String get selectStart => 'Seleccionar Inicio';

  @override
  String get selectEnd => 'Seleccionar Fin';

  @override
  String get noReservations => 'Aún no tienes reservas.';

  @override
  String get pleaseSelectDateTime => 'Por favor, selecciona fecha y horas.';

  @override
  String get endAfterStart =>
      'La hora de fin debe ser posterior a la de inicio.';
}
