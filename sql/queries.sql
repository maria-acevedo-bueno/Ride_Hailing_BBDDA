USE ride_hailing;

-- =========================================================
-- FLUJO COMPLETO DE OPERACION DEL PROGRAMA
-- =========================================================
-- Este archivo no está pensado como una colección aislada de consultas,
-- sino como una demostración funcional de extremo a extremo del sistema:
-- 1) se inspeccionan los datos iniciales
-- 2) se crea un nuevo rider
-- 3) se solicita un viaje
-- 4) un conductor acepta la oferta
-- 5) el viaje se inicia
-- 6) el viaje finaliza y se genera el pago
-- 7) se revisa el log de estados generado por el trigger

-- =========================================================
-- 0. CONSULTAS DE COMPROBACION INICIAL
-- =========================================================
-- Estas consultas sirven para verificar que la carga de datos inicial
-- se ha realizado correctamente y que el entorno está preparado.

-- Ver companies cargadas.
SELECT * FROM company ORDER BY id_company;

-- Ver todos los usuarios.
SELECT * FROM usuario ORDER BY id_usuario;

-- Ver riders.
SELECT * FROM rider ORDER BY id_usuario;

-- Ver conductores y su estado operativo.
SELECT * FROM conductor ORDER BY id_usuario;

-- Ver vehículos disponibles en el sistema.
SELECT * FROM vehiculo ORDER BY id_vehiculo;

-- Ver asignaciones vigentes e históricas entre conductores y vehículos.
SELECT *
FROM conductor_vehiculo
ORDER BY id_conductor, id_vehiculo, fecha_desde;

-- Ver viajes existentes antes del flujo nuevo.
SELECT *
FROM viaje
ORDER BY id_viaje;

-- Ver ofertas históricas existentes.
SELECT *
FROM oferta
ORDER BY id_oferta;

-- Ver pagos ya liquidados.
SELECT *
FROM pago
ORDER BY id_pago;

-- Ver historial previo de estados.
SELECT *
FROM viaje_estado_log
ORDER BY id_historial;

-- =========================================================
-- 1. CREAR UN NUEVO USUARIO RIDER PARA EL FLUJO
-- =========================================================
-- Se crea un usuario nuevo específico para esta prueba funcional.
-- Después se especializa como rider.

INSERT INTO usuario (
    nombre,
    apellido1,
    apellido2,
    email,
    telefono,
    activo
) VALUES (
    'Pedro',
    'Arias',
    'Luna',
    'pedro.arias.flujo@ridehailing.test',
    '600000099',
    TRUE
);

-- Guardamos el id autogenerado para reutilizarlo en el resto del flujo.
SET @id_nuevo_usuario = LAST_INSERT_ID();

-- Convertimos ese usuario en rider.
INSERT INTO rider (id_usuario)
VALUES (@id_nuevo_usuario);

-- Comprobación del rider creado.
SELECT @id_nuevo_usuario AS id_rider_creado;

-- =========================================================
-- 2. SOLICITAR UN NUEVO VIAJE
-- =========================================================
-- Se invoca el procedimiento de negocio que:
-- 1) crea el viaje
-- 2) calcula el importe base
-- 3) genera ofertas para conductores disponibles

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

-- Resultado de la operación:
-- debería devolver el id del viaje creado y 'OK' si salió bien.
SELECT
    @id_viaje_generado AS id_viaje_generado,
    @resultado_solicitud AS resultado_solicitud;

-- Ver el viaje recién creado.
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Ver las ofertas generadas para ese viaje.
-- Esto permite comprobar a qué conductores disponibles se les ofreció.
SELECT *
FROM oferta
WHERE id_viaje = @id_viaje_generado
ORDER BY id_oferta;

-- =========================================================
-- 3. ACEPTAR UNA OFERTA
-- =========================================================
-- Se simula que el conductor 11 acepta el viaje usando el vehículo 1.
-- Esta elección debe ser coherente con la carga de datos:
-- conductor 11 debe estar disponible y tener asignado el vehículo 1.

CALL sp_aceptar_oferta(
    @id_viaje_generado,
    11,
    1,
    @resultado_aceptacion
);

-- Ver resultado de la aceptación.
SELECT @resultado_aceptacion AS resultado_aceptacion;

-- Comprobar que el viaje ha cambiado a aceptado y ya tiene
-- conductor y vehículo asignados.
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Comprobar que una oferta ha quedado aceptada y el resto expiradas.
SELECT *
FROM oferta
WHERE id_viaje = @id_viaje_generado
ORDER BY id_oferta;

-- Comprobar el nuevo estado del conductor.
-- Debería estar marcado como en_viaje.
SELECT *
FROM conductor
WHERE id_usuario = 11;

-- Ver el log generado automáticamente por el trigger tras el cambio de estado.
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 4. INICIAR EL VIAJE
-- =========================================================
-- Una vez aceptado, se inicia el trayecto.
-- Esto debe cambiar el estado de aceptado a en_curso
-- y registrar fecha_inicio.

CALL sp_iniciar_viaje(
    @id_viaje_generado,
    @resultado_inicio
);

-- Ver resultado del inicio.
SELECT @resultado_inicio AS resultado_inicio;

-- Comprobar el viaje tras iniciarlo.
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Revisar el historial de estados tras el inicio.
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 5. FINALIZAR EL VIAJE Y GENERAR EL PAGO
-- =========================================================
-- Se simula la finalización del trayecto.
-- El procedimiento debe:
-- 1) cambiar el viaje a finalizado
-- 2) liberar al conductor
-- 3) calcular el pago
-- 4) insertar la liquidación en la tabla pago

CALL sp_finalizar_viaje_y_pagar(
    @id_viaje_generado,
    'tarjeta_credito',
    @resultado_finalizacion
);

-- Ver resultado de la finalización.
SELECT @resultado_finalizacion AS resultado_finalizacion;

-- Comprobar el viaje ya finalizado.
SELECT *
FROM viaje
WHERE id_viaje = @id_viaje_generado;

-- Comprobar que el conductor vuelve a estar disponible.
SELECT *
FROM conductor
WHERE id_usuario = 11;

-- Ver el pago generado automáticamente.
SELECT *
FROM pago
WHERE id_viaje = @id_viaje_generado;

-- Ver el historial completo de cambios de estado del viaje.
SELECT *
FROM viaje_estado_log
WHERE id_viaje = @id_viaje_generado
ORDER BY id_historial;

-- =========================================================
-- 6. CONSULTAS FINALES DE RESUMEN
-- =========================================================
-- Estas consultas sirven como cierre del flujo y resumen funcional.
-- Permiten enseñar de forma clara el resultado final del proceso completo.

-- Resumen funcional del viaje.
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

-- Resumen económico del viaje.
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

-- Resumen de todas las ofertas asociadas al viaje.
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

-- Resumen cronológico del historial de estados.
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