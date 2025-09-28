const express = require('express');
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Configuración del cliente de WhatsApp
const client = new Client({
    authStrategy: new LocalAuth({
        clientId: "whatsapp-web-server"
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ]
    }
});

// Variables globales
let qrCodeData = null;
let isClientReady = false;
let clientInfo = null;

// Eventos del cliente WhatsApp
client.on('qr', async (qr) => {
    console.log('QR Code recibido');
    qrCodeData = qr;
    
    try {
        const qrCodeImage = await qrcode.toDataURL(qr);
        io.emit('qr', qrCodeImage);
        console.log('QR Code enviado a clientes conectados');
    } catch (err) {
        console.error('Error generando QR Code:', err);
    }
});

client.on('ready', () => {
    console.log('WhatsApp Web está listo!');
    isClientReady = true;
    qrCodeData = null;
    
    client.getState().then(state => {
        clientInfo = {
            state: state,
            timestamp: new Date().toISOString()
        };
        io.emit('ready', clientInfo);
    });
});

client.on('authenticated', () => {
    console.log('Cliente autenticado');
    io.emit('authenticated');
});

client.on('auth_failure', (msg) => {
    console.error('Error de autenticación:', msg);
    io.emit('auth_failure', msg);
});

client.on('disconnected', (reason) => {
    console.log('Cliente desconectado:', reason);
    isClientReady = false;
    clientInfo = null;
    io.emit('disconnected', reason);
});

// Rutas de la API
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Agregar esta ruta
app.get('/status', (req, res) => {
    res.json({
        isReady: isClientReady,
        hasQR: !!qrCodeData,
        clientInfo: clientInfo,
        timestamp: new Date().toISOString()
    });
});

app.get('/api/status', (req, res) => {
    res.json({
        isReady: isClientReady,
        hasQR: !!qrCodeData,
        clientInfo: clientInfo,
        timestamp: new Date().toISOString()
    });
});

app.get('/api/qr', async (req, res) => {
    if (qrCodeData) {
        try {
            const qrCodeImage = await qrcode.toDataURL(qrCodeData);
            res.json({ qr: qrCodeImage });
        } catch (err) {
            res.status(500).json({ error: 'Error generando QR Code' });
        }
    } else {
        res.json({ qr: null, message: 'No hay QR Code disponible' });
    }
});

app.post('/api/send-message', async (req, res) => {
    if (!isClientReady) {
        return res.status(400).json({ error: 'WhatsApp no está listo' });
    }

    const { number, message } = req.body;
    
    if (!number || !message) {
        return res.status(400).json({ error: 'Número y mensaje son requeridos' });
    }

    try {
        const chatId = number.includes('@c.us') ? number : `${number}@c.us`;
        const result = await client.sendMessage(chatId, message);
        res.json({ success: true, messageId: result.id._serialized });
    } catch (err) {
        console.error('Error enviando mensaje:', err);
        res.status(500).json({ error: 'Error enviando mensaje' });
    }
});

// WebSocket para tiempo real
io.on('connection', (socket) => {
    console.log('Cliente conectado:', socket.id);
    
    // Enviar estado actual al cliente
    socket.emit('status', {
        isReady: isClientReady,
        hasQR: !!qrCodeData,
        clientInfo: clientInfo
    });
    
    // Si hay QR disponible, enviarlo
    if (qrCodeData) {
        qrcode.toDataURL(qrCodeData).then(qrCodeImage => {
            socket.emit('qr', qrCodeImage);
        });
    }
    
    socket.on('disconnect', () => {
        console.log('Cliente desconectado:', socket.id);
    });
});

// Función para iniciar el servidor
async function startServer() {
    try {
        console.log('Iniciando servidor WhatsApp Web...');
        
        // Inicializar cliente WhatsApp
        await client.initialize();
        
        // Iniciar servidor HTTP
        server.listen(PORT, '0.0.0.0', () => {
            console.log(`Servidor ejecutándose en http://0.0.0.0:${PORT}`);
            console.log('Esperando conexión de WhatsApp...');
        });
        
    } catch (error) {
        console.error('Error iniciando servidor:', error);
        process.exit(1);
    }
}

// Manejo de señales para cierre graceful
process.on('SIGINT', async () => {
    console.log('Cerrando servidor...');
    await client.destroy();
    server.close(() => {
        console.log('Servidor cerrado');
        process.exit(0);
    });
});

process.on('SIGTERM', async () => {
    console.log('Cerrando servidor...');
    await client.destroy();
    server.close(() => {
        console.log('Servidor cerrado');
        process.exit(0);
    });
});

// Iniciar servidor
startServer();
