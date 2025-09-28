#!/bin/bash

# Script para configurar EC2 para WhatsApp Web Server
# Ejecutar como: sudo bash setup-ec2.sh

set -e

echo "🚀 Configurando EC2 para WhatsApp Web Server..."

# Actualizar sistema
echo "📦 Actualizando sistema..."
apt update && apt upgrade -y

# Instalar Node.js 18
echo "📦 Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Instalar PM2 globalmente
echo "📦 Instalando PM2..."
npm install -g pm2

# Instalar dependencias del sistema para Puppeteer
echo "📦 Instalando dependencias del sistema..."
apt-get install -y \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils

# Crear directorio de la aplicación
echo "📁 Creando directorios..."
mkdir -p /opt/whatsapp-web-server
mkdir -p /var/log/whatsapp-web-server
chown -R ubuntu:ubuntu /opt/whatsapp-web-server
chown -R ubuntu:ubuntu /var/log/whatsapp-web-server

# Configurar firewall
echo "🔥 Configurando firewall..."
ufw allow 22/tcp
ufw allow 3000/tcp
ufw --force enable

# Configurar PM2 para auto-inicio
echo "⚙️ Configurando PM2..."
sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo -u ubuntu pm2 save

# Crear archivo de configuración de entorno
echo "📝 Creando archivo de configuración..."
cat > /opt/whatsapp-web-server/.env << EOF
NODE_ENV=production
PORT=3000
EOF

chown ubuntu:ubuntu /opt/whatsapp-web-server/.env

# Configurar logrotate para los logs
echo "📝 Configurando logrotate..."
cat > /etc/logrotate.d/whatsapp-web-server << EOF
/var/log/whatsapp-web-server/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload whatsapp-web-server > /dev/null 2>&1 || true
    endscript
}
EOF

# Configurar monitoreo básico
echo "📊 Configurando monitoreo..."
cat > /opt/whatsapp-web-server/health-check.sh << 'EOF'
#!/bin/bash
# Health check script para WhatsApp Web Server

SERVICE_URL="http://localhost:3000/api/status"
LOG_FILE="/var/log/whatsapp-web-server/health-check.log"

check_service() {
    if curl -f -s "$SERVICE_URL" > /dev/null 2>&1; then
        echo "$(date): ✅ Servicio funcionando correctamente" >> "$LOG_FILE"
        return 0
    else
        echo "$(date): ❌ Servicio no responde" >> "$LOG_FILE"
        return 1
    fi
}

if ! check_service; then
    echo "$(date): Reiniciando servicio..." >> "$LOG_FILE"
    systemctl restart whatsapp-web-server
    sleep 10
    check_service
fi
EOF

chmod +x /opt/whatsapp-web-server/health-check.sh
chown ubuntu:ubuntu /opt/whatsapp-web-server/health-check.sh

# Configurar cron para health check cada 5 minutos
echo "⏰ Configurando health check automático..."
(crontab -u ubuntu -l 2>/dev/null; echo "*/5 * * * * /opt/whatsapp-web-server/health-check.sh") | crontab -u ubuntu -

# Crear script de gestión
echo "📝 Creando script de gestión..."
cat > /opt/whatsapp-web-server/manage.sh << 'EOF'
#!/bin/bash
# Script de gestión para WhatsApp Web Server

case "$1" in
    start)
        echo "Iniciando WhatsApp Web Server..."
        systemctl start whatsapp-web-server
        ;;
    stop)
        echo "Deteniendo WhatsApp Web Server..."
        systemctl stop whatsapp-web-server
        ;;
    restart)
        echo "Reiniciando WhatsApp Web Server..."
        systemctl restart whatsapp-web-server
        ;;
    status)
        systemctl status whatsapp-web-server --no-pager
        ;;
    logs)
        journalctl -u whatsapp-web-server -f
        ;;
    health)
        curl -s http://localhost:3000/api/status | jq .
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|health}"
        exit 1
        ;;
esac
EOF

chmod +x /opt/whatsapp-web-server/manage.sh
chown ubuntu:ubuntu /opt/whatsapp-web-server/manage.sh

echo "✅ Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Sube tu código a GitHub"
echo "2. Configura los secrets en GitHub:"
echo "   - EC2_HOST: IP de tu instancia EC2"
echo "   - EC2_USERNAME: ubuntu (o tu usuario)"
echo "   - EC2_SSH_KEY: Tu clave privada SSH"
echo "   - EC2_PORT: 22 (puerto SSH)"
echo "3. Haz push a la rama main para desplegar automáticamente"
echo ""
echo "🔧 Comandos útiles:"
echo "sudo /opt/whatsapp-web-server/manage.sh status  # Ver estado"
echo "sudo /opt/whatsapp-web-server/manage.sh logs    # Ver logs"
echo "sudo /opt/whatsapp-web-server/manage.sh health  # Health check"
echo ""
echo "🌐 Tu aplicación estará disponible en: http://TU_IP_EC2:3000"
