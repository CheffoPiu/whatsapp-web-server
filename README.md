# WhatsApp Web Server para EC2

Un servidor de WhatsApp Web que se ejecuta automáticamente en EC2 con despliegue continuo usando GitHub Actions.

## 🚀 Características

- ✅ **Auto-ejecución**: Se inicia automáticamente al arrancar la instancia EC2
- ✅ **Despliegue automático**: Se actualiza automáticamente con cada push a GitHub
- ✅ **Interfaz web**: Panel de control para escanear QR y ver estado
- ✅ **API REST**: Endpoints para enviar mensajes programáticamente
- ✅ **WebSocket**: Actualizaciones en tiempo real
- ✅ **Monitoreo**: Health checks automáticos y logs
- ✅ **Reinicio automático**: Se reinicia si falla

## 📋 Requisitos Previos

1. **Instancia EC2** con Ubuntu 20.04+ o Amazon Linux 2
2. **Clave SSH** para acceder a EC2
3. **Repositorio GitHub** (este código)
4. **Puerto 3000** abierto en el Security Group de EC2

## 🛠️ Instalación

### 1. Configurar EC2

Conecta a tu instancia EC2 y ejecuta:

```bash
# Descargar y ejecutar el script de configuración
wget https://raw.githubusercontent.com/TU_USUARIO/whatsapp-web-server/main/setup-ec2.sh
chmod +x setup-ec2.sh
sudo bash setup-ec2.sh
```

### 2. Configurar GitHub Secrets

En tu repositorio GitHub, ve a **Settings > Secrets and variables > Actions** y agrega:

- `EC2_HOST`: IP pública de tu instancia EC2
- `EC2_USERNAME`: `ubuntu` (o tu usuario)
- `EC2_SSH_KEY`: Contenido de tu clave privada SSH
- `EC2_PORT`: `22` (puerto SSH)

### 3. Desplegar

Haz push a la rama `main`:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

El GitHub Action se ejecutará automáticamente y desplegará tu aplicación.

## 🌐 Uso

### Interfaz Web

Visita: `http://TU_IP_EC2:3000`

- Escanea el código QR con WhatsApp
- Ve el estado de la conexión
- Monitorea los logs en tiempo real

### API REST

#### Obtener estado
```bash
curl http://TU_IP_EC2:3000/api/status
```

#### Obtener QR Code
```bash
curl http://TU_IP_EC2:3000/api/qr
```

#### Enviar mensaje
```bash
curl -X POST http://TU_IP_EC2:3000/api/send-message \
  -H "Content-Type: application/json" \
  -d '{
    "number": "1234567890",
    "message": "Hola desde WhatsApp Web Server!"
  }'
```

### WebSocket

Conecta a `ws://TU_IP_EC2:3000` para recibir actualizaciones en tiempo real:

- `qr`: Nuevo código QR
- `ready`: WhatsApp conectado
- `authenticated`: Autenticación exitosa
- `disconnected`: Desconectado

## 🔧 Gestión del Servicio

### Comandos básicos

```bash
# Ver estado
sudo /opt/whatsapp-web-server/manage.sh status

# Ver logs en tiempo real
sudo /opt/whatsapp-web-server/manage.sh logs

# Reiniciar servicio
sudo /opt/whatsapp-web-server/manage.sh restart

# Health check
sudo /opt/whatsapp-web-server/manage.sh health
```

### Comandos systemd

```bash
# Iniciar
sudo systemctl start whatsapp-web-server

# Detener
sudo systemctl stop whatsapp-web-server

# Reiniciar
sudo systemctl restart whatsapp-web-server

# Ver estado
sudo systemctl status whatsapp-web-server

# Ver logs
sudo journalctl -u whatsapp-web-server -f
```

## 📊 Monitoreo

### Health Check Automático

El sistema ejecuta un health check cada 5 minutos y reinicia el servicio si no responde.

### Logs

Los logs se guardan en:
- **Systemd**: `sudo journalctl -u whatsapp-web-server`
- **Archivo**: `/var/log/whatsapp-web-server/`
- **Health Check**: `/var/log/whatsapp-web-server/health-check.log`

### Rotación de Logs

Los logs se rotan automáticamente cada día, manteniendo 7 días de historial.

## 🔒 Seguridad

- El servicio se ejecuta con usuario `ubuntu` (no root)
- Puerto 3000 abierto solo para HTTP
- Logs con permisos restringidos
- Health checks internos

## 🚨 Troubleshooting

### El servicio no inicia

```bash
# Ver logs detallados
sudo journalctl -u whatsapp-web-server -n 50

# Verificar dependencias
node --version
npm --version

# Verificar puerto
sudo netstat -tlnp | grep 3000
```

### WhatsApp no se conecta

1. Verifica que el QR se genere correctamente
2. Asegúrate de escanear con el mismo número de teléfono
3. Revisa los logs para errores de Puppeteer

### Problemas de memoria

```bash
# Ver uso de memoria
free -h
ps aux --sort=-%mem | head

# Reiniciar si es necesario
sudo systemctl restart whatsapp-web-server
```

## 📝 Estructura del Proyecto

```
whatsapp-web-server/
├── .github/workflows/
│   └── deploy.yml              # GitHub Action para despliegue
├── public/
│   └── index.html              # Interfaz web
├── package.json                # Dependencias Node.js
├── server.js                   # Servidor principal
├── ecosystem.config.js         # Configuración PM2
├── whatsapp-web-server.service # Servicio systemd
├── setup-ec2.sh               # Script de configuración EC2
└── README.md                  # Este archivo
```

## 🔄 Actualizaciones

Para actualizar la aplicación:

1. Haz cambios en tu código
2. Haz commit y push a `main`
3. GitHub Actions desplegará automáticamente
4. El servicio se reiniciará con la nueva versión

## 📞 Soporte

Si tienes problemas:

1. Revisa los logs: `sudo /opt/whatsapp-web-server/manage.sh logs`
2. Verifica el estado: `sudo /opt/whatsapp-web-server/manage.sh status`
3. Ejecuta health check: `sudo /opt/whatsapp-web-server/manage.sh health`

## 📄 Licencia

MIT License - ver archivo LICENSE para más detalles.
