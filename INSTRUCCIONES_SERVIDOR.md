# Servidor WebSocket de Prueba

## Instalación

```bash
npm install
```

## Ejecutar el servidor

```bash
npm start
```

El servidor iniciará:
- **Servidor REST**: `http://localhost:3000`
- **Servidor WebSocket**: `ws://localhost:8080`

## Endpoints REST

### POST /registro
Registra una nueva persona y notifica a todos los clientes WebSocket conectados.

**URL**: `http://localhost:3000/registro`

**Método**: `POST`

**Body** (JSON):
```json
{
  "nombre": "Juan Pérez",
  "rol": "aprendiz"
}
```

**Respuesta** (201 Created):
```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "hora": "10:35:45 AM"
}
```

### GET /registros
Obtiene todos los registros almacenados en memoria.

**URL**: `http://localhost:3000/registros`

**Método**: `GET`

### GET /health
Verifica el estado del servidor.

**URL**: `http://localhost:3000/health`

**Método**: `GET`

## Pruebas con Postman

### 1. Conectar WebSocket

1. Abre Postman
2. Crea una nueva **WebSocket Request**
3. URL: `ws://localhost:8080`
4. Click en **Connect**
5. Deberías ver un mensaje de bienvenida

### 2. Enviar registro REST

1. Crea una nueva **HTTP Request**
2. Método: `POST`
3. URL: `http://localhost:3000/registro`
4. Headers: `Content-Type: application/json`
5. Body (raw JSON):
```json
{
  "nombre": "Carlos Ruiz",
  "rol": "funcionario"
}
```
6. Click en **Send**

### 3. Verificar notificación en tiempo real

En la pestaña del WebSocket, deberías ver inmediatamente un mensaje:

```json
{
  "type": "nuevo_registro",
  "registro": {
    "id": 1,
    "nombre": "Carlos Ruiz",
    "rol": "funcionario",
    "hora": "10:35:45 AM"
  }
}
```

## Formato de mensajes WebSocket

El servidor envía mensajes con el siguiente formato:

```json
{
  "type": "nuevo_registro",
  "registro": {
    "id": 1,
    "nombre": "string",
    "rol": "string",
    "hora": "HH:MM:SS AM/PM"
  }
}
```

## Logs del servidor

El servidor muestra en consola:
- ✅ Cuando un cliente se conecta
- ❌ Cuando un cliente se desconecta
- 📥 Cuando se recibe un registro
- 📢 Cuántos clientes recibieron la notificación
- ❌ Errores si ocurren

## Conectar desde Flutter

Para conectar el dashboard Flutter, ejecuta la app con:

```bash
flutter run --dart-define=WS_URL=ws://localhost:8080
```

O configura la variable de entorno `WS_URL` en tu entorno de desarrollo.

