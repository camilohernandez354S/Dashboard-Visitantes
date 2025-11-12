# 🧪 Ejemplos de Prueba para Postman

## 📋 Endpoint WebSocket

**URL**: `ws://localhost:8080`

**Método**: WebSocket Connection

## 📋 Endpoint REST

**URL**: `http://localhost:3000/registro`

**Método**: `POST`

**Headers**:
```
Content-Type: application/json
```

---

## 🧪 Ejemplos de Prueba por Rol

### 1️⃣ Rol: Visitante

```json
{
  "nombre": "María González",
  "rol": "visitante"
}
```

**Resultado esperado:**
- Contador de **Visitantes** aumenta en 1
- Gráfica horaria muestra el nuevo registro
- Resumen ejecutivo se actualiza
- Tarjeta de Visitantes muestra el breakdown

---

### 2️⃣ Rol: Aprendiz con Sede

```json
{
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "sede": "Modelo"
}
```

**Resultado esperado:**
- Contador de **Aprendices** aumenta en 1
- Gráfica horaria se actualiza
- Trend semanal muestra el incremento
- Breakdown por sede muestra: **Modelo: 1**
- Tarjeta de Aprendices muestra el breakdown por sede

---

### 3️⃣ Rol: Instructor

```json
{
  "nombre": "Laura Gómez",
  "rol": "instructor"
}
```

**Resultado esperado:**
- Contador de **Instructores** aumenta en 1
- Tarjeta de Instructores muestra el nuevo valor

---

### 4️⃣ Rol: Funcionario

```json
{
  "nombre": "Carlos Ruiz",
  "rol": "funcionario"
}
```

**Resultado esperado:**
- Contador de **Funcionarios** aumenta en 1
- Dashboard se actualiza en tiempo real

---

## 🎯 Secuencia de Prueba Recomendada

### Paso 1: Conectar WebSocket en Postman
1. Abre Postman
2. Crea una nueva **WebSocket Request**
3. URL: `ws://localhost:8080`
4. Click en **Connect**
5. Deberías ver un mensaje de bienvenida

### Paso 2: Verificar Estado Inicial del Dashboard
- Ejecuta el dashboard Flutter
- Verifica que todos los contadores estén en **0**
- Verifica que la gráfica horaria esté vacía

### Paso 3: Enviar Registro de Aprendiz con Sede
1. Crea una nueva **HTTP Request** en Postman
2. Método: `POST`
3. URL: `http://localhost:3000/registro`
4. Headers: `Content-Type: application/json`
5. Body (raw JSON):
```json
{
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "sede": "Modelo"
}
```
6. Click en **Send**

### Paso 4: Verificar Actualización en Tiempo Real
**En el dashboard Flutter deberías ver:**
- ✅ Contador de **Aprendices** cambia de 0 a 1
- ✅ Gráfica horaria muestra un punto en la hora actual
- ✅ Resumen ejecutivo se actualiza
- ✅ Indicador "Última actualización" muestra la hora actual
- ✅ Tarjeta de Aprendices muestra el nuevo valor
- ✅ Breakdown por sede muestra: **Modelo: 1** en la tarjeta de Aprendices

**En la consola del dashboard deberías ver:**
```
📥 Nuevo registro recibido por WebSocket: Juan Pérez (Aprendiz)
📊 Datos actualizados - Instructores: 0, Aprendices: 1, Funcionarios: 0, Visitantes: 0
✅ Registro agregado y emitido al stream - Total registros: 1
🔄 Actualización recibida del stream - Aprendices: 1, Total registros: 1
✅ UI actualizada - Nuevo registro agregado (0 → 1 registros)
```

**En la consola del servidor Node.js deberías ver:**
```
📥 Registro recibido: Juan Pérez (aprendiz) - Sede: Modelo
📢 Enviado a 1 cliente(s)
```

**En la pestaña WebSocket de Postman deberías ver:**
```json
{
  "type": "nuevo_registro",
  "registro": {
    "id": 1,
    "nombre": "Juan Pérez",
    "rol": "aprendiz",
    "hora": "10:35:45 AM",
    "sede": "Modelo"
  }
}
```

---

## 🔄 Prueba de Múltiples Registros

### Secuencia de Prueba:

**1. Primer registro - Visitante:**
```json
{
  "nombre": "María González",
  "rol": "visitante"
}
```
Resultado: Visitantes = 1

**2. Segundo registro - Aprendiz con Sede:**
```json
{
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "sede": "Modelo"
}
```
Resultado: Aprendices = 1, Visitantes = 1, Breakdown: Modelo = 1

**3. Tercer registro - Visitante:**
```json
{
  "nombre": "Carlos Mendoza",
  "rol": "visitante"
}
```
Resultado: Visitantes = 2, Aprendices = 1

**4. Cuarto registro - Instructor:**
```json
{
  "nombre": "Laura Gómez",
  "rol": "instructor"
}
```
Resultado: Instructores = 1, Visitantes = 2, Aprendices = 1, Breakdown: Modelo = 1

**5. Quinto registro - Aprendiz con otra Sede:**
```json
{
  "nombre": "Carlos Mendoza",
  "rol": "aprendiz",
  "sede": "Centro"
}
```
Resultado: Aprendices = 2, Breakdown: Modelo = 1, Centro = 1

---

## 📊 Verificación de Datos

### Endpoint: GET /registros

**URL**: `http://localhost:3000/registros`

**Método**: `GET`

**Respuesta esperada:**
```json
{
  "total": 4,
  "registros": [
    {
      "id": 4,
      "nombre": "Laura Gómez",
      "rol": "instructor",
      "hora": "10:40:12 PM"
    },
    {
      "id": 3,
      "nombre": "Carlos Mendoza",
      "rol": "visitante",
      "hora": "10:39:30 PM"
    },
    {
      "id": 2,
      "nombre": "Juan Pérez",
      "rol": "aprendiz",
      "hora": "10:38:15 PM"
    },
    {
      "id": 1,
      "nombre": "María González",
      "rol": "visitante",
      "hora": "10:35:45 PM"
    }
  ]
}
```

---

## 🐛 Troubleshooting

### Si no se actualiza en tiempo real:

1. **Verifica que el WebSocket esté conectado:**
   - Revisa los logs del servidor Node.js
   - Deberías ver: `✅ Cliente conectado`

2. **Verifica los logs del dashboard:**
   - Deberías ver: `✅ WebSocket conectado exitosamente`
   - Deberías ver: `📥 Nuevo registro recibido por WebSocket`

3. **Verifica que el servidor esté corriendo:**
   ```bash
   # En una terminal
   npm start
   ```

4. **Verifica la respuesta del servidor:**
   - En Postman, verifica que el POST retorne `201 Created`
   - Verifica que el body de respuesta contenga el registro

5. **Verifica la conexión WebSocket:**
   - En Postman WebSocket, deberías recibir el mensaje inmediatamente
   - Si no recibes el mensaje, verifica que el servidor esté emitiendo

---

## 📝 Ejemplo Completo: Prueba de Aprendiz con Sede Modelo

### Request en Postman:

**Método**: `POST`

**URL**: `http://localhost:3000/registro`

**Headers**:
```
Content-Type: application/json
```

**Body (raw JSON)**:
```json
{
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "sede": "Modelo"
}
```

### Respuesta del Servidor:

```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "hora": "10:35:45 AM",
  "sede": "Modelo"
}
```

### Mensaje WebSocket Recibido:

```json
{
  "type": "nuevo_registro",
  "registro": {
    "id": 1,
    "nombre": "Juan Pérez",
    "rol": "aprendiz",
    "hora": "10:35:45 AM",
    "sede": "Modelo"
  }
}
```

### Cambios en el Dashboard:

- **Antes**: Aprendices = 0
- **Después**: Aprendices = 1
- **Gráfica horaria**: Muestra 1 registro en la hora actual
- **Resumen ejecutivo**: "Esta semana se registraron 1 asistencias en total..."
- **Tarjeta de Aprendices**: Muestra el valor 1 con variación 0%
- **Breakdown por sede**: Muestra **Modelo: 1** en la tarjeta de Aprendices
- **Distribución por sede**: El resumen ejecutivo incluye información de la sede Modelo

---

## 📝 Ejemplo Completo: Prueba de Visitante (sin sede)

### Request en Postman:

**Método**: `POST`

**URL**: `http://localhost:3000/registro`

**Headers**:
```
Content-Type: application/json
```

**Body (raw JSON)**:
```json
{
  "nombre": "María González",
  "rol": "visitante"
}
```

### Respuesta del Servidor:

```json
{
  "id": 1,
  "nombre": "María González",
  "rol": "visitante",
  "hora": "10:35:45 AM",
  "sede": null
}
```

### Mensaje WebSocket Recibido:

```json
{
  "type": "nuevo_registro",
  "registro": {
    "id": 1,
    "nombre": "María González",
    "rol": "visitante",
    "hora": "10:35:45 AM",
    "sede": null
  }
}
```

### Cambios en el Dashboard:

- **Antes**: Visitantes = 0
- **Después**: Visitantes = 1
- **Gráfica horaria**: Muestra 1 registro en la hora actual
- **Resumen ejecutivo**: "Esta semana se registraron 1 asistencias en total..."
- **Tarjeta de Visitantes**: Muestra el valor 1 con variación 0%
- **Breakdown por sede**: Muestra **Sin sede: 1** (porque no se proporcionó sede)

---

## ✅ Checklist de Verificación

- [ ] Servidor Node.js corriendo en `http://localhost:3000`
- [ ] WebSocket activo en `ws://localhost:8080`
- [ ] Dashboard Flutter ejecutándose
- [ ] WebSocket conectado en Postman
- [ ] POST request configurado correctamente
- [ ] Body JSON válido con `nombre` y `rol`
- [ ] Respuesta del servidor es `201 Created`
- [ ] Mensaje WebSocket recibido en Postman
- [ ] Dashboard se actualiza en tiempo real
- [ ] Contadores aumentan correctamente
- [ ] Gráfica horaria se actualiza
- [ ] Logs muestran el flujo completo

---

## 🎯 Prueba Rápida: Aprendiz con Sede Modelo

**Copia y pega esto en Postman:**

```
POST http://localhost:3000/registro
Content-Type: application/json

{
  "nombre": "Juan Pérez",
  "rol": "aprendiz",
  "sede": "Modelo"
}
```

**Resultado esperado:**
- Dashboard muestra: **Aprendices: 1**
- Breakdown por sede muestra: **Modelo: 1** en la tarjeta de Aprendices
- Actualización en tiempo real sin recargar
- Logs muestran el flujo completo
- Gráfica horaria muestra el registro en la hora actual

---

## 🎯 Prueba Rápida: Visitante

**Copia y pega esto en Postman:**

```
POST http://localhost:3000/registro
Content-Type: application/json

{
  "nombre": "María González",
  "rol": "visitante"
}
```

**Resultado esperado:**
- Dashboard muestra: **Visitantes: 1**
- Actualización en tiempo real sin recargar
- Logs muestran el flujo completo

