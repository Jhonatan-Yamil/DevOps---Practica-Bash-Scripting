#!/bin/bash
# Estudiantes:
# - Jhonatan Cabezas
# - Valeria Martinez

# Valida parametro 
if [ -z "$1" ]; then
    echo " Error: Debes especificar el nombre del servicio."
    echo "Uso: $0 nombre_servicio"
    exit 1
fi

SERVICE="$1"
LOG_FILE="service_status.log" 
EMAIL="jhonatanyamilcabezas@gmail.com"    
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)

# Verifica estado del servicio
if systemctl is-active --quiet "$SERVICE"; then
    STATUS="ACTIVE"
    MESSAGE="$DATE - $HOST - $SERVICE está ACTIVO "
else
    STATUS="INACTIVE"
    MESSAGE="$DATE - $HOST - $SERVICE está INACTIVO"
    echo "$MESSAGE" | mail -s "[$HOST] ALERTA: $SERVICE no está activo" "$EMAIL"
fi
echo "$MESSAGE" >> "$LOG_FILE"
echo "$MESSAGE"
