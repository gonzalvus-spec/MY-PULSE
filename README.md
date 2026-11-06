# MiPulso — Control de presión arterial

Aplicación móvil desarrollada en **Flutter** para registrar, consultar y exportar las mediciones de presión arterial de un paciente. Los datos se guardan en **MongoDB** y el historial se puede imprimir o compartir como **PDF**.

> Paquete Flutter: `presion_arterial_app` · Carpeta del proyecto: `MiPulso`

---

## Características

- **Registro del paciente**: nombre completo y DNI antes de comenzar.
- **Nueva medición**: presión sistólica (SYS), diastólica (DIA), pulso y fecha/hora.
- **Clasificación automática** de cada lectura con color e indicador:

  | Estado   | Criterio                          | Color   |
  | -------- | --------------------------------- | ------- |
  | Normal   | SYS < 120 y DIA < 80              | Verde   |
  | Elevada  | SYS ≤ 129 y DIA < 80              | Ámbar   |
  | Alta     | SYS ≤ 139 o DIA ≤ 89              | Naranja |
  | Muy alta | Cualquier valor por encima        | Rojo    |

- **Historial agrupado por día** con etiquetas «Hoy», «Ayer» y la fecha completa en español.
- **Editar y eliminar** mediciones desde la tarjeta o el menú de cada registro.
- **Editar los datos del paciente** en cualquier momento.
- **Exportar a PDF** por rango de fechas, con cabecera del paciente, tabla de mediciones, numeración de páginas y aviso médico.
- **Sincronización directa con MongoDB Atlas** (sin servidor intermedio).
- Interfaz Material 3, en español, con color principal `#006689`.

---

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) con **Dart 3.13** o superior.
- Toolchain de la plataforma destino (Android Studio, Xcode o Visual Studio).
- Una base de datos **MongoDB** (local o Atlas) accesible desde el dispositivo.

Comprobar el entorno:

```bash
flutter doctor
```

---

## Instalación y ejecución

```bash
cd MiPulso
flutter pub get
flutter run
```

Para generar los iconos de la app a partir de `assets/icon/app_icon.png`:

```bash
dart run flutter_launcher_icons
```

Para compilar una versión de producción:

```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build windows --release  # Windows
```

---

## Configuración de la base de datos

Las credenciales **no están en el código**. La app lee la URI de MongoDB desde la variable `MONGO_URI` del archivo `.env`:

1. Copia la plantilla y renómbrala:

   ```bash
   cp .env.example .env
   ```

2. Edita `.env` con tu cadena de conexión:

   ```env
   MONGO_URI=mongodb+srv://USUARIO:CONTRASEÑA@cluster.mongodb.net/mipulso?retryWrites=true&w=majority
   ```

3. Ejecuta la app con normalidad (`flutter run`). Si falta la variable, la app muestra un error indicando que configures `.env`.

`.env` está incluido en `.gitignore`, así que tus credenciales no se suben al repositorio. Solo se versiona `.env.example` con valores de ejemplo.

> **Importante:** si la contraseña estuvo publicada en algún momento, rótala en MongoDB Atlas. Y recuerda que cualquier archivo incluido como *asset* viaja dentro del APK: `.env` evita filtrar las credenciales en Git, no protege la base frente a alguien que extraiga el binario.

La app crea y usa estas colecciones automáticamente:

| Colección    | Contenido                                                        |
| ------------ | ---------------------------------------------------------------- |
| `paciente`   | Un único documento con `nombre`, `dni` y fecha de actualización.  |
| `mediciones` | Una entrada por lectura: `_id`, `sys`, `dia`, `pulso` y `fecha`. |

> Las mediciones guardan los valores y la fecha como texto (`dd/MM/yyyy HH:mm`). El servicio de PDF y la pantalla de edición aceptan además fechas ISO y `DateTime`.

---

## Estructura del proyecto

```
MiPulso/
├── lib/
│   ├── main.dart                  # Punto de entrada y tema de la app
│   ├── mongo_service.dart         # Conexión reutilizable a MongoDB
│   ├── screens/
│   │   ├── splash_screen.dart     # Splash y registro inicial del paciente
│   │   ├── home_screen.dart       # Historial, estado, edición y exportación
│   │   └── add_record_screen.dart # Alta y edición de una medición
│   └── services/
│       └── pdf_service.dart       # Generación e impresión del reporte PDF
├── assets/
│   └── icon/app_icon.png          # Icono de la aplicación
├── .env                           # Credenciales locales (ignorado por Git)
├── .env.example                   # Plantilla de variables de entorno
├── backend/                       # API REST opcional (Express + Mongoose)
├── android/ · ios/ · windows/ …   # Plataformas generadas por Flutter
└── pubspec.yaml
```

### Dependencias principales

| Paquete            | Uso                                        |
| ------------------ | ------------------------------------------ |
| `mongo_dart`       | Conexión y consultas a MongoDB             |
| `pdf`              | Construcción del documento PDF             |
| `printing`         | Vista previa, impresión y compartir el PDF |
| `flutter_animate`  | Animaciones de interfaz                    |
| `flutter_launcher_icons` | Generación de iconos (solo desarrollo) |

---

## Backend opcional (Express + Mongoose)

La carpeta `backend/` incluye una API REST de referencia que **no utiliza la app Flutter** (esta se conecta directo a MongoDB). Sirve si prefieres exponer los datos por HTTP.

```bash
cd backend
npm install express mongoose cors
node server.js
```

- Escucha en `http://localhost:3000`.
- Usa `MONGO_URI` del entorno o, por defecto, `mongodb://localhost:27017/presion_arterial_db`.
- Endpoints:
  - `GET /api/records` — lista las mediciones, de la más reciente a la más antigua.
  - `POST /api/records` — crea una medición (`systolic`, `diastolic`, `pulse`, `timestamp`).

> `backend/package.json` está vacío; por eso las dependencias se instalan a mano con el comando anterior.

---

## Seguridad y privacidad

- Este proyecto maneja **datos de salud**. No publiques mediciones ni datos personales reales en el repositorio, capturas o issues.
- La URI de MongoDB vive en `.env`, ignorado por Git. No la escribas de nuevo en el código ni la compartas en capturas o issues.
- El PDF generado incluye un aviso: la app **no sustituye** la evaluación ni el diagnóstico de un profesional de salud.

---

## Estado del proyecto

Versión `1.0.0+1`. Pensado para un único paciente por instalación: al registrar o editar el paciente se reemplaza el documento existente en la colección `paciente`.
