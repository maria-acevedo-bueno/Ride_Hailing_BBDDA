USE ride_hailing;

-- VISTAS DE SEGURIDAD (Ocultar datos sensibles)

-- Vista de analítica. Ocultamos email, teléfono y apellidos
-- para respetar la privacidad de los usuarios.
CREATE OR REPLACE VIEW v_usuarios_anonimizados AS
SELECT 
    id_usuario, 
    nombre, 
    fecha_alta, 
    activo
FROM usuario;

-- Vista que cruza viajes con compañías y vehículos sin exponer al rider.
-- Muy útil para el dashboard de negocio.
CREATE OR REPLACE VIEW v_viajes_dashboard AS
SELECT 
    v.id_viaje,
    v.estado,
    v.distancia_km,
    v.fecha_solicitud,
    v.fecha_fin,
    veh.matricula,
    c.nombre AS company_nombre
FROM viaje v
LEFT JOIN vehiculo veh ON v.id_vehiculo = veh.id_vehiculo
LEFT JOIN company c ON veh.id_company = c.id_company;


-- CREACIÓN DE ROLES

-- Trabajar con roles nos facilita la vida si mañana entra más gente al equipo,
-- ya que no tenemos que ir dando permisos tabla por tabla a cada persona.

CREATE ROLE IF NOT EXISTS 'rol_admin';
CREATE ROLE IF NOT EXISTS 'rol_app';
CREATE ROLE IF NOT EXISTS 'rol_analista';
CREATE ROLE IF NOT EXISTS 'rol_monitorizacion';

-- ASIGNACIÓN DE PRIVILEGIOS A LOS ROLES (Principio de mínimo privilegio)

-- ROL ADMIN: Control total sobre la estructura y los datos de nuestra base de datos.
GRANT ALL PRIVILEGES ON ride_hailing.* TO 'rol_admin';

-- ROL APP: El backend de nuestra aplicación.
-- Necesita poder leer y escribir datos de la operativa diaria.
-- NO le damos permisos de DROP ni ALTER para que un fallo en el código no borre tablas.
GRANT SELECT, INSERT, UPDATE, DELETE ON ride_hailing.* TO 'rol_app';
-- Le damos permiso explícito para ejecutar nuestros procedimientos almacenados.
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_aceptar_oferta TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_generar_pagos_pendientes TO 'rol_app';

-- ROL ANALISTA: Para el equipo que analiza datos y saca métricas.
-- Solo lectura y únicamente sobre las vistas anonimizadas y tablas no sensibles.
GRANT SELECT ON ride_hailing.v_usuarios_anonimizados TO 'rol_analista';
GRANT SELECT ON ride_hailing.v_viajes_dashboard TO 'rol_analista';
GRANT SELECT ON ride_hailing.pago TO 'rol_analista';
GRANT SELECT ON ride_hailing.valoracion TO 'rol_analista';
GRANT SELECT ON ride_hailing.viaje_estado_log TO 'rol_analista';

-- ROL MONITORIZACIÓN: Para el exporter de Prometheus que configuramos en Docker.
-- Necesita permisos globales para leer el estado interno del motor MySQL.
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'rol_monitorizacion';


-- CREACIÓN DE USUARIOS Y ASIGNACIÓN DE ROLES

-- Administrador de la base de datos
CREATE USER IF NOT EXISTS 'dba_user'@'%' IDENTIFIED BY 'Dba_SuperSecure123!';
GRANT 'rol_admin' TO 'dba_user'@'%';
SET DEFAULT ROLE 'rol_admin' TO 'dba_user'@'%';

-- Usuario para el backend (API) de nuestra aplicación de Ride-Hailing
CREATE USER IF NOT EXISTS 'app_backend'@'%' IDENTIFIED BY 'App_BackendPass456!';
GRANT 'rol_app' TO 'app_backend'@'%';
SET DEFAULT ROLE 'rol_app' TO 'app_backend'@'%';

-- Usuario para el analista de datos o la herramienta de Dashboarding
CREATE USER IF NOT EXISTS 'data_analyst'@'%' IDENTIFIED BY 'Data_Read0nly789!';
GRANT 'rol_analista' TO 'data_analyst'@'%';
SET DEFAULT ROLE 'rol_analista' TO 'data_analyst'@'%';

-- Usuario para Prometheus (mysqld-exporter)
-- OJO: La contraseña debe coincidir con la que pusimos en el compose.yml
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY 'exporterpass';
GRANT 'rol_monitorizacion' TO 'exporter'@'%';
SET DEFAULT ROLE 'rol_monitorizacion' TO 'exporter'@'%';

-- Recargamos los privilegios para que todo aplique al instante
FLUSH PRIVILEGES;