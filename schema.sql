-- CONFIGURACION DEL ESQUEMA OPERATIVO
CREATE DATABASE IF NOT EXISTS ride_hailing;
USE ride_hailing;

-- 1. TABLAS MAESTRAS Y COMPAÑIAS

CREATE TABLE IF NOT EXISTS company (
    id_company BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    cif VARBINARY(255) NOT NULL UNIQUE, -- Almacenamiento cifrado para datos sensibles
    fecha_alta DATE DEFAULT (CURRENT_DATE),
    activa BOOLEAN DEFAULT TRUE,
    INDEX idx_company_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50),
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARBINARY(255) NOT NULL UNIQUE, -- Almacenamiento cifrado
    fecha_alta DATE DEFAULT (CURRENT_DATE),
    activo BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_usuario_email (email)
) ENGINE=InnoDB;

-- 2. ESPECIALIZACION DE USUARIOS

CREATE TABLE IF NOT EXISTS rider (
    id_usuario BIGINT PRIMARY KEY,
    CONSTRAINT fk_rider_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuario(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS conductor (
    id_usuario BIGINT PRIMARY KEY,
    numero_licencia VARCHAR(50) NOT NULL UNIQUE,
    estado_conductor ENUM('disponible', 'en_viaje', 'desconectado', 'suspendido') DEFAULT 'desconectado',
    fecha_alta_conductor DATE DEFAULT (CURRENT_DATE),
    id_company BIGINT,
    CONSTRAINT fk_conductor_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_conductor_company FOREIGN KEY (id_company) 
        REFERENCES company(id_company) ON DELETE SET NULL,
    INDEX idx_conductor_estado (estado_conductor)
) ENGINE=InnoDB;

-- 3. GESTION DE FLOTA Y VIAJES

CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_company BIGINT NOT NULL,
    matricula VARCHAR(20) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    color VARCHAR(30),
    anio INT,
    capacidad INT DEFAULT 4,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_vehiculo_company FOREIGN KEY (id_company) 
        REFERENCES company(id_company) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS viaje (
    id_viaje BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_rider BIGINT NOT NULL,
    id_conductor BIGINT,
    id_vehiculo BIGINT,
    estado ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') DEFAULT 'solicitado',
    fecha_solicitud DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_aceptacion DATETIME,
    fecha_inicio DATETIME,
    fecha_fin DATETIME,
    -- Uso de tipos espaciales para optimizar calculos de cercania
    ubicacion_origen POINT NOT NULL SRID 4326,
    ubicacion_destino POINT NOT NULL SRID 4326,
    origen_direccion VARCHAR(255),
    destino_direccion VARCHAR(255),
    distancia_km DECIMAL(10, 2),
    cancelado_por ENUM('rider', 'conductor', 'sistema'),
    motivo_cancelacion TEXT,
    SPATIAL INDEX idx_viaje_origen (ubicacion_origen),
    CONSTRAINT fk_viaje_rider FOREIGN KEY (id_rider) REFERENCES rider(id_usuario),
    CONSTRAINT fk_viaje_conductor FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario),
    CONSTRAINT fk_viaje_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo),
    INDEX idx_viaje_busqueda (id_rider, estado) -- Indice compuesto para operativa frecuente
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS oferta (
    id_oferta BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT NOT NULL,
    id_conductor BIGINT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta DATETIME,
    estado_oferta ENUM('pendiente', 'aceptada', 'rechazada', 'expirada') DEFAULT 'pendiente',
    importe_ofrecido DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_oferta_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON DELETE CASCADE,
    CONSTRAINT fk_oferta_conductor FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario),
    INDEX idx_oferta_viaje (id_viaje),
    INDEX idx_oferta_estado (estado_oferta)
) ENGINE=InnoDB;

-- 4. ECONOMIA Y VALORACIONES

CREATE TABLE IF NOT EXISTS pago (
    id_pago BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT NOT NULL UNIQUE,
    importe_total DECIMAL(10, 2) NOT NULL,
    comision_company DECIMAL(10, 2) NOT NULL,
    importe_conductor DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM('tarjeta_credito', 'efectivo', 'wallet') DEFAULT 'tarjeta_credito',
    estado_pago ENUM('pendiente', 'completado', 'fallido', 'reembolsado') DEFAULT 'pendiente',
    fecha_pago DATETIME,
    CONSTRAINT fk_pago_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje),
    CONSTRAINT ck_pago_sumas CHECK (importe_total = comision_company + importe_conductor)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS valoracion (
    id_valoracion BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT NOT NULL,
    id_usuario_valorador BIGINT NOT NULL,
    id_usuario_valorado BIGINT NOT NULL,
    rol_valorado ENUM('rider', 'conductor') NOT NULL,
    puntuacion TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_valoracion DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_val_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje),
    CONSTRAINT fk_val_valorador FOREIGN KEY (id_usuario_valorador) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_val_valorado FOREIGN KEY (id_usuario_valorado) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- 5. AUDITORIA CON PARTICIONADO

CREATE TABLE IF NOT EXISTS viaje_estado_log (
    id_historial BIGINT AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    estado_anterior ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado'),
    estado_nuevo ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    comentario VARCHAR(255),
    PRIMARY KEY (id_historial, fecha_cambio)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(fecha_cambio)) (
    PARTITION p_old VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 6. OBJETOS PROGRAMABLES (PROCEDIMIENTOS Y FUNCIONES)

DELIMITER //

-- Funcion para calculo centralizado de tarifas
CREATE FUNCTION fn_calcular_precio_total(p_base DECIMAL(10,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN p_base * 1.20; -- Aplicacion de margen del 20%
END //

-- Procedimiento de aceptacion con control de concurrencia
CREATE PROCEDURE sp_aceptar_oferta(
    IN p_id_viaje BIGINT,
    IN p_id_conductor BIGINT,
    IN p_id_vehiculo BIGINT,
    OUT p_resultado VARCHAR(100)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    START TRANSACTION;
    
    -- Bloqueo de fila para evitar colisiones de aceptacion
    SELECT estado INTO v_estado_actual FROM viaje WHERE id_viaje = p_id_viaje FOR UPDATE;
    
    IF v_estado_actual = 'solicitado' THEN
        UPDATE viaje SET 
            estado = 'aceptado', 
            id_conductor = p_id_conductor, 
            id_vehiculo = p_id_vehiculo,
            fecha_aceptacion = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje;
        
        UPDATE oferta SET 
            estado_oferta = 'aceptada', 
            fecha_respuesta = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje AND id_conductor = p_id_conductor;
        
        UPDATE oferta SET estado_oferta = 'expirada'
        WHERE id_viaje = p_id_viaje AND id_conductor <> p_id_conductor AND estado_oferta = 'pendiente';
        
        UPDATE conductor SET estado_conductor = 'en_viaje' WHERE id_usuario = p_id_conductor;
        
        SET p_resultado = 'OK';
        COMMIT;
    ELSE
        SET p_resultado = 'ERROR_NO_DISPONIBLE';
        ROLLBACK;
    END IF;
END //

-- Procedimiento para generacion automatica de liquidaciones
CREATE PROCEDURE sp_generar_liquidaciones()
BEGIN
    INSERT INTO pago (id_viaje, importe_total, comision_company, importe_conductor, metodo_pago, estado_pago)
    SELECT 
        v.id_viaje,
        fn_calcular_precio_total(o.importe_ofrecido),
        o.importe_ofrecido * 0.20,
        o.importe_ofrecido,
        'tarjeta_credito',
        'pendiente'
    FROM viaje v
    JOIN oferta o ON v.id_viaje = o.id_viaje AND o.estado_oferta = 'aceptada'
    LEFT JOIN pago p ON v.id_viaje = p.id_viaje
    WHERE v.estado = 'finalizado' AND p.id_pago IS NULL;
END //

-- 7. EVENTOS Y TRIGGERS

-- Evento de mantenimiento para expirar ofertas huerfanas
CREATE EVENT ev_limpiar_ofertas_caducadas
ON SCHEDULE EVERY 1 MINUTE
DO
    UPDATE oferta 
    SET estado_oferta = 'expirada'
    WHERE estado_oferta = 'pendiente' 
    AND fecha_envio < (CURRENT_TIMESTAMP - INTERVAL 5 MINUTE);

-- Trigger de auditoria automatica
CREATE TRIGGER tr_audit_viaje_estado
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO viaje_estado_log (id_viaje, estado_anterior, estado_nuevo, comentario)
        VALUES (NEW.id_viaje, OLD.estado, NEW.estado, 'Actualizacion automatica de estado');
    END IF;
END //

DELIMITER ;
