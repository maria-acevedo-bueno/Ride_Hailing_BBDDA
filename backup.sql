-- Plan de copias de seguridad y recuperación (Disaster Recovery)
-- Los comandos de backup se ejecutan en la terminal (bash) y no en el cliente SQL, 
-- por eso los dejamos aquí documentados como comentarios.

/*
  ESTRATEGIA ELEGIDA (RPO y RTO)
  
  Como nuestra plataforma guarda información crítica de pagos y viajes, hemos
  establecido los siguientes objetivos para el plan de contingencia:

  - RPO (Recovery Point Objective): 1 hora.
    No queremos perder más de una hora de operativa. Para conseguirlo, vamos a programar 
    un backup completo de madrugada y mantendremos los 'binlogs' activados. Así, 
    si pasa algo durante el día, tiramos del binlog para recuperar hasta el último minuto (PITR).

  - RTO (Recovery Time Objective): 2 horas.
    Si el servidor se cae, al usar Docker tardamos muy poco en levantar otro contenedor. 
    Lo que más tiempo nos llevará será restaurar el archivo .sql y aplicar los binlogs. 
    Estimamos que en menos de 2 horas el sistema puede estar arriba de nuevo.
*/

/*
  1. BACKUP COMPLETO (Para poner en el Cron)
  Este es el comando que usaríamos para hacer la copia de seguridad lógica.
  Le ponemos --single-transaction para no bloquear a los conductores ni a los riders 
  mientras se hace la copia.

  docker exec mysql8_ride_hailing mysqldump \
    -uroot -prootpass \
    --databases ride_hailing \
    --single-transaction \
    --routines --triggers --events \
    --set-gtid-purged=OFF \
    > backup_ridehailing_$(date +%d_%m_%Y).sql
*/

/*
  2. CÓMO RESTAURAR EL BACKUP
  Si hay un desastre, levantamos un contenedor limpio y le pasamos el fichero así:

  cat backup_ridehailing_18_04_2026.sql | docker exec -i mysql8_ride_hailing mysql -uroot -prootpass
*/

/*
  3. RECUPERACIÓN HASTA UN PUNTO EN EL TIEMPO (PITR)
  Imaginemos el caso típico: a las 11:30 alguien hace un DELETE sin WHERE en los pagos.
  Para recuperar la base de datos a como estaba justo a las 11:29, haríamos esto:
*/

-- Primero nos aseguramos desde MySQL de que el log binario está encendido 
SHOW VARIABLES LIKE 'log_bin';
SHOW BINARY LOGS;

/*
  Luego, desde la terminal, sacamos los cambios desde el último backup nocturno 
  hasta un minuto antes de la catástrofe:

  docker exec mysql8_ride_hailing mysqlbinlog \
    --start-datetime="2025-11-20 03:00:00" \
    --stop-datetime="2025-11-20 11:29:59" \
    /var/lib/mysql/binlog.000001 > /tmp/cambios_guardados.sql

  Y por último, aplicamos esos cambios a la base de datos (después de haber 
  restaurado el backup completo del paso 2):

  cat /tmp/cambios_guardados.sql | docker exec -i mysql8_ride_hailing mysql -uroot -prootpass
*/

-- VALIDACIÓN POST-RESTORE
-- Un par de consultas rápidas que lanzaríamos después de restaurar todo para 
-- comprobar visualmente que no nos hemos olvidado de nada.

SELECT 'Usuarios' AS tabla, COUNT(*) AS filas_recuperadas FROM usuario
UNION ALL
SELECT 'Viajes', COUNT(*) FROM viaje
UNION ALL
SELECT 'Pagos', COUNT(*) FROM pago;