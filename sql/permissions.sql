-- CONFIGURACION DE SEGURIDAD Y PRIVILEGIOS
USE ride_hailing;

-- 1. VISTAS DE SEGURIDAD Y OPERACION

-- Vista para analítica sin exponer email ni teléfono
CREATE OR REPLACE VIEW v_usuarios_anonimizados AS
SELECT
    id_usuario,
    nombre,
    apellido1,
    apellido2,
    fecha_alta,
    activo
FROM usuario;

-- Vista de pagos para analistas
CREATE OR REPLACE VIEW v_pagos_analitica AS
SELECT
    id_pago,
    id_viaje,
    importe_total,
    comision_company,
    importe_conductor,
    metodo_pago,
    estado_pago,
    fecha_pago
FROM pago;

-- Vista del historial de estados de viaje
CREATE OR REPLACE VIEW v_viaje_estado_log_resumen AS
SELECT
    id_historial,
    id_viaje,
    estado_anterior,
    estado_nuevo,
    fecha_cambio,
    comentario
FROM viaje_estado_log;

-- Vista de auditoría para analistas y usuarios de solo lectura.
-- Permite revisar operaciones críticas sin dar acceso directo a la tabla audit_operacion.
CREATE OR REPLACE VIEW v_auditoria_operaciones AS
SELECT
    id_audit,
    tabla_afectada,
    id_registro,
    accion,
    usuario_mysql,
    fecha_operacion,
    descripcion
FROM audit_operacion;

-- Vista operativa de conductores disponibles para la aplicación
CREATE OR REPLACE VIEW v_conductores_disponibles AS
SELECT
    c.id_usuario AS id_conductor,
    c.id_company,
    u.nombre,
    u.apellido1,
    c.estado_conductor
FROM conductor c
JOIN usuario u
    ON u.id_usuario = c.id_usuario
WHERE u.activo = TRUE
  AND c.estado_conductor = 'disponible';

-- Vista operativa de viajes
CREATE OR REPLACE VIEW v_viajes_operativos AS
SELECT
    id_viaje,
    id_rider,
    id_conductor,
    id_vehiculo,
    estado,
    fecha_solicitud,
    fecha_aceptacion,
    fecha_inicio,
    fecha_fin,
    origen_direccion,
    destino_direccion,
    distancia_km
FROM viaje;

-- Vista operativa de ofertas
CREATE OR REPLACE VIEW v_ofertas_operativas AS
SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    fecha_envio,
    fecha_respuesta,
    estado_oferta,
    importe_ofrecido
FROM oferta;

-- 2. DEFINICION DE ROLES

CREATE ROLE IF NOT EXISTS 'rol_admin';
CREATE ROLE IF NOT EXISTS 'rol_app';
CREATE ROLE IF NOT EXISTS 'rol_analista';
CREATE ROLE IF NOT EXISTS 'rol_backup';
CREATE ROLE IF NOT EXISTS 'rol_readonly';

-- 3. ASIGNACION DE PRIVILEGIOS

-- Rol de administración: control total del esquema
GRANT ALL PRIVILEGES ON ride_hailing.* TO 'rol_admin';

-- Rol de aplicación:
-- La aplicación NO actualiza directamente las tablas críticas.
-- Las operaciones de negocio se canalizan mediante procedimientos almacenados.

-- Lectura mediante vistas operativas.
GRANT SELECT ON ride_hailing.v_conductores_disponibles TO 'rol_app';
GRANT SELECT ON ride_hailing.v_viajes_operativos TO 'rol_app';
GRANT SELECT ON ride_hailing.v_ofertas_operativas TO 'rol_app';

-- Escritura directa solo donde no rompe el flujo crítico de aceptación.
GRANT INSERT ON ride_hailing.valoracion TO 'rol_app';

-- Ejecución de lógica de negocio.
-- La aceptación de ofertas se hace por sp_aceptar_oferta,
-- no con UPDATE directo sobre la tabla oferta.
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_solicitar_viaje TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_aceptar_oferta TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_iniciar_viaje TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_finalizar_viaje_y_pagar TO 'rol_app';

-- Rol de analista:
-- solo lectura sobre vistas y datos no sensibles
GRANT SELECT ON ride_hailing.v_usuarios_anonimizados TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_pagos_analitica TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_viaje_estado_log_resumen TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_viajes_operativos TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_auditoria_operaciones TO 'rol_analista';

-- Rol de solo lectura:
-- pensado para consultas funcionales sin permisos de escritura
GRANT SELECT ON ride_hailing.v_usuarios_anonimizados TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_conductores_disponibles TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_viajes_operativos TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_ofertas_operativas TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_pagos_analitica TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_viaje_estado_log_resumen TO 'rol_readonly';
GRANT SELECT ON ride_hailing.v_auditoria_operaciones TO 'rol_readonly';

-- Rol de backup:
-- lectura del esquema y objetos necesarios para copias lógicas
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES
ON ride_hailing.* TO 'rol_backup';

-- privilegios globales habituales para soporte de backup y binlogs
GRANT RELOAD, PROCESS, REPLICATION CLIENT
ON *.* TO 'rol_backup';

-- 4. GESTION DE USUARIOS

CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'Admin_Pass_2026!';
GRANT 'rol_admin' TO 'admin_user'@'%';
SET DEFAULT ROLE 'rol_admin' TO 'admin_user'@'%';

CREATE USER IF NOT EXISTS 'backend_user'@'%' IDENTIFIED BY 'App_Pass_2026!';
GRANT 'rol_app' TO 'backend_user'@'%';
SET DEFAULT ROLE 'rol_app' TO 'backend_user'@'%';

CREATE USER IF NOT EXISTS 'analyst_user'@'%' IDENTIFIED BY 'Analyst_Pass_2026!';
GRANT 'rol_analista' TO 'analyst_user'@'%';
SET DEFAULT ROLE 'rol_analista' TO 'analyst_user'@'%';

CREATE USER IF NOT EXISTS 'readonly_user'@'%' IDENTIFIED BY 'Readonly_Pass_2026!';
GRANT 'rol_readonly' TO 'readonly_user'@'%';
SET DEFAULT ROLE 'rol_readonly' TO 'readonly_user'@'%';

CREATE USER IF NOT EXISTS 'backup_user'@'%' IDENTIFIED BY 'Backup_Pass_2026!';
GRANT 'rol_backup' TO 'backup_user'@'%';
SET DEFAULT ROLE 'rol_backup' TO 'backup_user'@'%';

-- 5. COMPROBACIONES

SHOW GRANTS FOR 'admin_user'@'%';
SHOW GRANTS FOR 'backend_user'@'%';
SHOW GRANTS FOR 'analyst_user'@'%';
SHOW GRANTS FOR 'readonly_user'@'%';
SHOW GRANTS FOR 'backup_user'@'%';

SHOW GRANTS FOR 'rol_admin';
SHOW GRANTS FOR 'rol_app';
SHOW GRANTS FOR 'rol_analista';
SHOW GRANTS FOR 'rol_readonly';
SHOW GRANTS FOR 'rol_backup';

FLUSH PRIVILEGES;
