USE cabify;

-- 0. INSERTS DE OPERATIVA BÁSICA

-- 0.1. Insertar un nuevo rider
INSERT INTO
    cabify.rider (
        nombre,
        email,
        telefono,
        activo
    )
VALUES (
        'Pedro Torres',
        'pedro.rider@cabify.test',
        '600000004',
        TRUE
    );

-- 0.2. Insertar un nuevo viaje solicitado sin conductor asignado
INSERT INTO
    cabify.viaje (
        id_rider,
        id_conductor,
        origen_latitud,
        origen_longitud,
        destino_latitud,
        destino_longitud,
        estado
    )
VALUES (
        4,
        NULL,
        40.410000,
        -3.700000,
        40.435000,
        -3.690000,
        'solicitado'
    );

-- 1. SELECT SENCILLOS

-- 1.1. Listar riders
SELECT
    id_rider,
    nombre,
    email,
    telefono,
    activo
FROM cabify.rider
ORDER BY id_rider;

-- 1.2. Listar conductores
SELECT
    id_conductor,
    id_company,
    dni,
    nombre,
    email,
    telefono,
    activo
FROM cabify.conductor
ORDER BY id_conductor;

-- 1.3. Listar viajes
SELECT
    id_viaje,
    id_rider,
    id_conductor,
    estado,
    fecha_solicitud
FROM cabify.viaje
ORDER BY id_viaje;

-- 1.4. Listar ofertas
SELECT
    id_oferta,
    id_viaje,
    id_conductor,
    estado_oferta,
    fecha_envio,
    fecha_respuesta
FROM cabify.oferta
ORDER BY id_oferta;

-- 2. JOINs

-- 2.1. Viajes con datos del rider
SELECT v.id_viaje, r.nombre AS rider, v.estado, v.fecha_solicitud
FROM cabify.viaje v
    JOIN cabify.rider r ON r.id_rider = v.id_rider
ORDER BY v.id_viaje;

-- 2.2. Viajes con rider y conductor (si existe)
SELECT v.id_viaje, r.nombre AS rider, c.nombre AS conductor, v.estado, v.fecha_solicitud
FROM cabify.viaje v
    JOIN cabify.rider r ON r.id_rider = v.id_rider
    LEFT JOIN cabify.conductor c ON c.id_conductor = v.id_conductor
ORDER BY v.id_viaje;

-- 2.3. Conductores con su company
SELECT c.id_conductor, c.nombre AS conductor, co.nombre AS company
FROM cabify.conductor c
    JOIN cabify.company co ON co.id_company = c.id_company
ORDER BY c.id_conductor;

-- 2.4. Ofertas con viaje y conductor
SELECT o.id_oferta, o.id_viaje, c.nombre AS conductor, o.estado_oferta, o.fecha_envio, o.fecha_respuesta
FROM cabify.oferta o
    JOIN cabify.conductor c ON c.id_conductor = o.id_conductor
    JOIN cabify.viaje v ON v.id_viaje = o.id_viaje
ORDER BY o.id_viaje, o.id_oferta;

-- 3. GROUP BY

-- 3.1. Número de viajes por estado
SELECT estado, COUNT(*) AS total_viajes
FROM cabify.viaje
GROUP BY
    estado
ORDER BY estado;

-- 3.2. Número de conductores por company
SELECT co.nombre AS company, COUNT(*) AS total_conductores
FROM cabify.conductor c
    JOIN cabify.company co ON co.id_company = c.id_company
GROUP BY
    co.nombre
ORDER BY co.nombre;

-- 3.3. Número de ofertas recibidas por conductor
SELECT c.nombre AS conductor, COUNT(*) AS total_ofertas
FROM cabify.oferta o
    JOIN cabify.conductor c ON c.id_conductor = o.id_conductor
GROUP BY
    c.nombre
ORDER BY total_ofertas DESC, c.nombre;

-- 3.4. Número de ofertas por viaje
SELECT id_viaje, COUNT(*) AS total_ofertas
FROM cabify.oferta
GROUP BY
    id_viaje
ORDER BY id_viaje;

-- 3.5. Distancia e importe medio de los viajes finalizados
SELECT AVG(distancia_km) AS media_km, AVG(importe_total) AS media_importe
FROM cabify.viaje
WHERE
    estado = 'finalizado';

-- 4. SUBCONSULTAS

-- 4.1. Conductores que tienen al menos una oferta aceptada
SELECT *
FROM cabify.conductor c
WHERE
    c.id_conductor IN (
        SELECT o.id_conductor
        FROM cabify.oferta o
        WHERE
            o.estado_oferta = 'aceptada'
    );

-- 4.2. Riders que han solicitado viajes finalizados
SELECT *
FROM cabify.rider r
WHERE
    r.id_rider IN (
        SELECT v.id_rider
        FROM cabify.viaje v
        WHERE
            v.estado = 'finalizado'
    );

-- 4.3. Viajes que todavía no tienen conductor asignado
SELECT * FROM cabify.viaje v WHERE v.id_conductor IS NULL;

-- 5. UPDATE

-- 5.1. Actualizar el teléfono de un rider
UPDATE cabify.rider SET telefono = '600999999' WHERE id_rider = 1;

-- 5.2. Marcar un vehículo como inactivo
UPDATE cabify.vehiculo SET activo = FALSE WHERE id_vehiculo = 4;

-- 5.3. Actualizar estado de un viaje
UPDATE cabify.viaje SET estado = 'cancelado' WHERE id_viaje = 3;

-- 6. DELETE

-- 6.1. Borrar un registro de auditoría concreto
DELETE FROM cabify.auditoria WHERE id_auditoria = 5;

-- 6.2. Ejemplo de borrado controlado de oferta pendiente
DELETE FROM cabify.oferta
WHERE
    id_oferta = 6
    AND estado_oferta = 'pendiente';

-- 7. TRANSACCIÓN SIMPLE

START TRANSACTION;

INSERT INTO
    cabify.auditoria (
        entidad,
        id_entidad,
        accion,
        detalle
    )
VALUES (
        'viaje',
        3,
        'UPDATE',
        'Cambio manual de estado a cancelado'
    );

UPDATE cabify.viaje SET estado = 'cancelado' WHERE id_viaje = 3;

COMMIT;