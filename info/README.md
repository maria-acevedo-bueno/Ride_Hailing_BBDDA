# CÓMO OPERAR SOBRE LA BASE DE DATOS

## 1. Manejar la base de datos usando Docker Compose

### 1.1. Comprobar que tenemos todo lo necesario para hacer uso de docker

```bash
docker --version
docker compose version
```

En caso de tener tanto docker como docker compose instalados en el sistema, vamos con el siguiente paso.

### 1.2. Arrancar el servicio

```bash
# Inicializa el contenedor en segundo plano '-d'
docker compose up -d
# Muestra los contenedores en ejecución
docker compose ps
# Muestra logs
docker compose logs -f mysql
```

Una vez iniciado, podemos comprobar si mysql está listo para ser usado 

```bash
docker exec -it mysql8 mysqladmin ping -h 127.0.0.1 -uroot -prootpass
```

Si como salida de este comando vemos `mysqld is alive` estamos preparados para empezar a trabajar con la base de datos.

## 1.3. Conectarse a la base de datos

### Conectarse desde dentro del contenedor

```bash
docker exec -it mysql8 mysql -uroot -prootpass
```

### Conectarse desde tu máquina

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -p
```

## 1.4. Bajar el proyecto

En caso de que queramos bajar el contenedor, tenemos varias opciones

### Bajar el proyecto sin borrar datos

```bash
docker compose down
```

### Borrar TODO (incluye datos)

```bash
docker compose down -v
```

## 2. Tabla entidad-relación

## 3. Roles y permisos

Explicar usuarios y roles, por qué se han creado y las funciones que hacen cada uno de ellos.

## 4. Vistas e Índices

Explicar todas las vistas que se han creado, para qué sirven y quién tiene acceso a ellas.

Explicar los índices que se han creado, por qué se han creado y para qué sirven.

## 5. Procedimientos almacenados y triggers

Qué procedimientos almacenados y triggers tenemos, por qué los hemos creado y para qué sirven.

## 6. Backup

Explicar el RTO decidido, cómo están automatizados los backups y cómo hacemos PITR

## 7. Monitorización

Explicar el sistema de monitorización que hayamos usado.