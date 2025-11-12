import express from 'express';
import { WebSocketServer } from 'ws';
import cors from 'cors';
import http from 'http';

const app = express();
const PORT_REST = 3000;
const PORT_WS = 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Almacenamiento en memoria
const registros = [];
let idCounter = 1;

// Función para formatear la hora actual
function formatearHora() {
  const now = new Date();
  const hours = now.getHours();
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  const horas12 = hours % 12 || 12;
  return `${horas12}:${minutes}:${seconds} ${ampm}`;
}

// Servidor HTTP para Express
const server = http.createServer(app);

// Servidor WebSocket
const wss = new WebSocketServer({ port: PORT_WS });

// Clientes conectados
const clientes = new Set();

// Manejo de conexiones WebSocket
wss.on('connection', (ws) => {
  clientes.add(ws);
  console.log('✅ Cliente conectado');

  // Enviar mensaje de bienvenida (opcional)
  ws.send(
    JSON.stringify({
      type: 'connection',
      message: 'Conectado al servidor WebSocket de prueba',
    })
  );

  // Manejar desconexión
  ws.on('close', () => {
    clientes.delete(ws);
    console.log('❌ Cliente desconectado');
  });

  // Manejar errores
  ws.on('error', (error) => {
    console.error('❌ Error en WebSocket:', error);
  });

  // Manejar mensajes del cliente (opcional)
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log('📨 Mensaje recibido del cliente:', data);
    } catch (error) {
      console.error('❌ Error al procesar mensaje del cliente:', error);
    }
  });
});

// Función para notificar a todos los clientes
function notificarClientes(registro) {
  const mensaje = {
    type: 'nuevo_registro',
    registro: registro,
  };

  const mensajeJson = JSON.stringify(mensaje);
  let clientesNotificados = 0;

  clientes.forEach((cliente) => {
    if (cliente.readyState === 1) {
      // WebSocket.OPEN = 1
      try {
        cliente.send(mensajeJson);
        clientesNotificados++;
      } catch (error) {
        console.error('❌ Error al enviar mensaje a cliente:', error);
        clientes.delete(cliente);
      }
    }
  });

  console.log(`📢 Enviado a ${clientesNotificados} cliente(s)`);
}

// Endpoint REST: POST /registro
app.post('/registro', (req, res) => {
  try {
    const { nombre, rol, sede } = req.body;

    // Validación
    if (!nombre || !rol) {
      return res.status(400).json({
        error: 'Faltan campos requeridos',
        message: 'Se requieren los campos "nombre" y "rol"',
      });
    }

    // Crear registro con hora actual
    const hora = formatearHora();
    const registro = {
      id: idCounter++,
      nombre: nombre.toString().trim(),
      rol: rol.toString().trim(),
      hora: hora,
      // Sede es opcional, si no se proporciona será null
      sede: sede ? sede.toString().trim() : null,
    };

    // Guardar en memoria
    registros.push(registro);

    const sedeInfo = registro.sede ? ` - Sede: ${registro.sede}` : '';
    console.log(`📥 Registro recibido: ${registro.nombre} (${registro.rol})${sedeInfo}`);

    // Notificar a todos los clientes WebSocket conectados
    notificarClientes(registro);

    // Responder al cliente REST
    res.status(201).json(registro);
  } catch (error) {
    console.error('❌ Error al procesar registro:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message,
    });
  }
});

// Endpoint opcional: GET /registros (para ver todos los registros)
app.get('/registros', (req, res) => {
  // Debug: imprimir registros antes de enviar
  console.log('📤 Enviando registros:', JSON.stringify(registros, null, 2));
  res.json({
    total: registros.length,
    registros: registros,
  });
});

// Endpoint de salud
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    clientesConectados: clientes.size,
    totalRegistros: registros.length,
  });
});

// Iniciar servidor REST
server.listen(PORT_REST, () => {
  console.log(`🚀 Servidor REST en http://localhost:${PORT_REST}`);
  console.log(`🌐 WebSocket activo en ws://localhost:${PORT_WS}`);
  console.log(`\n📋 Endpoints disponibles:`);
  console.log(`   POST http://localhost:${PORT_REST}/registro`);
  console.log(`   GET  http://localhost:${PORT_REST}/registros`);
  console.log(`   GET  http://localhost:${PORT_REST}/health`);
  console.log(`\n💡 Para probar:`);
  console.log(`   1. Conecta un cliente WebSocket a ws://localhost:${PORT_WS}`);
  console.log(`   2. Envía POST a http://localhost:${PORT_REST}/registro`);
  console.log(`   3. Verifica que el mensaje llegue en tiempo real al WebSocket\n`);
});

// Manejo de errores del servidor
server.on('error', (error) => {
  console.error('❌ Error del servidor:', error);
});

