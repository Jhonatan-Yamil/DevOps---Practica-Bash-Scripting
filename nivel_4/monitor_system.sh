#!/bin/bash

ENV_PATH="/home/jhonatan/devops/practicaI/DevOps---Practica-Bash-Scripting/.env"

if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' "$ENV_PATH" | xargs)
else
    echo "No se encontró archivo .env en $ENV_PATH"
    exit 1
fi

CPU_LIMIT=80
RAM_LIMIT=80
DISK_LIMIT=80

# Colores 
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

DATE=$(date '+%Y%m%d')
ALERT_LOG="./alerts.log"
METRICS_LOG="./metrics_${DATE}.log"

# Variables
WEBHOOK_URL="$DISCORD_WEBHOOK"
EMAIL="$ALERT_EMAIL"

# Metricas
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_USAGE=$(( RAM_USED * 100 / RAM_TOTAL ))
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

# Historico
echo "=== Métricas de $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$METRICS_LOG"
echo "CPU: ${CPU_USAGE}%  RAM: ${RAM_USAGE}%  Disco: ${DISK_USAGE}%" >> "$METRICS_LOG"

# Alertas
ALERT=0

if [ "$CPU_USAGE" -ge "$CPU_LIMIT" ]; then
    echo -e "${RED}ALERTA: CPU alta (${CPU_USAGE}%)${NC}" | tee -a "$ALERT_LOG"
    ALERT=1
else
    echo -e "${GREEN}CPU OK (${CPU_USAGE}%)${NC}"
fi

if [ "$RAM_USAGE" -ge "$RAM_LIMIT" ]; then
    echo -e "${RED}ALERTA: RAM alta (${RAM_USAGE}%)${NC}" | tee -a "$ALERT_LOG"
    ALERT=1
else
    echo -e "${GREEN}RAM OK (${RAM_USAGE}%)${NC}"
fi

if [ "$DISK_USAGE" -ge "$DISK_LIMIT" ]; then
    echo -e "${RED}ALERTA: Disco lleno (${DISK_USAGE}%)${NC}" | tee -a "$ALERT_LOG"
    ALERT=1
else
    echo -e "${GREEN}Disco OK (${DISK_USAGE}%)${NC}"
fi

if [ "$ALERT" -eq 1 ]; then
    MESSAGE=" Alerta sistema: CPU ${CPU_USAGE}%, RAM ${RAM_USAGE}%, Disco ${DISK_USAGE}%"
    
    # Correo
    echo "$MESSAGE" | mail -s "Alerta Sistema $(hostname)" "$EMAIL"
    
    # Discord
    if [ -n "$WEBHOOK_URL" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$MESSAGE\"}" \
             "$WEBHOOK_URL"
    fi
fi

echo -e "${GREEN}Monitoreo completado.${NC}"
exit 0

