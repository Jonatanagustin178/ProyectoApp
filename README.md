# Aplicación de Reservación de Salas

Esta es una aplicación Flutter para la gestión y reservación de salas, desarrollada como proyecto de ejemplo y aprendizaje. Permite a los usuarios ver la disponibilidad de salas, realizar reservas, liberar salas, y visualizar sus reservas activas, todo con una experiencia visual moderna y animada.

## Funcionalidades principales

- **Visualización de salas**: Muestra una lista de salas disponibles y reservadas, con imágenes, capacidad y ubicación.
- **Reservar sala**: Permite seleccionar fecha, hora de inicio y fin para reservar una sala disponible.
- **Liberar sala**: Opción para liberar una sala reservada antes de que termine el tiempo.
- **Mis Reservas**: Pantalla dedicada para ver todas las reservas activas del usuario.
- **Animaciones modernas**:
  - Animaciones de escala en botones y tarjetas.
  - Confetti al reservar o liberar una sala.
  - Barra de progreso animada que muestra el tiempo restante de cada reserva.
- **Notificaciones locales**: Recibe notificaciones cuando una reserva está por finalizar (requiere permisos).
- **Soporte multilenguaje**: Cambia entre español e inglés desde la interfaz.

## Mejoras y extras agregados

- Barra de progreso animada en la pantalla de "Mis Reservas".
- Animaciones visuales en botones y tarjetas para una mejor experiencia de usuario.
- Efecto confetti al reservar y liberar salas.
- Validaciones de fecha y hora para evitar reservas inválidas.
- Interfaz adaptada a Material 3.

## Instalación y ejecución

1. Clona este repositorio:
   ```
   git clone <URL_DE_TU_REPOSITORIO>
   ```
2. Entra a la carpeta del proyecto:
   ```
   cd aplicaciones_P
   ```
3. Instala las dependencias:
   ```
   flutter pub get
   ```
4. Ejecuta la app:
   ```
   flutter run
   ```

## Estructura principal del proyecto

- `lib/main.dart`: Lógica principal, pantallas y widgets.
- `lib/models/`: Modelos de datos (Sala, Reserva, etc).
- `lib/provider/`: Lógica de estado y gestión de reservas.
- `assets/`: Imágenes de las salas.
- `l10n/`: Archivos de localización para soporte multilenguaje.

## Dependencias destacadas
- [provider](https://pub.dev/packages/provider)
- [confetti](https://pub.dev/packages/confetti)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [intl](https://pub.dev/packages/intl)

## Créditos y agradecimientos

Desarrollado por [Tu Nombre].

---
¡Personaliza este README con tu nombre y el enlace de tu repositorio antes de publicarlo en GitHub!
