-- BACKUP.SQL
-- Plan de backup y recuperación de ride_hailing

USE ride_hailing;

-- =========================================================
-- 1. OBJETIVO DEL PLAN
-- =========================================================
-- Backup: copia de seguridad de datos y configuración.
-- Restore: recuperar datos desde un backup.
-- RPO: pérdida máxima de datos aceptable.
-- RTO: tiempo máximo para recuperar el servicio.
-- PITR: recuperación a un punto concreto en el tiempo usando backup + binlog.

-- Criterio para la práctica:
-- RPO: 24 horas con backup diario.
-- RTO: restauración manual en entorno Docker.
-- Método principal: backup lógico con mysqldump.
-- Mejora posible: PITR si el binlog está activo.


-- =========================================================
-- 2. BACKUP LÓGICO DE ride_hailing
-- =========================================================
-- Ejecutar en terminal, no dentro de MySQL.
-- Incluye base de datos, procedimientos, triggers y eventos.

-- docker exec mysql8 mysqldump \
--   -uroot -prootpass \
--   --databases ride_hailing \
--   --single-transaction \
--   --routines --triggers --events \
--   --set-gtid-purged=OFF \
--   > backup_ride_hailing_$(date +%Y%m%d).sql


-- =========================================================
-- 3. BACKUP COMPLETO DEL SERVIDOR
-- =========================================================
-- Incluye también la base mysql, donde están usuarios y privilegios.
-- Ejecutar en terminal.

-- docker exec mysql8 mysqldump \
--   -uroot -prootpass \
--   --all-databases \
--   --single-transaction \
--   --routines --triggers --events \
--   --set-gtid-purged=OFF \
--   > backup_full_$(date +%Y%m%d).sql


-- =========================================================
-- 4. BACKUP DE TABLAS CONCRETAS
-- =========================================================
-- Útil para exportar solo tablas principales.
-- Ejecutar en terminal.

-- docker exec mysql8 mysqldump \
--   -uroot -prootpass \
--   --single-transaction \
--   ride_hailing usuario rider conductor company vehiculo viaje oferta pago valoracion viaje_estado_log \
--   > backup_tablas_ride_hailing_$(date +%Y%m%d).sql


-- =========================================================
-- 5. RESTAURAR UN BACKUP
-- =========================================================
-- Ejecutar en terminal.

-- Opción con cat:
-- cat backup_ride_hailing.sql | docker exec -i mysql8 mysql -uroot -prootpass

-- Opción con redirección:
-- docker exec -i mysql8 mysql -uroot -prootpass < backup_ride_hailing.sql


-- =========================================================
-- 6. COMPROBACIONES DESPUÉS DEL RESTORE
-- =========================================================

-- Comprobar que la base existe.
SHOW DATABASES;

-- Entrar en la base restaurada.
USE ride_hailing;

-- Comprobar tablas.
SHOW TABLES;

-- Conteos básicos.
SELECT 'company' AS tabla, COUNT(*) AS filas FROM company
UNION ALL
SELECT 'usuario', COUNT(*) FROM usuario
UNION ALL
SELECT 'rider', COUNT(*) FROM rider
UNION ALL
SELECT 'conductor', COUNT(*) FROM conductor
UNION ALL
SELECT 'vehiculo', COUNT(*) FROM vehiculo
UNION ALL
SELECT 'conductor_vehiculo', COUNT(*) FROM conductor_vehiculo
UNION ALL
SELECT 'viaje', COUNT(*) FROM viaje
UNION ALL
SELECT 'oferta', COUNT(*) FROM oferta
UNION ALL
SELECT 'pago', COUNT(*) FROM pago
UNION ALL
SELECT 'valoracion', COUNT(*) FROM valoracion
UNION ALL
SELECT 'viaje_estado_log', COUNT(*) FROM viaje_estado_log;

-- Comprobar claves foráneas declaradas.
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'ride_hailing'
  AND REFERENCED_TABLE_NAME IS NOT NULL;


-- =========================================================
-- 7. COMPROBAR SI SE PUEDE HACER PITR
-- =========================================================
-- PITR = restaurar un backup y aplicar binlogs hasta un momento concreto.

SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
SHOW BINARY LOGS;


-- =========================================================
-- 8. EJEMPLO DE PITR
-- =========================================================
-- Caso: se quiere recuperar hasta antes de un DELETE accidental.
-- Ajustar fechas y nombre de binlog al caso real.
-- Ejecutar en terminal.

-- 1) Restaurar el backup completo:
-- cat backup_ride_hailing_10_00.sql | docker exec -i mysql8 mysql -uroot -prootpass

-- 2) Extraer cambios hasta antes del error:
-- docker exec mysql8 mysqlbinlog \
--   --start-datetime="2026-04-25 10:00:00" \
--   --stop-datetime="2026-04-25 10:29:59" \
--   /var/lib/mysql/binlog.000001 > cambios.sql

-- 3) Aplicar cambios:
-- cat cambios.sql | docker exec -i mysql8 mysql -uroot -prootpass


-- =========================================================
-- 9. BUSCAR UNA OPERACIÓN EN EL BINLOG
-- =========================================================
-- Ejemplo para localizar un DELETE.
-- Ejecutar en terminal.

-- docker exec mysql8 mysqlbinlog \
--   --start-datetime="2026-04-25 10:25:00" \
--   --stop-datetime="2026-04-25 10:35:00" \
--   /var/lib/mysql/binlog.000001 | grep -A5 -B5 "DELETE"

-- También se puede recuperar por posiciones:

-- docker exec mysql8 mysqlbinlog \
--   --start-position=154 \
--   --stop-position=12345 \
--   /var/lib/mysql/binlog.000001 > cambios.sql


-- =========================================================
-- 10. SNAPSHOT CONSISTENTE
-- =========================================================
-- Los snapshots pueden ser inconsistentes si MySQL está escribiendo.
-- Para coordinarlo, se puede bloquear brevemente la lectura de tablas.

-- Ejecutar en MySQL antes del snapshot:
-- FLUSH TABLES WITH READ LOCK;

-- Tomar el snapshot desde la infraestructura correspondiente.

-- Liberar después:
-- UNLOCK TABLES;


-- =========================================================
-- 11. SCRIPT DE BACKUP CON ROTACIÓN
-- =========================================================
-- Guardar como backup_mysql.sh.
-- Ejecutar desde el sistema, no desde MySQL.

-- #!/bin/bash
-- FECHA=$(date +%Y%m%d_%H%M%S)
-- BACKUP_DIR="/backups/mysql"
-- RETENTION_DAYS=7
--
-- docker exec mysql8 mysqldump \
--   -uroot -prootpass \
--   --all-databases \
--   --single-transaction \
--   --routines --triggers --events \
--   --set-gtid-purged=OFF \
--   | gzip > "${BACKUP_DIR}/backup_${FECHA}.sql.gz"
--
-- if [ $? -eq 0 ]; then
--   echo "Backup creado: backup_${FECHA}.sql.gz"
-- else
--   echo "ERROR: Backup falló" >&2
--   exit 1
-- fi
--
-- find ${BACKUP_DIR} -name "backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
-- echo "Backups con más de ${RETENTION_DAYS} días eliminados"

-- Programar backup diario a las 3:00:
-- crontab -e
-- 0 3 * * * /scripts/backup_mysql.sh >> /var/log/mysql_backup.log 2>&1
