# Cabify - MySQL 8 con Docker

# 1 - Docker

## 1.1. Requisitos

Requisitos:

- Docker
- Docker Compose

Comprobación de que estos están instalados:

```bash
docker --version
docker compose version
```

## 1.2. Inicio de la base de datos

```bash
docker compose up -d
docker compose ps
docker compose logs -f mysql
```

Comprobar que todo esté listo:

```bash
docker exec -it cabify_mysql8 mysqladmin ping -h 127.0.0.1 -uroot -prootpass
```

## 1.3. Conectarse a la base de datos

```bash
# Desde el contenedor
docker exec -it cabify_mysql8 mysql -uroot -prootpass

# Desde el host (rootpass como contraseña)
mysql -h 127.0.0.1 -P 3306 -uroot -p
```

Comandos de comprobación:

```SQL
SELECT VERSION();
SHOW DATABASES;
USE cabify;
SHOW TABLES;
```

## 1.4. Parar docker

```bash
docker compose down
# Pararlo y borrar el volumen
docker compose down -v
```

## 1.5. Otros comandos interesantes

```bash
# Para el contenedor 
docker compose stop mysql
# Inicia de nuevo el contenedor parado
docker compose start mysql
# Reinicia el contenedor
docker compose restart mysql
```

## 1.6. Persistencia

La información de la base de datos se almacena en `/var/lib/mysql` usando un volumen de Docker.
Los datos persisten mientras no se elimine el volumen con `docker compose down -v`.

## 1.7. Variables de entorno

Las credenciales se leerán del archivo `.env` para evitar escribirlas directamente en el `compose.yml`.

```yaml
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE: ${MYSQL_DATABASE}
MYSQL_USER: ${MYSQL_USER}
MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

# 2 - Schema

## 2.1. Cargar el esquema de la base de datos

Ejecutar el archivo `schema.sql` dentro del contenedor MySQL:

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/schema.sql
```

## 2.2. Comprobaciones del esquema de la base de datos

Ver las bases de datos disponibles

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW DATABASES;"
```

Ver las tablas dentro de la base de datos

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SHOW TABLES;"
```

Comprobar las definiciones de las tablas

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.company\G"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.conductor\G"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.vehiculo\G"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.viaje\G"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.oferta\G"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW CREATE TABLE cabify.auditoria\G"
```

Revisar los índices creados

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW INDEX FROM cabify.conductor;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW INDEX FROM cabify.vehiculo;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW INDEX FROM cabify.viaje;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW INDEX FROM cabify.oferta;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW INDEX FROM cabify.auditoria;"
```

Revisar las claves foráneas

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'cabify'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
"
```

## 2.3. Ejecutar el esquema en caso de cambios

Este comando elimina y recrea la base de datos `cabify`, por lo que borra los datos existentes.

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/schema.sql
```

# 3 - Data

## 3.1. Cargar los datos en la base de datos

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/data.sql
```

## 3.2. Comprobaciones

Ver el número de elementos por tabla:

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM company;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM rider;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM conductor;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM vehiculo;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM viaje;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM oferta;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT COUNT(*) AS total FROM auditoria;"

docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT id_viaje, id_rider, id_conductor, estado FROM viaje ORDER BY id_viaje;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "USE cabify; SELECT id_oferta, id_viaje, id_conductor, estado_oferta FROM oferta ORDER BY id_viaje, id_conductor;"
```

# 4 - Queries

## 4.1. Probar las queries básicas

Ejecutar el archivo queries.sql dentro del contenedor (Cuidado, se ejecutan queries que modifican datos, se recomienda probarlas de 1 en 1)

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/queries.sql
```

En caso de haberlo ejecutado, se puede reiniciar la base de datos con los siguientes comandos

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/schema.sql
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/data.sql
```

# 5 - Administración de la base de datos

## 5.1. cnf

En caso de modificar `mysql/conf.d/custom.cnf`, hay que reiniciar el contenedor.

```bash
docker compose restart mysql
```

Comprobación de ajustes de cnf

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'sql_mode';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'slow_query_log';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'long_query_time';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'max_connections';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'performance_schema';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'log_bin';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'sync_binlog';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';"
```

## 5.2. Revisar estado del servidor

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW STATUS;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW STATUS LIKE 'Uptime';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW STATUS LIKE 'Threads_connected';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW STATUS LIKE 'Connections';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'max_connections';"
```

## 5.3. Revisar procesos 

```bash 
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW PROCESSLIST;"
```

## 5.4. Revisar performance_schema

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SELECT * FROM performance_schema.threads LIMIT 10;"
```

## 5.5. Revisar slow log y binlog

```bash
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'log_bin';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'slow_query_log%';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'long_query_time';"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW BINARY LOGS;"
docker exec -it cabify_mysql8 mysql -uroot -prootpass -e "SHOW MASTER STATUS;"
```