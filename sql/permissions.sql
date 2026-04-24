-- CONFIGURACION DE SEGURIDAD Y PRIVILEGIOS
USE ride_hailing;

-- 1. VISTAS DE SEGURIDAD (ANONIMIZACION)
CREATE OR REPLACE VIEW v_usuarios_anonimizados AS
SELECT 
    id_usuario, 
    nombre, 
    fecha_alta, 
    activo
FROM usuario;

-- 2. DEFINICION DE ROLES
CREATE ROLE IF NOT EXISTS 'rol_admin';
CREATE ROLE IF NOT EXISTS 'rol_app';
CREATE ROLE IF NOT EXISTS 'rol_analista';

-- 3. ASIGNACION DE PRIVILEGIOS
-- El rol de administracion mantiene control total
GRANT ALL PRIVILEGES ON ride_hailing.* TO 'rol_admin';

-- El rol de aplicacion se limita a la operativa diaria y ejecucion de logica
GRANT SELECT, INSERT, UPDATE, DELETE ON ride_hailing.* TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_aceptar_oferta TO 'rol_app';
GRANT EXECUTE ON PROCEDURE ride_hailing.sp_generar_liquidaciones TO 'rol_app';
GRANT EXECUTE ON FUNCTION ride_hailing.fn_calcular_precio_total TO 'rol_app';

-- El rol de analista solo accede a datos no sensibles y vistas
GRANT SELECT ON ride_hailing.v_usuarios_anonimizados TO 'rol_analista';
GRANT SELECT ON ride_hailing.pago TO 'rol_analista';
GRANT SELECT ON ride_hailing.viaje_estado_log TO 'rol_analista';

-- 4. GESTION DE USUARIOS
CREATE USER IF NOT EXISTS 'backend_user'@'%' IDENTIFIED BY 'App_Pass_2026!';
GRANT 'rol_app' TO 'backend_user'@'%';
SET DEFAULT ROLE 'rol_app' TO 'backend_user'@'%';

CREATE USER IF NOT EXISTS 'analyst_user'@'%' IDENTIFIED BY 'Analyst_Pass_2026!';
GRANT 'rol_analista' TO 'analyst_user'@'%';
SET DEFAULT ROLE 'rol_analista' TO 'analyst_user'@'%';

FLUSH PRIVILEGES;
