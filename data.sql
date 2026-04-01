USE ride_hailing;

SET NAMES utf8mb4;
SET time_zone = '+00:00';

INSERT INTO company (id_company, nombre, cif, fecha_alta, activa) VALUES
(1, 'Cabify', 'B12345678', '2024-01-10', TRUE),
(2, 'Uber', 'B23456789', '2024-02-05', TRUE),
(3, 'Bolt', 'B34567890', '2024-03-12', TRUE),
(4, 'Lyft', 'B34567891', '2024-04-13', TRUE);


INSERT INTO usuario (id_usuario, nombre, apellido1, apellido2, email, telefono, fecha_alta, activo) VALUES
(1, 'Lucia', 'Garcia', 'Sanz', 'lucia.garcia@example.com', '600000001', '2025-01-10', TRUE),
(2, 'Mateo', 'Lopez', 'Ruiz', 'mateo.lopez@example.com', '600000002', '2025-01-11', TRUE),
(3, 'Sofia', 'Martinez', 'Gil', 'sofia.martinez@example.com', '600000003', '2025-01-12', TRUE),
(4, 'Daniel', 'Perez', 'Mora', 'daniel.perez@example.com', '600000004', '2025-01-13', TRUE),
(5, 'Elena', 'Sanchez', 'Lago', 'elena.sanchez@example.com', '600000005', '2025-01-14', TRUE),
(6, 'Pablo', 'Torres', 'Vega', 'pablo.torres@example.com', '600000006', '2025-01-15', TRUE),
(7, 'Irene', 'Navarro', 'Costa', 'irene.navarro@example.com', '600000007', '2025-01-16', TRUE),
(8, 'Alvaro', 'Romero', 'Diaz', 'alvaro.romero@example.com', '600000008', '2025-01-17', TRUE),
(9, 'Carmen', 'Hernandez', 'Soto', 'carmen.hernandez@example.com', '600000009', '2025-01-18', TRUE),
(10, 'Javier', 'Ortega', 'Rios', 'javier.ortega@example.com', '600000010', '2025-01-19', TRUE),
(11, 'Raul', 'Mendez', 'Prieto', 'raul.mendez@example.com', '600000011', '2025-01-20', TRUE),
(12, 'Nuria', 'Castro', 'Iglesias', 'nuria.castro@example.com', '600000012', '2025-01-21', TRUE),
(13, 'Hugo', 'Serrano', 'Pascual', 'hugo.serrano@example.com', '600000013', '2025-01-22', TRUE),
(14, 'Aitana', 'Cano', 'Blanco', 'aitana.cano@example.com', '600000014', '2025-01-23', TRUE),
(15, 'Diego', 'Fuentes', 'Rey', 'diego.fuentes@example.com', '600000015', '2025-01-24', TRUE),
(16, 'Valeria', 'Leon', 'Molina', 'valeria.leon@example.com', '600000016', '2025-02-24', TRUE),
(17, 'Adrian', 'Delgado', 'Ramos', 'adrian.delgado@example.com', '600000017', '2025-01-26', TRUE),
(18, 'Paula', 'Vidal', 'Nuñez', 'paula.vidal@example.com', '600000018', '2025-01-27', TRUE),
(19, 'Marcos', 'Crespo', 'Sierra', 'marcos.crespo@example.com', '600000019', '2025-01-28', TRUE),
(20, 'Claudia', 'Benitez', 'Peña', 'claudia.benitez@example.com', '600000020', '2025-01-29', TRUE);

INSERT INTO rider (id_usuario) VALUES
(1),(2),(3),(4),(5),(6),(7),(8);

INSERT INTO conductor (id_usuario, numero_licencia, estado_conductor, fecha_alta_conductor, id_company) VALUES
(9,  'LIC-MAD-0001', 'disponible',   '2025-02-01', 1),
(10, 'LIC-MAD-0002', 'disponible',   '2025-02-02', 1),
(11, 'LIC-MAD-0003', 'en_viaje',     '2025-02-03', 1),
(12, 'LIC-MAD-0004', 'disponible',   '2025-02-04', 2),
(13, 'LIC-MAD-0005', 'desconectado', '2025-02-05', 2),
(14, 'LIC-MAD-0006', 'disponible',   '2025-02-06', 2),
(15, 'LIC-MAD-0007', 'disponible',   '2025-02-07', 3),
(16, 'LIC-MAD-0008', 'disponible',   '2025-02-08', 3),
(17, 'LIC-MAD-0009', 'suspendido',   '2025-02-09', 3),
(18, 'LIC-MAD-0010', 'disponible',   '2025-02-10', 1);

INSERT INTO vehiculo (id_vehiculo, id_company, id_conductor, matricula, marca, modelo, color, anio, capacidad, activo) VALUES
(1, 1,  9, '1234ABC', 'Toyota',   'Corolla', 'Blanco', 2021, 4, TRUE),
(2, 1, 10, '2345BCD', 'Seat',     'Leon',    'Negro',  2020, 4, TRUE),
(3, 1, 11, '3456CDE', 'Hyundai',  'i30',     'Gris',   2022, 4, TRUE),
(4, 2, 12, '4567DEF', 'Kia',      'Niro',    'Azul',   2023, 4, TRUE),
(5, 2, 13, '5678EFG', 'Renault',  'Clio',    'Rojo',   2019, 4, TRUE),
(6, 2, 14, '6789FGH', 'Peugeot',  '308',     'Blanco', 2021, 4, TRUE),
(7, 3, 15, '7890GHI', 'Skoda',    'Octavia', 'Gris',   2020, 4, TRUE),
(8, 3, 16, '8901HIJ', 'Toyota',   'Prius',   'Verde',  2022, 4, TRUE),
(9, 3, 17, '9012IJK', 'Volkswagen','Golf',   'Negro',  2021, 4, FALSE),
(10,1, 18, '0123JKL', 'Dacia',    'Sandero', 'Blanco', 2024, 4, TRUE);

INSERT INTO viaje (
    id_viaje, id_rider, id_conductor, id_vehiculo, estado,
    fecha_solicitud, fecha_aceptacion, fecha_inicio, fecha_fin,
    origen_lat, origen_lng, origen_direccion,
    destino_lat, destino_lng, destino_direccion,
    distancia_km, duracion_min, cancelado_por, motivo_cancelacion, id_oferta_aceptada
) VALUES
(1, 1,  9, 1, 'finalizado', '2026-03-20 08:00:00', '2026-03-20 08:01:00', '2026-03-20 08:05:00', '2026-03-20 08:28:00', 40.4168, -3.7038, 'Puerta del Sol, Madrid', 40.4521, -3.6883, 'Chamartin, Madrid', 8.40, 23.00, NULL, NULL, NULL),
(2, 2, 10, 2, 'finalizado', '2026-03-20 09:10:00', '2026-03-20 09:11:00', '2026-03-20 09:15:00', '2026-03-20 09:42:00', 40.4280, -3.7045, 'Gran Via, Madrid', 40.4379, -3.6797, 'Retiro, Madrid', 6.80, 27.00, NULL, NULL, NULL),
(3, 3, 12, 4, 'finalizado', '2026-03-20 10:30:00', '2026-03-20 10:31:00', '2026-03-20 10:36:00', '2026-03-20 11:02:00', 40.4153, -3.7074, 'Atocha, Madrid', 40.4637, -3.7492, 'Moncloa, Madrid', 10.20, 26.00, NULL, NULL, NULL),
(4, 4, NULL, NULL, 'cancelado', '2026-03-20 11:00:00', NULL, NULL, NULL, 40.4090, -3.6910, 'Lavapies, Madrid', 40.4500, -3.7000, 'Nuevos Ministerios, Madrid', NULL, NULL, 'rider', 'El rider cancela antes de asignar conductor', NULL),
(5, 5, 15, 7, 'aceptado', '2026-03-20 12:00:00', '2026-03-20 12:02:00', NULL, NULL, 40.4300, -3.7000, 'Malasana, Madrid', 40.4700, -3.7200, 'Plaza Castilla, Madrid', 9.50, NULL, NULL, NULL, NULL),
(6, 6, 11, 3, 'en_curso', '2026-03-20 12:15:00', '2026-03-20 12:16:00', '2026-03-20 12:22:00', NULL, 40.4200, -3.7050, 'Callao, Madrid', 40.4515, -3.6900, 'Bernabeu, Madrid', 7.10, NULL, NULL, NULL, NULL),
(7, 7, NULL, NULL, 'solicitado', '2026-03-20 12:30:00', NULL, NULL, NULL, 40.4150, -3.7020, 'Tirso de Molina, Madrid', 40.4890, -3.6820, 'Fuencarral, Madrid', NULL, NULL, NULL, NULL, NULL),
(8, 8, 14, 6, 'finalizado', '2026-03-20 13:00:00', '2026-03-20 13:01:00', '2026-03-20 13:05:00', '2026-03-20 13:29:00', 40.4380, -3.7120, 'Arguelles, Madrid', 40.4010, -3.6930, 'Embajadores, Madrid', 7.80, 24.00, NULL, NULL, NULL),
(9, 1, 16, 8, 'finalizado', '2026-03-20 14:00:00', '2026-03-20 14:01:00', '2026-03-20 14:07:00', '2026-03-20 14:33:00', 40.4470, -3.7030, 'Cuatro Caminos, Madrid', 40.4180, -3.6760, 'Goya, Madrid', 8.90, 26.00, NULL, NULL, NULL),
(10,2, NULL, NULL, 'solicitado', '2026-03-20 15:00:00', NULL, NULL, NULL, 40.4250, -3.7100, 'Tribunal, Madrid', 40.4705, -3.6400, 'Arturo Soria, Madrid', NULL, NULL, NULL, NULL, NULL);

INSERT INTO oferta (id_oferta, id_viaje, id_conductor, fecha_envio, fecha_respuesta, estado_oferta, importe_ofrecido) VALUES
(1, 1,  9, '2026-03-20 08:00:10', '2026-03-20 08:00:45', 'aceptada', 13.50),
(2, 1, 10, '2026-03-20 08:00:12', '2026-03-20 08:01:10', 'rechazada', 13.50),
(3, 1, 12, '2026-03-20 08:00:15', '2026-03-20 08:02:00', 'expirada', 13.50),

(4, 2, 10, '2026-03-20 09:10:12', '2026-03-20 09:10:40', 'aceptada', 11.80),
(5, 2,  9, '2026-03-20 09:10:14', '2026-03-20 09:11:00', 'rechazada', 11.80),
(6, 2, 14, '2026-03-20 09:10:16', '2026-03-20 09:11:30', 'expirada', 11.80),

(7, 3, 12, '2026-03-20 10:30:10', '2026-03-20 10:30:50', 'aceptada', 15.20),
(8, 3, 15, '2026-03-20 10:30:15', '2026-03-20 10:31:10', 'rechazada', 15.20),
(9, 3, 16, '2026-03-20 10:30:18', '2026-03-20 10:31:20', 'expirada', 15.20),

(10,4, 13, '2026-03-20 11:00:10', NULL, 'pendiente', 14.00),
(11,4, 14, '2026-03-20 11:00:12', NULL, 'pendiente', 14.00),

(12,5, 15, '2026-03-20 12:00:10', '2026-03-20 12:01:00', 'aceptada', 16.50),
(13,5, 16, '2026-03-20 12:00:12', '2026-03-20 12:01:20', 'rechazada', 16.50),
(14,5, 18, '2026-03-20 12:00:14', '2026-03-20 12:02:10', 'expirada', 16.50),

(15,6, 11, '2026-03-20 12:15:10', '2026-03-20 12:15:45', 'aceptada', 12.30),
(16,6,  9, '2026-03-20 12:15:12', '2026-03-20 12:16:05', 'rechazada', 12.30),
(17,6, 12, '2026-03-20 12:15:14', '2026-03-20 12:16:15', 'expirada', 12.30),

(18,7, 10, '2026-03-20 12:30:10', NULL, 'pendiente', 17.20),
(19,7, 14, '2026-03-20 12:30:12', NULL, 'pendiente', 17.20),
(20,7, 15, '2026-03-20 12:30:15', NULL, 'pendiente', 17.20),

(21,8, 14, '2026-03-20 13:00:10', '2026-03-20 13:00:42', 'aceptada', 12.90),
(22,8, 10, '2026-03-20 13:00:12', '2026-03-20 13:01:03', 'rechazada', 12.90),
(23,8, 18, '2026-03-20 13:00:14', '2026-03-20 13:01:11', 'expirada', 12.90),

(24,9, 16, '2026-03-20 14:00:10', '2026-03-20 14:00:40', 'aceptada', 14.10),
(25,9, 12, '2026-03-20 14:00:12', '2026-03-20 14:01:01', 'rechazada', 14.10),
(26,9, 15, '2026-03-20 14:00:14', '2026-03-20 14:01:18', 'expirada', 14.10),

(27,10,  9, '2026-03-20 15:00:10', NULL, 'pendiente', 18.40),
(28,10, 10, '2026-03-20 15:00:12', NULL, 'pendiente', 18.40),
(29,10, 18, '2026-03-20 15:00:15', NULL, 'pendiente', 18.40);

UPDATE viaje SET id_oferta_aceptada = 1  WHERE id_viaje = 1;
UPDATE viaje SET id_oferta_aceptada = 4  WHERE id_viaje = 2;
UPDATE viaje SET id_oferta_aceptada = 7  WHERE id_viaje = 3;
UPDATE viaje SET id_oferta_aceptada = 12 WHERE id_viaje = 5;
UPDATE viaje SET id_oferta_aceptada = 15 WHERE id_viaje = 6;
UPDATE viaje SET id_oferta_aceptada = 21 WHERE id_viaje = 8;
UPDATE viaje SET id_oferta_aceptada = 24 WHERE id_viaje = 9;

INSERT INTO pago (id_pago, id_viaje, importe_total, comision_company, importe_conductor, metodo_pago, estado_pago, fecha_pago) VALUES
(1, 1, 16.20, 3.24, 12.96, 'tarjeta', 'completado', '2026-03-20 08:29:00'),
(2, 2, 14.50, 2.90, 11.60, 'paypal',  'completado', '2026-03-20 09:43:00'),
(3, 3, 18.10, 3.62, 14.48, 'tarjeta', 'completado', '2026-03-20 11:03:00'),
(4, 5, 19.80, 3.96, 15.84, 'bizum',   'pendiente',  NULL),
(5, 6, 13.90, 2.78, 11.12, 'tarjeta', 'pendiente',  NULL),
(6, 8, 15.40, 3.08, 12.32, 'tarjeta', 'completado', '2026-03-20 13:30:00'),
(7, 9, 17.30, 3.46, 13.84, 'paypal',  'completado', '2026-03-20 14:34:00');

INSERT INTO viaje_estado_log (id_historial, id_viaje, estado_anterior, estado_nuevo, fecha_cambio, id_usuario_actor, comentario) VALUES
(1, 1, NULL,         'solicitado', '2026-03-20 08:00:00', 1,  'Creacion del viaje'),
(2, 1, 'solicitado', 'aceptado',   '2026-03-20 08:01:00', 9,  'Oferta aceptada por el conductor'),
(3, 1, 'aceptado',   'en_curso',   '2026-03-20 08:05:00', 9,  'Inicio del trayecto'),
(4, 1, 'en_curso',   'finalizado', '2026-03-20 08:28:00', 9,  'Viaje completado'),

(5, 2, NULL,         'solicitado', '2026-03-20 09:10:00', 2,  'Creacion del viaje'),
(6, 2, 'solicitado', 'aceptado',   '2026-03-20 09:11:00', 10, 'Oferta aceptada'),
(7, 2, 'aceptado',   'en_curso',   '2026-03-20 09:15:00', 10, 'Inicio del trayecto'),
(8, 2, 'en_curso',   'finalizado', '2026-03-20 09:42:00', 10, 'Viaje finalizado'),

(9, 3, NULL,         'solicitado', '2026-03-20 10:30:00', 3,  'Creacion del viaje'),
(10,3, 'solicitado', 'aceptado',   '2026-03-20 10:31:00', 12, 'Oferta aceptada'),
(11,3, 'aceptado',   'en_curso',   '2026-03-20 10:36:00', 12, 'Inicio del trayecto'),
(12,3, 'en_curso',   'finalizado', '2026-03-20 11:02:00', 12, 'Viaje finalizado'),

(13,4, NULL,         'solicitado', '2026-03-20 11:00:00', 4,  'Creacion del viaje'),
(14,4, 'solicitado', 'cancelado',  '2026-03-20 11:03:00', 4,  'Cancelado por rider'),

(15,5, NULL,         'solicitado', '2026-03-20 12:00:00', 5,  'Creacion del viaje'),
(16,5, 'solicitado', 'aceptado',   '2026-03-20 12:02:00', 15, 'Oferta aceptada'),

(17,6, NULL,         'solicitado', '2026-03-20 12:15:00', 6,  'Creacion del viaje'),
(18,6, 'solicitado', 'aceptado',   '2026-03-20 12:16:00', 11, 'Oferta aceptada'),
(19,6, 'aceptado',   'en_curso',   '2026-03-20 12:22:00', 11, 'Inicio del trayecto'),

(20,7, NULL,         'solicitado', '2026-03-20 12:30:00', 7,  'Creacion del viaje'),

(21,8, NULL,         'solicitado', '2026-03-20 13:00:00', 8,  'Creacion del viaje'),
(22,8, 'solicitado', 'aceptado',   '2026-03-20 13:01:00', 14, 'Oferta aceptada'),
(23,8, 'aceptado',   'en_curso',   '2026-03-20 13:05:00', 14, 'Inicio del trayecto'),
(24,8, 'en_curso',   'finalizado', '2026-03-20 13:29:00', 14, 'Viaje finalizado'),

(25,9, NULL,         'solicitado', '2026-03-20 14:00:00', 1,  'Creacion del viaje'),
(26,9, 'solicitado', 'aceptado',   '2026-03-20 14:01:00', 16, 'Oferta aceptada'),
(27,9, 'aceptado',   'en_curso',   '2026-03-20 14:07:00', 16, 'Inicio del trayecto'),
(28,9, 'en_curso',   'finalizado', '2026-03-20 14:33:00', 16, 'Viaje finalizado'),

(29,10, NULL,        'solicitado', '2026-03-20 15:00:00', 2,  'Creacion del viaje');

INSERT INTO valoracion (id_valoracion, id_viaje, id_usuario_valorador, id_usuario_valorado, rol_valorado, puntuacion, comentario, fecha_valoracion) VALUES
(1, 1, 1,  9, 'conductor', 5, 'Conduccion muy comoda', '2026-03-20 08:35:00'),
(2, 1, 9,  1, 'rider',     5, 'Rider puntual y amable', '2026-03-20 08:36:00'),
(3, 2, 2, 10, 'conductor', 4, 'Buen servicio',          '2026-03-20 09:50:00'),
(4, 2, 10, 2, 'rider',     5, 'Cliente correcto',       '2026-03-20 09:51:00'),
(5, 3, 3, 12, 'conductor', 5, 'Trayecto rapido',        '2026-03-20 11:10:00'),
(6, 8, 8, 14, 'conductor', 4, 'Todo bien',              '2026-03-20 13:40:00'),
(7, 9, 1, 16, 'conductor', 5, 'Excelente atencion',     '2026-03-20 14:40:00');

INSERT INTO audit_log (tabla_afectada, id_registro, accion, detalle, fecha_evento) VALUES
('viaje', 1, 'INSERT', 'Alta inicial del viaje 1', '2026-03-20 08:00:00'),
('oferta', 1, 'INSERT', 'Creacion de oferta 1 para viaje 1', '2026-03-20 08:00:10'),
('pago', 1, 'INSERT', 'Registro de pago completado del viaje 1', '2026-03-20 08:29:00'),
('viaje', 4, 'UPDATE', 'Viaje cancelado por el rider', '2026-03-20 11:03:00'),
('viaje', 6, 'UPDATE', 'Viaje en curso', '2026-03-20 12:22:00');