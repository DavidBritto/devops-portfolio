#!/bin/bash

LOG="logs_despliegue.txt"

instalar_dependencias() {
  echo "Instalando dependencias..." | tee -a $LOG
  sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx git >> $LOG 2>&1
  sudo systemctl enable nginx >> $LOG 2>&1
  sudo systemctl start nginx >> $LOG 2>&1
}

clonar_app() {
  echo "Clonando la aplicación..." | tee -a $LOG
  git clone -b booklibrary https://github.com/roxsross/devops-static-web.git >> $LOG 2>&1
  cd devops-static-web
}

configurar_entorno() {
  echo "Configurando entorno virtual..." | tee -a ../$LOG
  python3 -m venv venv && source venv/bin/activate
  pip install -r requirements.txt >> ../$LOG 2>&1
  pip install gunicorn >> ../$LOG 2>&1
}

configurar_gunicorn() {
  echo "Iniciando Gunicorn..." | tee -a ../$LOG
  # CORREGIDO: Eliminar el :app extra
  nohup venv/bin/gunicorn -w 4 -b 0.0.0.0:8000 library_site:app >> ../$LOG 2>&1 &
  sleep 3  # Dar tiempo a que Gunicorn inicie
}

configurar_nginx() {
  echo "Configurando Nginx..." | tee -a ../$LOG
  
  # NUEVO: Eliminar configuración por defecto
  sudo rm -f /etc/nginx/sites-enabled/default
  
  # CORREGIDO: Usar 127.0.0.1:8000 en lugar de 0.0.0.0:8000
  sudo tee /etc/nginx/sites-available/booklibrary > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
    
    location /static/ {
        alias $(pwd)/static/;
        expires 30d;
    }
    
    access_log /var/log/nginx/booklibrary_access.log;
    error_log /var/log/nginx/booklibrary_error.log;
}
EOF
  
  sudo ln -sf /etc/nginx/sites-available/booklibrary /etc/nginx/sites-enabled/
  sudo nginx -t >> ../$LOG 2>&1 && sudo systemctl reload nginx
}

verificar_servicios() {
  echo "Verificando servicios..." | tee -a ../$LOG
  
  # Verificar Nginx
  if systemctl is-active --quiet nginx; then
    echo "✓ Nginx está activo" | tee -a ../$LOG
  else
    echo "✗ Nginx no está activo" | tee -a ../$LOG
  fi
  
  # Verificar Gunicorn
  if pgrep -f "gunicorn.*library_site" > /dev/null; then
    echo "✓ Gunicorn está corriendo" | tee -a ../$LOG
  else
    echo "✗ Gunicorn no está corriendo" | tee -a ../$LOG
  fi
  
  # Verificar puerto 8000
  if netstat -tlnp | grep -q ":8000"; then
    echo "✓ Puerto 8000 está en uso" | tee -a ../$LOG
  else
    echo "✗ Puerto 8000 no está en uso" | tee -a ../$LOG
  fi
  
  # Probar conexión directa a Gunicorn
  if curl -s http://127.0.0.1:8000 > /dev/null; then
    echo "✓ Gunicorn responde correctamente" | tee -a ../$LOG
  else
    echo "✗ Gunicorn no responde" | tee -a ../$LOG
  fi
}

main() {
  echo "=== Iniciando despliegue de Book Library ===" | tee $LOG
  instalar_dependencias
  clonar_app
  configurar_entorno
  configurar_gunicorn
  configurar_nginx
  verificar_servicios
  
  echo "=== Despliegue finalizado ===" | tee -a ../$LOG
  echo "Revisá $LOG para detalles." | tee -a ../$LOG
  echo "La aplicación debería estar disponible en: http://$(hostname -I | awk '{print $1}')" | tee -a ../$LOG
}

main