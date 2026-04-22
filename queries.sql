USE ride_hailing;

-- OPERATIVA BÁSICA (INSERTs y UPDATEs sencillos)

-- Un nuevo rider se registra en la plataforma
INSERT INTO usuario (nombre, apellido1, email, telefono) 
VALUES ('Laura', 'Gómez', 'laura.gomez@email.com', '+34600999000');
INSERT INTO rider (id_usuario) VALUES (LAST_INSERT_ID());

-- El rider solicita un nuevo viaje
INSERT INTO viaje (id_rider, estado, origen_lat, origen_lng, origen_direccion, destino_lat, destino_lng, destino_direccion) 
VALUES (5, 'solicitado', 40.4520, -3.6900, 'Nuevos Ministerios', 40.4165, -3.7025, 'Plaza Mayor');

-- El sistema genera ofertas para los conductores cercanos y disponibles
INSERT INTO oferta (id_viaje, id_conductor, importe_ofrecido) VALUES (4, 3, 10.50);
INSERT INTO oferta (id_viaje, id_conductor, importe_ofrecido) VALUES (4, 4, 10.50);

-- TRANSACCIONES Y LOCKS POR CONCURRENCIA (Protección de datos)

-- CASO: El rider decide CANCELAR el viaje justo en el mismo milisegundo en el que 
-- un conductor está intentando aceptarlo. 
-- Solución: Usamos FOR UPDATE para bloquear la fila del viaje, comprobar su estado 
-- de forma segura y cancelarlo, invalidando las ofertas.

START TRANSACTION;

-- Bloqueamos el viaje para que nadie más lo modifique mientras pensamos
SELECT estado FROM viaje WHERE id_viaje = 4 FOR UPDATE;

-- (Aquí la aplicación comprobaría si el estado es 'solicitado' o 'aceptado')
-- Si es así, procedemos a cancelar todo en bloque:
UPDATE viaje 
SET estado = 'cancelado', cancelado_por = 'rider', motivo_cancelacion = 'Tardaba mucho' 
WHERE id_viaje = 4;

-- Expiramos todas las ofertas pendientes para que a los conductores les desaparezcan de la pantalla
UPDATE oferta 
SET estado_oferta = 'expirada' 
WHERE id_viaje = 4 AND estado_oferta = 'pendiente';

COMMIT;
-- Fin de la transacción segura.

-- JOINS COMPLEJOS (Lecturas para la aplicación)

-- CASO: El rider quiere ver el "Ticket" o historial detallado de su viaje finalizado
-- Requiere cruzar 6 tablas para tener la info completa.
SELECT 
    v.id_viaje,
    v.fecha_solicitud,
    v.origen_direccion,
    v.destino_direccion,
    v.distancia_km,
    u_cond.nombre AS nombre_conductor,
    veh.matricula,
    c.nombre AS nombre_company,
    p.importe_total,
    val.puntuacion AS estrellas_dadas
FROM viaje v
JOIN usuario u_cond ON v.id_conductor = u_cond.id_usuario
JOIN vehiculo veh ON v.id_vehiculo = veh.id_vehiculo
JOIN company c ON veh.id_company = c.id_company
JOIN pago p ON v.id_viaje = p.id_viaje
LEFT JOIN valoracion val ON v.id_viaje = val.id_viaje AND val.rol_valorado = 'conductor'
WHERE v.id_rider = 1 AND v.estado = 'finalizado';

-- CASO: Llamada al Procedimiento Almacenado de aceptación de oferta 
-- Esto simula cuando un conductor pulsa el botón "Aceptar" en la app.
CALL sp_aceptar_oferta(3, 3, 1, @resultado);
SELECT @resultado AS mensaje_operacion;