# 📱 Sistema de Reservas de Salas - Flutter App

## 🎯 Descripción del Proyecto
Una aplicación móvil desarrollada en Flutter para la gestión y reserva de salas. Permite a los usuarios visualizar salas disponibles, realizar reservas con fecha y hora específica, y gestionar sus reservaciones con un sistema de notificaciones integrado.

## ✨ Características Principales
- 🏢 **Gestión de Salas**: Visualización de salas con imágenes, capacidad y ubicación
- 📅 **Sistema de Reservas**: Selección de fecha y hora para reservas
- 🔔 **Notificaciones Locales**: Alertas y recordatorios de reservas
- 🌐 **Internacionalización**: Soporte para múltiples idiomas (Español/Inglés)
- 🎨 **Interfaz Moderna**: Animaciones, confetti y diseño Material 3
- 📊 **Progreso de Reservas**: Barra de progreso en tiempo real
- ⚡ **Provider Pattern**: Gestión de estado eficiente

## 🛠️ Tecnologías Utilizadas
- **Flutter**: Framework principal
- **Dart**: Lenguaje de programación
- **Provider**: Gestión de estado
- **Flutter Local Notifications**: Sistema de notificaciones
- **Intl**: Internacionalización
- **Confetti**: Animaciones celebratorias

---

## 🌳 Flujo de Trabajo con Git Branches

### 📋 Estructura de Ramas

```
master
├── develop
├── feature/notifications-enhancement
├── feature/ui-improvements
└── testing
```

### 🔄 Flujo de Desarrollo Implementado

#### 1. **Rama Principal (master)**
- **Propósito**: Código estable y listo para producción
- **Estado**: Versión funcional base del sistema de reservas
- **Comando**: `git checkout master`

#### 2. **Rama de Desarrollo (develop)**
- **Propósito**: Integración continua de nuevas características
- **Estado**: Desarrollo activo y testing de nuevas funcionalidades
- **Comando**: `git checkout develop`

#### 3. **Feature Branches**

##### 🔔 feature/notifications-enhancement
- **Propósito**: Mejoras en el sistema de notificaciones
- **Desarrollo**: 
  - Configuración avanzada de notificaciones locales
  - Manejo de respuestas de notificación
  - Integración iOS/Android
- **Comando**: `git checkout feature/notifications-enhancement`

##### 🎨 feature/ui-improvements
- **Propósito**: Mejoras en la interfaz de usuario
- **Desarrollo**:
  - Animaciones y transiciones
  - Sistema de confetti
  - Diseño responsivo
  - Material Design 3
- **Comando**: `git checkout feature/ui-improvements`

#### 4. **Rama de Testing (testing)**
- **Propósito**: Pruebas exhaustivas antes de merge a master
- **Estado**: Validación de funcionalidades integradas
- **Comando**: `git checkout testing`

---

## 🚀 Comandos Git para Navegación

### Ver todas las ramas disponibles:
```bash
git branch -a
```

### Cambiar entre ramas:
```bash
# Rama principal
git checkout master

# Rama de desarrollo
git checkout develop

# Características específicas
git checkout feature/notifications-enhancement
git checkout feature/ui-improvements

# Rama de testing
git checkout testing
```

### Ver el historial de commits por rama:
```bash
git log --oneline --graph --all
```

### Ver diferencias entre ramas:
```bash
# Comparar master con develop
git diff master..develop

# Comparar develop con feature
git diff develop..feature/notifications-enhancement
```

---

## 📁 Estructura del Proyecto

```
aplicaciones_P/
├── lib/
│   ├── main.dart                    # Punto de entrada principal
│   ├── models/                      # Modelos de datos (Sala, Reserva)
│   ├── provider/                    # Provider para gestión de estado
│   └── l10n/                        # Archivos de localización
├── assets/                          # Imágenes de las salas
├── android/                         # Configuración Android
├── ios/                            # Configuración iOS
└── README.md                       # Este archivo
```

---

## 🔧 Configuración y Ejecución

### Prerrequisitos:
- Flutter SDK (≥ 3.0.0)
- Dart SDK (≥ 2.18.0)
- Android Studio / VS Code
- Emulador Android o dispositivo físico

### Instalación:
```bash
# Clonar el repositorio
git clone https://github.com/Jonatanagustin178/ProyectoApp.git

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

---

## 📝 Proceso de Desarrollo Documentado

### Fase 1: Desarrollo Base (master)
1. ✅ Configuración inicial del proyecto Flutter
2. ✅ Implementación de la estructura básica de salas
3. ✅ Sistema básico de reservas
4. ✅ Navegación entre pantallas

### Fase 2: Mejoras de Funcionalidad (develop)
1. ✅ Integración del patrón Provider
2. ✅ Sistema de gestión de estado
3. ✅ Validaciones de reservas
4. ✅ Persistencia de datos local

### Fase 3: Sistema de Notificaciones (feature/notifications-enhancement)
1. ✅ Configuración de Flutter Local Notifications
2. ✅ Manejo de permisos para iOS/Android
3. ✅ Implementación de callbacks de notificación
4. ✅ Integración con el sistema de reservas

### Fase 4: Mejoras de UI/UX (feature/ui-improvements)
1. ✅ Implementación de animaciones
2. ✅ Sistema de confetti para celebraciones
3. ✅ Diseño responsivo y moderno
4. ✅ Transiciones suaves entre pantallas

### Fase 5: Testing y Validación (testing)
1. ✅ Pruebas de integración
2. ✅ Validación de funcionalidades
3. ✅ Testing en diferentes dispositivos
4. ✅ Preparación para producción

---

## 🎯 Funcionalidades por Rama

### Master Branch Features:
- Sistema básico de reservas
- Visualización de salas
- Navegación fundamental

### Develop Branch Features:
- Gestión de estado con Provider
- Validaciones mejoradas
- Estructura de datos optimizada

### Feature/Notifications-Enhancement:
- Notificaciones locales completas
- Configuración multiplataforma
- Manejo de respuestas de usuario

### Feature/UI-Improvements:
- Animaciones fluidas
- Efectos visuales (confetti)
- Diseño Material 3
- Experiencia de usuario mejorada

### Testing Branch:
- Integración de todas las características
- Validación completa del sistema
- Optimizaciones finales

---

## 🌐 Internacionalización

El proyecto soporta múltiples idiomas:
- **Español (es)**: Idioma por defecto
- **English (en)**: Idioma alternativo

### Cambiar idioma:
Utiliza el botón de idioma (🌐) en la AppBar para alternar entre idiomas.

## Funcionalidades Implementadas

### Visualización de salas
- Muestra una lista de salas disponibles y reservadas, con imágenes, capacidad y ubicación.

### Sistema de Reservas
- Permite seleccionar fecha, hora de inicio y fin para reservar una sala disponible.

### Liberación de salas
- Opción para liberar una sala reservada antes de que termine el tiempo.

### Mis Reservas
- Pantalla dedicada para ver todas las reservas activas del usuario.

### Animaciones modernas
  - Animaciones de escala en botones y tarjetas.
  - Confetti al reservar o liberar una sala.
  - Barra de progreso animada que muestra el tiempo restante de cada reserva.

### Notificaciones locales
- Recibe notificaciones cuando una reserva está por finalizar (requiere permisos).

### Soporte multilenguaje
- Cambia entre español e inglés desde la interfaz.

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
