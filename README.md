# 🎨 Dashboard de Visitantes SENA - Estilo Admin Pro

Dashboard moderno y profesional en Flutter Web que muestra estadísticas de asistencias en tiempo real con gráficas interactivas.

---

## ✨ Características Principales

🎯 **Diseño Profesional**
- Colores institucionales SENA
- Fondo degradado sutil (#F6F9F4)
- Tipografía moderna y legible
- Material Design 3

💳 **Tarjetas Animadas**
- Efecto hover con scale animation
- Sombras dinámicas (4px → 8px)
- Gradiente sutil de fondo
- Íconos con badge circular
- Indicador "trending up"

📊 **Gráfica Interactiva**
- Barras con gradiente vertical
- Datos semanales (L-D)
- Tooltips al hover
- Badge con total semanal
- Grid horizontal sutil

🎯 **Header Destacado**
- Ícono dashboard con sombra
- Título centrado profesional
- Badge de última actualización

📱 **Responsive Design**
- Móvil: 1 columna
- Tablet: 2 columnas  
- Desktop: 3 columnas

🔄 **Actualización**
- Pull to refresh
- Botón flotante con etiqueta
- Indicador de última actualización

---

## 🚀 EJECUTAR AHORA

### Modo Mock (sin backend):

```bash
flutter run -d chrome --web-port 5173
```

**Resultado:**
- ✅ Dashboard moderno con colores SENA
- ✅ 3 tarjetas animadas (145, 23, 8)
- ✅ Gráfica de barras semanal
- ✅ Hover effects funcionando
- ✅ Responsive design

---

### Modo API Real:

```bash
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://TU_IP:PUERTO/api
```

**Formato del endpoint:**

```http
GET http://TU_IP:PUERTO/api/dashboard

Response:
{
  "aprendices": 145,
  "funcionarios": 23,
  "visitantes": 8
}
```

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                  # Entry point + tema aplicado
├── theme/
│   └── app_theme.dart        # Tema personalizado SENA
├── screens/
│   └── dashboard_screen.dart # Dashboard moderno
├── services/
│   └── api_service.dart      # HTTP client + mock mode
└── widgets/
    ├── stat_card.dart        # Tarjetas animadas
    └── visitors_chart.dart   # Gráfica de barras

web/
├── index.html                # Configuración Flutter Web
└── manifest.json             # PWA config
```

**Total: 6 archivos Dart** (arquitectura mínima profesional)

---

## 🎨 Paleta de Colores

| Elemento | Color | Hex |
|----------|-------|-----|
| Primary | Verde SENA | `#00A65A` |
| Background | Verde claro | `#F6F9F4` |
| AppBar | Verde pastel | `#E8F3E8` |
| Cards | Blanco | `#FFFFFF` |
| Aprendices | Azul | `#2196F3` |
| Funcionarios | Naranja | `#FF9800` |
| Visitantes | Verde | `#4CAF50` |

---

## 📊 Vista Previa

```
┌─────────────────────────────────────────────────────────────┐
│  🎯 Dashboard de Visitantes SENA          ⏰ 10:25:30       │
├─────────────────────────────────────────────────────────────┤
│  Estadísticas en tiempo real                                │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ 🎓 📈        │  │ 👔 📈        │  │ 👥 📈        │    │
│  │ Aprendices   │  │ Funcionarios │  │ Visitantes   │    │
│  │              │  │              │  │              │    │
│  │    145       │  │     23       │  │      8       │    │
│  │         total│  │        total │  │         total│    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Asistencias esta semana       📈 Total: 695          │  │
│  │                                                      │  │
│  │   ▂   ▆   ▄   ▅   █   ▃   ▂                       │  │
│  │   L   M   M   J   V   S   D                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ℹ️ Los datos se actualizan automáticamente cada minuto    │
└─────────────────────────────────────────────────────────────┘
                                            [🔄 Actualizar]
```

---

## 🎯 Características Visuales Detalladas

### 1. Tarjetas con Animación

**Efectos al hover:**
- Escala 1.0 → 1.02
- Elevación 4px → 8px
- Sombra con color del tipo
- Badge "trending up" aparece
- Duración: 200ms

**Diseño:**
- Ícono en círculo con gradiente
- Título en gris (#000000 54%)
- Valor grande (36px) con color destacado
- Label "total" pequeño

### 2. Gráfica de Barras

**Características:**
- 7 barras (Lunes a Domingo)
- Gradiente vertical (color 70% → 100%)
- Ancho: 24px
- Bordes redondeados (6px)
- Tooltips interactivos
- Grid horizontal sutil
- Badge con total semanal
- Ícono trending up

**Datos mock actuales:**
```
L: 80  | M: 120 | M: 95  | J: 110
V: 140 | S: 90  | D: 60
Total: 695 visitas
```

### 3. Header Profesional

- Ícono dashboard en contenedor blanco con sombra
- Título "Dashboard de Visitantes SENA" centrado
- Badge de última actualización con ícono reloj
- Background: Verde pastel (#E8F3E8)

---

## 🔧 Personalización

### Cambiar Colores del Tema:

```dart
// lib/theme/app_theme.dart líneas 5-7
static const Color senaPrimary = Color(0xFF00A65A);      // 👈 Primary
static const Color senaBackground = Color(0xFFF6F9F4);   // 👈 Background
static const Color cardWhite = Colors.white;             // 👈 Cards
```

### Cambiar Colores de Tarjetas:

```dart
// lib/screens/dashboard_screen.dart líneas ~210-230
StatCard(
  title: 'Aprendices',
  value: aprendices,
  icon: Icons.school,
  color: Colors.purple,  // 👈 Cambiar color
),
```

### Cambiar Datos de la Gráfica:

```dart
// lib/screens/dashboard_screen.dart línea ~240
VisitorsChart(
  data: [100, 150, 120, 180, 200, 110, 90],  // 👈 Nuevos valores
  labels: ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
  color: AppTheme.senaPrimary,
),
```

---

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2              # Cliente HTTP
  fl_chart: ^1.1.0          # Gráficos profesionales
  cupertino_icons: ^1.0.2   # Íconos iOS
```

**Total: 3 dependencias externas**

---

## 🧪 Testing

### Test 1: Animaciones de Hover
```bash
flutter run -d chrome --web-port 5173
```
1. Pasa el mouse sobre las tarjetas
2. Verifica: escala, sombra, badge

### Test 2: Gráfica Interactiva
1. Pasa el mouse sobre las barras
2. Verifica: tooltips con valores

### Test 3: Responsive
1. Redimensiona la ventana
2. Verifica: 3 → 2 → 1 columnas

### Test 4: Actualización
1. Click en botón "Actualizar"
2. Verifica: animación de carga

---

## 🐛 Solución de Problemas

### Pantalla blanca:
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port 5173
```

### Errores de compilación:
Verifica que `web/index.html` tenga `<base href="/">`

### Gráfica no aparece:
Verifica que `fl_chart` esté en `pubspec.yaml`:
```bash
flutter pub add fl_chart
```

---

## 📱 Plataformas Soportadas

| Plataforma | Comando | Estado |
|------------|---------|--------|
| Chrome | `flutter run -d chrome --web-port 5173` | ✅ Testeado |
| Edge | `flutter run -d edge` | ✅ Compatible |
| Windows | `flutter run -d windows` | ✅ Compatible |
| Android | `flutter run -d android` | ✅ Compatible |
| iOS | `flutter run -d ios` | ✅ Compatible |

---

## 🎯 Próximos Pasos

1. ✅ **Ejecutar ahora:** `flutter run -d chrome --web-port 5173`
2. ⏳ **Desarrollar backend:** Endpoint `/api/dashboard`
3. ⏳ **Agregar endpoint semanal:** `/api/dashboard/weekly`
4. ⏳ **Configurar API_BASE_URL:** Via `--dart-define`
5. ⏳ **Testing con datos reales**
6. ⏳ **Deploy:** `flutter build web --release`

---

## 📞 Archivos Clave

| Archivo | Propósito | Editar para |
|---------|-----------|-------------|
| `lib/theme/app_theme.dart` | Tema visual | Cambiar colores SENA |
| `lib/screens/dashboard_screen.dart` | UI principal | Modificar layout |
| `lib/widgets/stat_card.dart` | Tarjetas | Cambiar animaciones |
| `lib/widgets/visitors_chart.dart` | Gráfica | Personalizar barras |
| `lib/services/api_service.dart` | API/Mock | Cambiar endpoint |

---

## ✅ Checklist de Calidad

- [x] Diseño moderno estilo admin pro
- [x] Colores institucionales SENA
- [x] Tarjetas animadas con hover
- [x] Gráfica interactiva con tooltips
- [x] Header profesional con ícono
- [x] Responsive design (móvil/desktop)
- [x] Pull to refresh
- [x] Botón actualización flotante
- [x] Estados de carga/error
- [x] Logs detallados en consola
- [x] Sin errores de linter
- [x] Tipografía profesional
- [x] Sombras suaves
- [x] Footer informativo

---

## 🎨 Resultado Final

```
✅ Dashboard Estilo Admin Pro
✅ Animaciones suaves y profesionales
✅ Gráfica interactiva fl_chart
✅ Diseño 100% responsive
✅ Colores institucionales SENA
✅ UX moderna y atractiva
✅ Listo para producción
```

---

**✅ Dashboard Moderno: COMPLETADO**  
**📅 Noviembre 2024**  
**🎨 Diseño profesional estilo admin**  
**🚀 Listo para impresionar**
