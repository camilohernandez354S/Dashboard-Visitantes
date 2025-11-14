# Documentación de Endpoints Backend Laravel

**Base URL:** `http://10.7.52.227:8000/api`

## Endpoints REST

### 1. GET /websocket/estadisticas

Obtiene las estadísticas generales del dashboard.

#### Parámetros
- Ninguno

#### Cabeceras obligatorias
```
Accept: application/json
```

#### Respuesta exitosa (HTTP 200)
```json
{
  "success": true,
  "data": {
    /* Estructura de estadísticas general, ej. conteos por tipo */
  }
}
```

#### Respuesta de error (HTTP 500)
```json
{
  "success": false,
  "message": "Error al obtener estadísticas"
}
```

#### Ejemplo de uso en Dart
```dart
final uri = Uri.parse('http://10.7.52.227:8000/api/websocket/estadisticas');
final response = await http.get(
  uri,
  headers: {'Accept': 'application/json'},
);

if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  // Procesar respuesta
}
```

---

### 2. POST /websocket/entrada

Registra una entrada de visitante.

#### Cabeceras obligatorias
```
Content-Type: application/json
Accept: application/json
```

#### Cuerpo JSON requerido
```json
{
  "persona_id": 123,              // int - ID de la persona
  "nombre": "Juan Pérez",         // string - Nombre completo
  "documento": "1234567890",      // string - Documento identificador
  "rol": "VISITANTE",             // string - Rol textual (ej. "VISITANTE")
  "ficha": "FICHA123",            // string|null - Opcional
  "ambiente": "Ambiente A"        // string|null - Opcional
}
```

#### Respuesta exitosa (HTTP 200)
```json
{
  "success": true,
  "message": "Entrada registrada correctamente",
  "visitante": {
    "id": 123,
    "nombre": "Juan Pérez",
    "documento": "1234567890",
    "rol": "VISITANTE",
    "ficha": "FICHA123",
    "ambiente": "Ambiente A",
    "hora_entrada": "2024-01-15T10:30:00Z"
  }
}
```

#### Respuesta de validación (HTTP 422)
```json
{
  "success": false,
  "message": "Error de validación",
  "errors": {
    "persona_id": ["El campo persona_id es obligatorio"],
    "nombre": ["El campo nombre es obligatorio"]
  }
}
```

#### Respuesta de error (HTTP 500)
```json
{
  "success": false,
  "message": "Error al registrar entrada"
}
```

#### Ejemplo de uso en Dart
```dart
final uri = Uri.parse('http://10.7.52.227:8000/api/websocket/entrada');
final body = {
  'persona_id': 123,
  'nombre': 'Juan Pérez',
  'documento': '1234567890',
  'rol': 'VISITANTE',
  'ficha': 'FICHA123',
  'ambiente': 'Ambiente A',
};

final response = await http.post(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: jsonEncode(body),
);

if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  // Procesar respuesta
}
```

---

### 3. POST /websocket/salida

Registra una salida de visitante.

#### Cabeceras obligatorias
```
Content-Type: application/json
Accept: application/json
```

#### Cuerpo JSON requerido
```json
{
  "persona_id": 123,              // int - ID de la persona
  "nombre": "Juan Pérez",         // string - Nombre completo
  "documento": "1234567890",      // string - Documento identificador
  "rol": "VISITANTE"              // string - Rol textual
}
```

#### Respuesta exitosa (HTTP 200)
```json
{
  "success": true,
  "message": "Salida registrada correctamente",
  "visitante": {
    "id": 123,
    "nombre": "Juan Pérez",
    "documento": "1234567890",
    "rol": "VISITANTE",
    "hora_salida": "2024-01-15T14:30:00Z"
  }
}
```

#### Respuesta de validación (HTTP 422)
```json
{
  "success": false,
  "message": "Error de validación",
  "errors": {
    "persona_id": ["El campo persona_id es obligatorio"],
    "nombre": ["El campo nombre es obligatorio"]
  }
}
```

#### Respuesta de error (HTTP 500)
```json
{
  "success": false,
  "message": "Error al registrar salida"
}
```

#### Ejemplo de uso en Dart
```dart
final uri = Uri.parse('http://10.7.52.227:8000/api/websocket/salida');
final body = {
  'persona_id': 123,
  'nombre': 'Juan Pérez',
  'documento': '1234567890',
  'rol': 'VISITANTE',
};

final response = await http.post(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: jsonEncode(body),
);

if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  // Procesar respuesta
}
```

---

### 4. GET /websocket/visitantes-actuales

Obtiene la lista de visitantes actualmente dentro del centro.

#### Parámetros
- Ninguno

#### Cabeceras obligatorias
```
Accept: application/json
```

#### Respuesta exitosa (HTTP 200)
```json
{
  "success": true,
  "data": [
    // Lista de visitantes actuales. Por ahora se devuelve un array vacío.
  ]
}
```

#### Respuesta de error (HTTP 500)
```json
{
  "success": false,
  "message": "Error al obtener visitantes actuales"
}
```

#### Ejemplo de uso en Dart
```dart
final uri = Uri.parse('http://10.7.52.227:8000/api/websocket/visitantes-actuales');
final response = await http.get(
  uri,
  headers: {'Accept': 'application/json'},
);

if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final visitantes = decoded['data'] as List;
  // Procesar lista de visitantes
}
```

---

## WebSocket (Laravel Reverb)

### Configuración

**Host:** `10.7.52.227`  
**Puerto:** `8080`  
**Esquema:** `ws://` (sin TLS)  
**App Key:** `<REVERB_APP_KEY>` (configurar con la clave real)  
**App ID:** `<REVERB_APP_ID>` (configurar con el ID real)

### URL de conexión
```
ws://10.7.52.227:8080/app/{REVERB_APP_KEY}
```

### Canales y Eventos

#### Canal: `visitantes`

**Evento:** `visitante.actualizado`

**Payload:**
```json
{
  "visitante": {
    "id": 123,
    "nombre": "Juan Pérez",
    "documento": "1234567890",
    "rol": "VISITANTE",
    "ficha": "FICHA123",
    "ambiente": "Ambiente A",
    "hora_entrada": "2024-01-15T10:30:00Z"
  },
  "tipo": "entrada",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

El campo `tipo` puede ser:
- `"entrada"` - Cuando se registra una entrada
- `"salida"` - Cuando se registra una salida

#### Canal: `estadisticas-visitantes`

**Evento:** `estadisticas.actualizadas`

**Payload:**
```json
{
  "estadisticas": {
    /* Mismos datos que GET /websocket/estadisticas */
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Ejemplo de suscripción en Dart

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('ws://10.7.52.227:8080/app/local'),
);

// Suscribirse al canal visitantes
channel.sink.add(jsonEncode({
  'event': 'pusher:subscribe',
  'data': {'channel': 'visitantes'},
}));

// Suscribirse al canal estadisticas-visitantes
channel.sink.add(jsonEncode({
  'event': 'pusher:subscribe',
  'data': {'channel': 'estadisticas-visitantes'},
}));

// Escuchar eventos
channel.stream.listen((event) {
  final message = jsonDecode(event) as Map<String, dynamic>;
  final eventType = message['event'];
  
  if (eventType == 'visitante.actualizado') {
    final data = message['data'];
    // Procesar evento de visitante
  } else if (eventType == 'estadisticas.actualizadas') {
    final data = message['data'];
    // Procesar evento de estadísticas
  }
});
```

---

## Notas Importantes

1. **Accesibilidad de red:** Asegúrate de que la red y el firewall permitan tráfico a `10.7.52.227` en los puertos:
   - `8000` (HTTP)
   - `8080` (WebSocket)

2. **REVERB_APP_KEY:** Necesitas obtener la clave real de la aplicación Reverb desde el archivo `.env` del backend Laravel. Sin esta clave, la conexión WebSocket fallará.

3. **Autenticación:** Si el backend requiere autenticación, necesitarás incluir tokens en las cabeceras de las peticiones REST.

4. **Validación:** Los endpoints POST validan los datos antes de procesarlos. Asegúrate de enviar todos los campos requeridos.

5. **Timeouts:** Los endpoints pueden tardar en responder dependiendo de la carga del servidor. Se recomienda configurar timeouts apropiados en las peticiones.

