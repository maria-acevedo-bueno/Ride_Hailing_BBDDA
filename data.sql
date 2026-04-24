-- CARGA DE DATOS DE PRUEBA
USE ride_hailing;

-- Definicion de clave para cifrado (Simulacion de entorno seguro)
SET @key_str = 'ClaveSegura2026';

-- 1. COMPAÑIAS Y USUARIOS
INSERT INTO company (nombre, cif, fecha_alta, activa) VALUES 
('Uber España', AES_ENCRYPT('B12345678', @key_str), '2020-01-15', TRUE),
('Bolt Madrid', AES_ENCRYPT('B87654321', @key_str), '2021-03-10', TRUE);

INSERT INTO usuario (nombre, apellido1, apellido2, email, telefono) VALUES 
('Ana', 'García', 'López', 'ana.garcia@email.com', AES_ENCRYPT('+34600111222', @key_str)),
('Carlos', 'Ruiz', 'Sánchez', 'carlos.ruiz@email.com', AES_ENCRYPT('+34600333444', @key_str)),
('Elena', 'Martínez', 'Gómez', 'elena.martinez@email.com', AES_ENCRYPT('+34600555666', @key_str)),
('Javier', 'Fernández', 'Díaz', 'javier.fernandez@email.com', AES_ENCRYPT('+34600777888', @key_str));

-- 2. ROLES ESPECIFICOS
INSERT INTO rider (id_usuario) VALUES (1), (2);
INSERT INTO conductor (id_usuario, numero_licencia, estado_conductor, id_company) VALUES 
(3, 'LIC-998877', 'disponible', 1),
(4, 'LIC-112233', 'disponible', 2);

-- 3. VEHICULOS
INSERT INTO vehiculo (id_company, matricula, marca, modelo, color, anio) VALUES 
(1, '1234-LMN', 'Toyota', 'Corolla', 'Blanco', 2022),
(2, '9876-XYZ', 'Kia', 'Niro', 'Negro', 2023);

-- 4. OPERATIVA DE VIAJES (Con datos espaciales)
-- SRID 4326: Coordenadas GPS estandar
INSERT INTO viaje (id_rider, id_conductor, id_vehiculo, estado, ubicacion_origen, ubicacion_destino, origen_direccion, destino_direccion, distancia_km) VALUES 
(1, 3, 1, 'finalizado', ST_GeomFromText('POINT(40.4168 -3.7038)', 4326), ST_GeomFromText('POINT(40.4530 -3.6883)', 4326), 'Sol, Madrid', 'Bernabéu, Madrid', 5.2);

INSERT INTO viaje (id_rider, id_conductor, id_vehiculo, estado, ubicacion_origen, ubicacion_destino, origen_direccion, destino_direccion) VALUES 
(2, 4, 2, 'en_curso', ST_GeomFromText('POINT(40.4290 -3.7012)', 4326), ST_GeomFromText('POINT(40.4000 -3.7167)', 4326), 'Malasaña, Madrid', 'Matadero, Madrid');

-- 5. OFERTAS Y PAGOS
INSERT INTO oferta (id_viaje, id_conductor, estado_oferta, importe_ofrecido) VALUES 
(1, 3, 'aceptada', 12.50),
(2, 4, 'aceptada', 10.00);

-- Ejecucion de liquidacion automatica para el viaje finalizado
CALL sp_generar_liquidaciones();

-- 6. VALORACIONES
INSERT INTO valoracion (id_viaje, id_usuario_valorador, id_usuario_valorado, rol_valorado, puntuacion, comentario) VALUES 
(1, 1, 3, 'conductor', 5, 'Servicio excelente');
