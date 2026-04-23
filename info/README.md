# Cabify - MySQL 8 con Docker

# T1 - Docker

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
docker compose stop mysql
docker compose start mysql
docker compose restart mysql
```

## 1.6. Persistencia

La información de la base de datos se almacenará en /var/lib/mysql como volumen de docker

## 1.7. Variables de entorno

Las credenciales se leerán de el archivo .env para aumentar la seguridad

```yaml
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE: ${MYSQL_DATABASE}
MYSQL_USER: ${MYSQL_USER}
MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

# T2 - Esquema SQL

## 2.1. Cargar el esquema

Ejecutar el archivo `schema.sql` dentro del contenedor MySQL:

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/schema.sql
```

## 2.2. Comprobaciones

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

```SQL
DROP DATABASE IF EXISTS cabify;
CREATE DATABASE cabify;
USE cabify;
```

```bash
docker exec -i cabify_mysql8 mysql -uroot -prootpass < sql/schema.sql
```