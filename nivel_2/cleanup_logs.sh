#!/bin/bash
# Jhonatan Cabezas

set -o errexit
set -o pipefail
set -o nounset

# Se sobreescribe con parametros
LOG_DIR="${1:-/var/log}"
BACKUP_DIR="${2:-/backup/logs}"
DATE_NOW=$(date '+%Y-%m-%d_%H%M%S')
ARCHIVE_NAME="logs_${DATE_NOW}.tar.gz"

DEFAULT_SYSLOG="/var/log/cleanup_logs.log"
if [ -w "$(dirname "$DEFAULT_SYSLOG")" ] || [ ! -e "$DEFAULT_SYSLOG" -a -w "$(dirname "$DEFAULT_SYSLOG")" ]; then
    LOGFILE="$DEFAULT_SYSLOG"
else
    LOGFILE="$HOME/cleanup_logs.log"
fi

log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOGFILE"
}

log "INICIO - Limpieza de logs: buscando archivos en '$LOG_DIR' con más de 7 días."

# Directorio de logs
if [ ! -d "$LOG_DIR" ]; then
    log "ERROR - Directorio de logs no existe: $LOG_DIR"
    exit 2
fi

# Directorio de backup si no existe
if [ ! -d "$BACKUP_DIR" ]; then
    log "INFO - Directorio de backup '$BACKUP_DIR' no existe. Creando..."
    mkdir -p "$BACKUP_DIR" || { log "ERROR - No se pudo crear $BACKUP_DIR"; exit 3; }
    log "INFO - Directorio de backup creado: $BACKUP_DIR"
fi

ARCHIVE_PATH="${BACKUP_DIR%/}/$ARCHIVE_NAME"

# Busca archivos > 7 días y empaquetarlos
mapfile -d '' -t old_files < <(find "$LOG_DIR" -type f -mtime +7 -print0)

if [ "${#old_files[@]}" -eq 0 ]; then
    log "INFO - No se encontraron archivos con más de 7 días en $LOG_DIR. Nada que hacer."
    exit 0
fi

log "INFO - Se encontraron ${#old_files[@]} archivos antiguos. Preparando compresión en: $ARCHIVE_PATH"

# tar.gz leyendo la lista NUL desde find
if find "$LOG_DIR" -type f -mtime +7 -print0 | tar --null --files-from=- -czf "$ARCHIVE_PATH"; then
    log "OK - Compresión exitosa: $ARCHIVE_PATH"

    if [ ! -s "$ARCHIVE_PATH" ]; then
        log "ERROR - Archivo de backup creado pero vacío o no accesible: $ARCHIVE_PATH"
        exit 4
    fi

    log "INFO - Eliminando archivos originales..."
    find "$LOG_DIR" -type f -mtime +7 -print0 | xargs -0 -r -I{} bash -c 'echo "BORRAR: {}"' | tee -a "$LOGFILE"
    find "$LOG_DIR" -type f -mtime +7 -print0 | xargs -0 -r rm -f --
    log "OK - Archivos originales eliminados."

    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    log "INFO - Backup guardado en $ARCHIVE_PATH (tamaño: $ARCHIVE_SIZE)"
else
    log "ERROR - Falló la compresión. No se eliminaron archivos."
    [ -f "$ARCHIVE_PATH" ] && { log "INFO - Eliminando archivo de backup parcial: $ARCHIVE_PATH"; rm -f "$ARCHIVE_PATH"; }
    exit 5
fi

log "FIN - Proceso finalizado correctamente."
exit 0

# Para cron se uso:
# 0 2 * * * /home/jhonatan/devops/practicaI/DevOps---Practica-Bash-Scripting/nivel_2/cleanup_logs.sh /var/log /backup/logs >> /var/log/cleanup_logs.log 2>&1
