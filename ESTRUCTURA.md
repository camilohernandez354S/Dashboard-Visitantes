# Estructura del Proyecto Dashboard Visitantes

## Backend (FastAPI + Python)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── dependencies.py
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── attendance.py
│   │       └── websocket.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── database.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── attendance.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   └── attendance.py
│   └── services/
│       ├── __init__.py
│       ├── attendance_service.py
│       └── websocket_manager.py
├── .gitignore
├── Dockerfile
└── requirements.txt

## Frontend (Flutter)

```
frontend/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── models/
│   │   ├── attendance_model.dart
│   │   └── stats_model.dart
│   ├── providers/
│   │   └── attendance_provider.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   └── attendance_list_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── websocket_service.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   └── date_formatter.dart
│   └── widgets/
│       ├── attendance_card.dart
│       └── stats_widget.dart
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── ios/
│   └── Runner/
│       └── Info.plist
├── web/
│   └── index.html
└── pubspec.yaml

## Raíz del Proyecto

```
dashboard_visitantes/
├── backend/
├── frontend/
├── .gitignore
├── docker-compose.yml
└── README.md
```

## Descripción de Componentes

### Backend
- **main.py**: Punto de entrada de la aplicación FastAPI
- **api/routes**: Endpoints REST y WebSocket
- **core**: Configuración y conexión a base de datos
- **models**: Modelos de SQLAlchemy (ORM)
- **schemas**: Schemas de Pydantic (validación)
- **services**: Lógica de negocio y gestión de WebSocket

### Frontend
- **main.dart**: Punto de entrada de la aplicación Flutter
- **config**: Configuración de la aplicación
- **models**: Modelos de datos
- **providers**: Estado global (Provider/Riverpod)
- **screens**: Pantallas principales
- **services**: Servicios de API y WebSocket
- **utils**: Utilidades y constantes
- **widgets**: Componentes reutilizables

