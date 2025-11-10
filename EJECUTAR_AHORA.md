# 🚀 EJECUTAR DASHBOARD - INSTRUCCIONES

## ✅ PROBLEMA RESUELTO

**Pantalla blanca en Flutter Web:** ✅ CORREGIDO  
**Causa:** `web/index.html` estaba vacío  
**Solución:** Implementada arquitectura mínima funcional

---

## 📋 PASO A PASO

### 1️⃣ Instalar Dependencias

Abre terminal en la raíz del proyecto:

```bash
cd C:\Documentos\trabajos\Programing\Proyecto-APP\dashboard_visitantes
flutter pub get
```

**Esperado:** "Got dependencies!" sin errores

---

### 2️⃣ Ejecutar en Modo MOCK (Recomendado)

```bash
flutter run -d chrome --web-port 5173
```

**Esperado:**
- ✅ Chrome abre en `http://localhost:5173`
- ✅ Dashboard con 3 tarjetas
- ✅ **145** Aprendices (azul 🎓)
- ✅ **23** Funcionarios (naranja 👔)
- ✅ **8** Visitantes (verde 👥)

**Logs en consola:**
```
📦 [ApiService] API_BASE_URL vacío → usando datos MOCK
```

---

### 3️⃣ (Opcional) Ejecutar con API Real

Si ya tienes tu backend funcionando:

```bash
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
```

**Reemplaza:**
- `192.168.1.100` por tu IP
- `8000` por tu puerto
- `/api` por tu base path

**Tu endpoint debe responder:**

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

## 🎯 QUÉ VERÁS

### Dashboard Responsive:

```
┌─────────────────────────────────────────────────────┐
│  Dashboard de Visitantes SENA          [🔄 Refresh] │
├─────────────────────────────────────────────────────┤
│  Última actualización: 10:25:30                     │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│
│  │ 🎓           │  │ 👔           │  │ 👥        ││
│  │ Aprendices   │  │ Funcionarios │  │ Visitantes││
│  │              │  │              │  │           ││
│  │     145      │  │      23      │  │     8     ││
│  └──────────────┘  └──────────────┘  └───────────┘│
│                                                     │
└─────────────────────────────────────────────────────┘
                                            🔄 (FAB)
```

---

## 🔧 Características Implementadas

✅ **Modo Mock Automático**
- Sin backend necesario
- Datos hardcodeados: 145, 23, 8
- Perfecto para desarrollo

✅ **Modo API Real**
- Via `--dart-define=API_BASE_URL=...`
- Timeout: 6 segundos
- Fallback a mock si falla

✅ **UI Moderna**
- Material Design 3
- 3 tarjetas con íconos y colores
- Responsive (móvil, tablet, desktop)

✅ **Manejo de Errores**
- Estados: loading / error / datos
- Botón "Reintentar"
- Logs detallados en consola

✅ **Interactividad**
- FAB para refresh manual
- Última actualización visible
- Pull to refresh (redimensiona ventana)

---

## 🐛 Solución de Problemas

### Si Chrome no abre:

```bash
# Verifica dispositivos disponibles
flutter devices

# Si no aparece Chrome, intenta con Edge
flutter run -d edge
```

### Si ves errores en consola:

1. Abre DevTools (F12) → Console
2. Busca líneas que empiecen con:
   - `❌` → Error
   - `📦` → Modo mock
   - `🌐` → Consultando API
   - `✅` → Éxito

### Si el puerto 5173 está ocupado:

```bash
flutter run -d chrome --web-port 8080  # Cambia el puerto
```

### Si no compila:

```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port 5173
```

---

## 📊 Testing Rápido

### Test 1: Verificar Compilación
```bash
flutter analyze
```
**Esperado:** "No issues found!"

### Test 2: Modo Mock
```bash
flutter run -d chrome --web-port 5173
```
**Esperado:** Dashboard con 145, 23, 8

### Test 3: Responsive
1. Ejecuta el dashboard
2. Redimensiona la ventana del navegador
3. Verifica que las columnas cambien:
   - Ventana estrecha: 1 columna
   - Ventana media: 2 columnas
   - Ventana ancha: 3 columnas

---

## 🎨 Personalización Rápida

### Cambiar Datos Mock:

```dart
// lib/services/api_service.dart línea ~13
return {
  "aprendices": 200,     // 👈 Cambiar aquí
  "funcionarios": 50,    // 👈 Cambiar aquí
  "visitantes": 15,      // 👈 Cambiar aquí
};
```

### Cambiar Colores:

```dart
// lib/screens/dashboard_screen.dart líneas ~115-130
StatCard(
  title: 'Aprendices',
  value: aprendices,
  icon: Icons.school,
  color: Colors.purple,  // 👈 Azul → Morado
),
```

### Cambiar Íconos:

```dart
icon: Icons.person_outline,  // 👈 school → person_outline
```

Íconos disponibles: https://fonts.google.com/icons

---

## 📦 Estructura Final

```
lib/
├── main.dart                  ✅ Punto de entrada + error handling
├── screens/
│   └── dashboard_screen.dart ✅ UI principal
├── services/
│   └── api_service.dart      ✅ HTTP client + mock
└── widgets/
    └── stat_card.dart        ✅ Tarjeta de estadística
```

**Total: 4 archivos Dart** (mínimo funcional)

---

## 🚀 Comandos Rápidos

```bash
# Desarrollo (Mock)
flutter run -d chrome --web-port 5173

# Producción (API Real)
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://TU_IP:PUERTO/api

# Build para Deploy
flutter build web --release

# Limpiar caché
flutter clean

# Actualizar dependencias
flutter pub get

# Ver logs detallados
flutter run -d chrome --web-port 5173 --verbose
```

---

## ✅ Checklist de Verificación

Antes de continuar, verifica:

- [ ] Terminal en la raíz del proyecto
- [ ] `flutter pub get` ejecutado sin errores
- [ ] Chrome instalado
- [ ] Puerto 5173 disponible
- [ ] Internet activo (para descargar dependencias)

---

## 🎯 COMANDO PRINCIPAL

**Si es la primera vez:**

```bash
cd C:\Documentos\trabajos\Programing\Proyecto-APP\dashboard_visitantes
flutter clean
flutter pub get
flutter run -d chrome --web-port 5173
```

**Si ya ejecutaste antes:**

```bash
flutter run -d chrome --web-port 5173
```

---

## 📞 Archivos Importantes

| Archivo | Qué hace | Editar para |
|---------|----------|-------------|
| `lib/services/api_service.dart` | Consulta API o mock | Cambiar datos mock, URL API |
| `lib/screens/dashboard_screen.dart` | UI del dashboard | Cambiar colores, íconos |
| `lib/widgets/stat_card.dart` | Diseño de tarjetas | Cambiar estilos |
| `web/index.html` | Config Flutter Web | Título, meta tags |

---

## 🎉 RESULTADO ESPERADO

Al ejecutar `flutter run -d chrome --web-port 5173`:

1. ✅ Terminal muestra: "Launching lib\main.dart on Chrome..."
2. ✅ Chrome abre automáticamente
3. ✅ Dashboard visible en menos de 3 segundos
4. ✅ 3 tarjetas con números: **145**, **23**, **8**
5. ✅ FAB (botón flotante) visible abajo a la derecha
6. ✅ Console log: "📦 [ApiService] API_BASE_URL vacío → usando datos MOCK"
7. ✅ Al hacer click en FAB, los datos se actualizan
8. ✅ Responsive: redimensiona ventana y las columnas cambian

---

**✅ Dashboard Funcionando en Modo Mock**  
**🎯 Listo para desarrollo**  
**🚀 Siguiente paso: Desarrollar tu backend**  
**📅 Noviembre 2024**

