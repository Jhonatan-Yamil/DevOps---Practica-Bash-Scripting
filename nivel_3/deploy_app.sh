#!/bin/bash
#.Env
ENV_PATH="/home/jhonatan/devops/practicaI/DevOps---Practica-Bash-Scripting/.env"

if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' "$ENV_PATH" | xargs)
else
    echo " No se encontró archivo .env en $ENV_PATH"
    exit 1
fi
REPO_URL="https://github.com/rayner-villalba-coderoad-com/clash-of-clan"
DEPLOY_DIR="./clash-of-clan"
LOG_FILE="./deploy.log"
SERVICE="apache2"
WEBHOOK_URL="$DISCORD_WEBHOOK"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] === Iniciando despliegue ===" | tee -a "$LOG_FILE"

# Clona y actualiza repo
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "[$DATE] Clonando repositorio..." | tee -a "$LOG_FILE"
    git clone "$REPO_URL" "$DEPLOY_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo "[$DATE] Error al clonar repositorio" | tee -a "$LOG_FILE"
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \" Error al clonar el repositorio en $(hostname) a las $DATE\"}" \
             "$WEBHOOK_URL"
        exit 1
    fi
else
    echo "[$DATE] Actualizando repositorio..." | tee -a "$LOG_FILE"
    cd "$DEPLOY_DIR" || exit 1
    git pull origin main >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo "[$DATE] Error al hacer git pull" | tee -a "$LOG_FILE"
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"Error en git pull en $(hostname) a las $DATE\"}" \
             "$WEBHOOK_URL"
        exit 1
    fi
fi

# Apache2 reinicio
echo "[$DATE] Reiniciando Apache2..." | tee -a "$LOG_FILE"
systemctl restart apache2
if [ $? -eq 0 ]; then
    echo "[$DATE]  Apache2 reiniciado correctamente" | tee -a "$LOG_FILE"
else
    echo "[$DATE]  Error al reiniciar Apache2" | tee -a "$LOG_FILE"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \" Error al reiniciar Apache2 en $(hostname) a las $DATE\"}" \
         "$WEBHOOK_URL"
    exit 1
fi

# Notificacion final
MESSAGE=" Despliegue completado exitosamente en $(hostname) a las $DATE"
curl -H "Content-Type: application/json" \
     -X POST \
     -d "{\"content\": \"$MESSAGE\"}" \
     "$WEBHOOK_URL"

echo "[$DATE] Despliegue completado exitosamente." | tee -a "$LOG_FILE"
exit 0
