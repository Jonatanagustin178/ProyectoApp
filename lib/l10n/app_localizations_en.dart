// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Room Management';

  @override
  String get availableRooms => 'Available Rooms';

  @override
  String get myReservations => 'My Reservations';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get releaseRoom => 'Release Room';

  @override
  String get reserveRoom => 'Reserve Room';

  @override
  String get capacity => 'Capacity';

  @override
  String get location => 'Location';

  @override
  String get stateReserved => 'State: Reserved';

  @override
  String get stateAvailable => 'State: Available';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectStart => 'Select Start';

  @override
  String get selectEnd => 'Select End';

  @override
  String get noReservations => 'You have no reservations yet.';

  @override
  String get pleaseSelectDateTime => 'Please select date and times.';

  @override
  String get endAfterStart => 'End time must be after start time.';
}
