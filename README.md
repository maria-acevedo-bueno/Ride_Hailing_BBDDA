# Proyecto: Base de Datos para Plataforma Ride-Hailing

Este repositorio contiene la práctica grupal de diseño e implementación de una base de datos relacional para una plataforma de movilidad.

## Decisiones de Diseño e Implementación

Para el desarrollo de esta práctica se han tomado las siguientes decisiones técnicas, buscando el equilibrio entre rendimiento y consistencia de los datos:

* **Arquitectura y Monitorización:** Se ha desplegado MySQL 8 mediante Docker, integrado con Prometheus y Grafana. Esto permite extraer métricas en tiempo real (uso de CPU, conexiones activas, hit ratio del Buffer Pool) y evaluar el rendimiento del motor sin depender de instalaciones locales.
* **Diseño Físico e Integridad:** Se prioriza la integridad referencial utilizando ON DELETE RESTRICT en las claves foráneas. Por este motivo, se descartó el particionado de la tabla de viajes (InnoDB no soporta particionado combinado con claves foráneas) y se compensó mediante la creación de índices compuestos estratégicos para las consultas recurrentes.
* **Concurrencia:** El caso de uso crítico, donde múltiples conductores intentan aceptar la misma oferta simultáneamente, se resuelve a nivel de motor. Se ha implementado un Procedimiento Almacenado que emplea transacciones y bloqueos explícitos (SELECT ... FOR UPDATE) para prevenir condiciones de carrera y la pérdida de actualizaciones.
* **Auditoría Automatizada:** El registro histórico de los cambios de estado de cada viaje se delega a la base de datos mediante un Trigger (AFTER UPDATE), garantizando la trazabilidad sin depender del código de la aplicación.
* **Seguridad (Mínimo Privilegio):** En lugar de otorgar permisos globales, se han definido Roles específicos (rol_app, rol_analista, rol_admin). Además, se han creado Vistas para anonimizar los datos personales de los usuarios frente a los perfiles analíticos.
* **Backup y Recuperación:** Se ha establecido un RPO de 1 hora y un RTO de 2 horas. La estrategia implementada combina backups lógicos regulares con mysqldump y el uso del log binario (binlog) para permitir la recuperación exacta hasta un punto en el tiempo (PITR).

## Requisitos Previos

* Docker y Docker Compose instalados.
* Cliente SQL (DBeaver, MySQL Workbench o terminal).

## Instrucciones de Despliegue

### Paso 1: Levantar la Infraestructura

Abrir una terminal en la raíz del proyecto y ejecutar:

```
docker compose up -d
```

Es necesario esperar aproximadamente 15 segundos para que MySQL inicialice el sistema de archivos. Se puede verificar el estado de los contenedores con:

```
docker compose ps
```

### Paso 2: Cargar el Esquema y los Datos

Para inicializar la base de datos, configurar la seguridad y cargar los datos de prueba, se deben ejecutar los siguientes comandos en orden estricto:

1. Crear estructura, índices y procedimientos:

```
cat schema.sql | docker exec -i mysql8_ride_hailing mysql -uroot -prootpass
```

2. Configurar roles, vistas y permisos:

```
cat permissions.sql | docker exec -i mysql8_ride_hailing mysql -uroot -prootpass
```

3. Insertar los datos de prueba (Mock Data):

```
cat data.sql | docker exec -i mysql8_ride_hailing mysql -uroot -prootpass
```

## Operativa y Pruebas

Una vez desplegado el entorno, se pueden utilizar los siguientes scripts para comprobar el funcionamiento del sistema:

* **queries.sql:** Contiene la operativa diaria de la aplicación. Incluye transacciones, comprobaciones de concurrencia y llamadas a los procedimientos almacenados.
* **dashboard.sql:** Contiene consultas analíticas para Inteligencia de Negocio (tasas de aceptación, ingresos) y consultas de DBA para revisar el rendimiento (EXPLAIN, buffer pool).

Para visualizar el panel de monitorización del servidor:

1. Acceder a `http://localhost:3000` en el navegador.
2. Iniciar sesión con el usuario `admin` y la contraseña `adminpassword`.
3. Importar un dashboard estándar para MySQL Prometheus Exporter (ej. ID 7362).

## Archivos del Repositorio

* `DESIGN.md`: Modelo Entidad-Relación y definición de dominios.
* `schema.sql`: DDL, tablas, índices, triggers y stored procedures.
* `permissions.sql`: DCL, vistas de seguridad, roles y usuarios.
* `data.sql`: DML, carga de datos iniciales.
* `queries.sql`: Casos de uso de la aplicación y control de concurrencia.
* `dashboard.sql`: Consultas analíticas y monitorización de rendimiento.
* `backup.sql`: Plan documentado de Disaster Recovery y ejecución PITR.
* `compose.yml`, `prometheus.yml`, `custom.cnf`: Archivos de configuración de infraestructura.