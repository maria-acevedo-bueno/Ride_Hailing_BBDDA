-- CARGA DE MOCK DATA

USE ride_hailing;

-- COMPAÑÍAS Y USUARIOS BASE

-- Insertamos un par de compañías de transporte
INSERT INTO company (nombre, cif, fecha_alta, activa) VALUES 
('Uber España', 'B12345678', '2020-01-15', TRUE),
('Bolt Madrid', 'B87654321', '2021-03-10', TRUE);

-- Insertamos 4 usuarios base (2 serán riders y 2 serán conductores)
INSERT INTO usuario (nombre, apellido1, apellido2, email, telefono) VALUES 
('Ana', 'García', 'López', 'ana.garcia@email.com', '+34600111222'),
('Carlos', 'Ruiz', 'Sánchez', 'carlos.ruiz@email.com', '+34600333444'),
('Elena', 'Martínez', 'Gómez', 'elena.martinez@email.com', '+34600555666'),
('Javier', 'Fernández', 'Díaz', 'javier.fernandez@email.com', '+34600777888');

-- ESPECIALIZACIÓN: RIDERS Y CONDUCTORES

-- Ana (id 1) y Carlos (id 2) son Riders
INSERT INTO rider (id_usuario) VALUES (1), (2);

-- Elena (id 3) y Javier (id 4) son Conductores
INSERT INTO conductor (id_usuario, numero_licencia, estado_conductor, id_company) VALUES 
(3, 'LIC-998877', 'disponible', 1), -- Elena trabaja para Uber
(4, 'LIC-112233', 'disponible', 2); -- Javier trabaja para Bolt

-- VEHÍCULOS

-- Asignamos un par de coches a las compañías
INSERT INTO vehiculo (id_company, matricula, marca, modelo, color, anio) VALUES 
(1, '1234-LMN', 'Toyota', 'Corolla', 'Blanco', 2022),
(2, '9876-XYZ', 'Kia', 'Niro', 'Negro', 2023);

-- VIAJES (Diferentes estados para dar juego en el dashboard)

-- Viaje 1: Ya finalizado (Lo hizo Ana con Elena)
INSERT INTO viaje (id_rider, id_conductor, id_vehiculo, estado, fecha_solicitud, fecha_aceptacion, fecha_inicio, fecha_fin, origen_lat, origen_lng, origen_direccion, destino_lat, destino_lng, destino_direccion, distancia_km) VALUES 
(1, 3, 1, 'finalizado', '2025-01-20 10:00:00', '2025-01-20 10:02:00', '2025-01-20 10:05:00', '2025-01-20 10:25:00', 40.4168, -3.7038, 'Sol, Madrid', 40.4530, -3.6883, 'Bernabéu, Madrid', 5.2);

-- Viaje 2: En curso (Carlos con Javier)
INSERT INTO viaje (id_rider, id_conductor, id_vehiculo, estado, fecha_solicitud, fecha_aceptacion, fecha_inicio, origen_lat, origen_lng, origen_direccion, destino_lat, destino_lng, destino_direccion) VALUES 
(2, 4, 2, 'en_curso', '2025-01-25 15:30:00', '2025-01-25 15:31:00', '2025-01-25 15:35:00', 40.4290, -3.7012, 'Malasaña, Madrid', 40.4000, -3.7167, 'Matadero, Madrid');

-- Viaje 3: Recién solicitado (Nadie lo ha aceptado aún, id_conductor e id_vehiculo son NULL)
INSERT INTO viaje (id_rider, estado, origen_lat, origen_lng, origen_direccion, destino_lat, destino_lng, destino_direccion) VALUES 
(1, 'solicitado', 40.4153, -3.6845, 'Retiro, Madrid', 40.4893, -3.6827, 'Plaza Castilla, Madrid');

-- OFERTAS

-- Ofertas para el Viaje 1 (Elena la aceptó, Javier llegó tarde y expiró)
INSERT INTO oferta (id_viaje, id_conductor, estado_oferta, importe_ofrecido, fecha_envio, fecha_respuesta) VALUES 
(1, 3, 'aceptada', 12.50, '2025-01-20 10:01:00', '2025-01-20 10:02:00'),
(1, 4, 'expirada', 12.50, '2025-01-20 10:01:00', NULL);

-- Ofertas para el Viaje 3 (Están pendientes porque acaba de pedirlo)
INSERT INTO oferta (id_viaje, id_conductor, estado_oferta, importe_ofrecido) VALUES 
(3, 3, 'pendiente', 15.00),
(3, 4, 'pendiente', 15.00);

-- PAGOS Y VALORACIONES (Solo para viajes finalizados)

-- Generamos el pago del Viaje 1
INSERT INTO pago (id_viaje, importe_total, comision_company, importe_conductor, metodo_pago, estado_pago, fecha_pago) VALUES 
(1, 15.00, 3.00, 12.00, 'tarjeta_credito', 'completado', '2025-01-20 10:26:00');

-- Ana valora a Elena por el Viaje 1 (5 estrellas!)
INSERT INTO valoracion (id_viaje, id_usuario_valorador, id_usuario_valorado, rol_valorado, puntuacion, comentario) VALUES 
(1, 1, 3, 'conductor', 5, 'Conducción excelente y coche muy limpio.');

-- AUDITORÍA (Logs iniciales manuales)
-- Como nuestro Trigger funciona con 'AFTER UPDATE', los INSERTs iniciales
-- no generan log. Por eso metemos manualmente un par de históricos para que
-- el dashboard tenga algo que mostrar desde el principio.

INSERT INTO viaje_estado_log (id_viaje, estado_anterior, estado_nuevo, comentario) VALUES 
(1, NULL, 'solicitado', 'Viaje creado por el rider'),
(1, 'solicitado', 'aceptado', 'El conductor aceptó la oferta'),
(1, 'aceptado', 'en_curso', 'El conductor ha recogido al rider'),
(1, 'en_curso', 'finalizado', 'El viaje ha terminado correctamente');