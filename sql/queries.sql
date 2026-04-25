USE ride_hailing;

-- =========================================================
-- FLUJO COMPLETO DE OPERACION DEL PROGRAMA
-- =========================================================

-- 0. CONSULTAS DE COMPROBACION INICIAL

-- Ver companies
SELECT * FROM company ORDER BY id_company;

-- Ver usuarios
SELECT * FROM usuario ORDER BY id_usuario;

-- Ver riders
SELECT * FROM rider ORDER BY id_usuario;

-- Ver conductores
SELECT * FROM conductor ORDER BY id_usuario;

-- Ver vehículos
SELECT * FROM vehiculo ORDER BY id_vehiculo;

-- Ver asignaciones vigentes conductor-vehículo
SELECT *
FROM conductor_vehiculo
ORDER BY id_conductor, id_vehiculo, fecha_desde;

-- Ver estado actual de los viajes históricos
SELECT *
FROM viaje
ORDER BY id_viaje;

-- Ver ofertas históricas
SELECT *
FROM oferta
ORDER BY id_oferta;

-- Ver pagos históricos
SELECT *
FROM pago
ORDER BY id_pago;

-- Ver log histórico
SELECT *
FROM viaje_estado_log
ORDER BY id_historial;

-- =========================================================
-- 1. CREAR UN NUEVO USUARIO RIDER PARA EL FLUJO
-- =========================================================

INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES (
    'Pedro',
    'Torres',
    'Luna',
    'pedro.torres@ridehailing.test',
    '600000099',
    TRUE
);

SET @id_nuevo_usuario = LAST_INSERT_ID();

INSERT INTO rider (id_usuario)
VALUES (@id_nuevo_usuario);

SELECT @id_nuevo_usuario AS id_rider_creado;

-- =========================================================
-- 2. SOLICITAR UN NUEVO VIAJE
-- =========================================================

CALL sp_solicitar_viaje(
    @id_nuevo_usuario,
    40.410000,
    -3.700000,
    40.440000,
    -3.690000,
    'Gran Via, Madrid',
    'Plaza Castilla, Madrid',
    7.50,
    @id_viaje_generado,
    @resultado_solicitud
);

SELECT
    @id_viaje_generado AS id_viaje_generado,
    @resultado_solicitud AS resultado_solicitud;

-- Ver el viaje recién creado
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Ver las ofertas generadas para ese viaje
SELECT *
FROM oferta
WHERE id_viaje = @id_viaje_generado
ORDER BY id_oferta;

-- =========================================================
-- 3. ACEPTAR UNA OFERTA
-- Elegimos un conductor y un vehículo coherentes con los datos cargados.
-- En este caso: conductor 6 con vehículo 1
-- =========================================================

CALL sp_aceptar_oferta(
    @id_viaje_generado,
    6,
    1,
    @resultado_aceptacion
);

SELECT @resultado_aceptacion AS resultado_aceptacion;

-- Ver el viaje tras la aceptación
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Ver las ofertas tras la aceptación
SELECT *
FROM oferta
WHERE id_viaje = @id_viaje_generado
ORDER BY id_oferta;

-- Ver el conductor tras la aceptación
SELECT *
FROM conductor
WHERE id_usuario = 6;

-- Ver el log generado por el trigger
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 4. INICIAR EL VIAJE
-- =========================================================

CALL sp_iniciar_viaje(
    @id_viaje_generado,
    @resultado_inicio
);

SELECT @resultado_inicio AS resultado_inicio;

-- Ver viaje tras iniciarlo
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Ver log tras el inicio
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 5. FINALIZAR EL VIAJE Y GENERAR EL PAGO
-- =========================================================

CALL sp_finalizar_viaje_y_pagar(
    @id_viaje_generado,
    'tarjeta_credito',
    @resultado_finalizacion
);

SELECT @resultado_finalizacion AS resultado_finalizacion;

-- Ver viaje finalizado
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Ver conductor liberado
SELECT *
FROM conductor
WHERE id_usuario = 6;

-- Ver pago generado
SELECT *
FROM pago
WHERE id_viaje = @id_viaje_generado;

-- Ver log completo del flujo del viaje
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 6. CONSULTAS FINALES DE RESUMEN
-- =========================================================

-- Resumen del último viaje creado
SELECT
    v.id_viaje,
    v.id_rider,
    v.id_conductor,
    v.id_vehiculo,
    v.estado,
    v.fecha_solicitud,
    v.fecha_aceptacion,
    v.fecha_inicio,
    v.fecha_fin,
    v.origen_direccion,
    v.destino_direccion,
    v.distancia_km
FROM viaje v
WHERE v.id_viaje = @id_viaje_generado;

-- Resumen económico del viaje
SELECT
    p.id_pago,
    p.id_viaje,
    p.importe_total,
    p.comision_company,
    p.importe_conductor,
    p.metodo_pago,
    p.estado_pago,
    p.fecha_pago
FROM pago p
WHERE p.id_viaje = @id_viaje_generado;

-- Resumen de ofertas del viaje
SELECT
    o.id_oferta,
    o.id_viaje,
    o.id_conductor,
    o.estado_oferta,
    o.importe_ofrecido,
    o.fecha_envio,
    o.fecha_respuesta
FROM oferta o
WHERE o.id_viaje = @id_viaje_generado
ORDER BY o.id_oferta;

-- Resumen del historial de estados
SELECT
    l.id_historial,
    l.id_viaje,
    l.estado_anterior,
    l.estado_nuevo,
    l.fecha_cambio,
    l.comentario
FROM viaje_estado_log l
WHERE l.id_viaje = @id_viaje_generado
ORDER BY l.id_historial;