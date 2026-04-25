-- CONFIGURACION DEL ESQUEMA OPERATIVO
DROP DATABASE IF EXISTS ride_hailing;
CREATE DATABASE ride_hailing;
USE ride_hailing;

-- 1. TABLAS MAESTRAS Y COMPANIES

CREATE TABLE IF NOT EXISTS company (

    id_company BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    cif VARCHAR(9) NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,

    PRIMARY KEY (id_company),
    CONSTRAINT uk_company_cif UNIQUE (cif)

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS usuario (

    id_usuario BIGINT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50),
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,

    PRIMARY KEY (id_usuario),
    CONSTRAINT uk_usuario_email UNIQUE (email),
    CONSTRAINT uk_usuario_telefono UNIQUE (telefono)

) ENGINE = InnoDB;

-- 2. ESPECIALIZACION DE USUARIOS

CREATE TABLE IF NOT EXISTS rider (

    id_usuario BIGINT NOT NULL,

    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_rider_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS conductor (

    id_usuario BIGINT NOT NULL,
    numero_licencia VARCHAR(50) NOT NULL,
    estado_conductor ENUM('disponible', 'en_viaje', 'desconectado', 'suspendido') DEFAULT 'desconectado' NOT NULL,
    fecha_alta_conductor DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_modificacion_conductor DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    id_company BIGINT NOT NULL,

    PRIMARY KEY (id_usuario),
    CONSTRAINT uk_conductor_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_conductor_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_conductor_company FOREIGN KEY (id_company)
        REFERENCES company(id_company) ON UPDATE CASCADE ON DELETE RESTRICT,

    INDEX idx_conductor_company (id_company),
    INDEX idx_conductor_estado (estado_conductor)

) ENGINE = InnoDB;

-- 3. GESTION DE FLOTA Y VIAJES

CREATE TABLE IF NOT EXISTS vehiculo (

    id_vehiculo BIGINT NOT NULL AUTO_INCREMENT,
    id_company BIGINT NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    capacidad INT DEFAULT 4 NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,

    PRIMARY KEY (id_vehiculo),
    CONSTRAINT uk_vehiculo_matricula UNIQUE (matricula),
    CONSTRAINT fk_vehiculo_company FOREIGN KEY (id_company)
        REFERENCES company(id_company) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_vehiculo_capacidad CHECK (capacidad > 0),

    INDEX idx_vehiculo_company (id_company)

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS conductor_vehiculo (

    id_conductor BIGINT NOT NULL,
    id_vehiculo BIGINT NOT NULL,
    fecha_desde DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_hasta DATETIME NULL,

    PRIMARY KEY (id_conductor, id_vehiculo, fecha_desde),

    CONSTRAINT fk_cv_conductor FOREIGN KEY (id_conductor)
        REFERENCES conductor(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cv_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo(id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT,

    INDEX idx_cv_conductor_vigente (id_conductor, fecha_hasta),
    INDEX idx_cv_vehiculo_vigente (id_vehiculo, fecha_hasta)

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS viaje (

    id_viaje BIGINT NOT NULL AUTO_INCREMENT,
    id_rider BIGINT NOT NULL,
    id_conductor BIGINT NULL,
    id_vehiculo BIGINT NULL,
    estado ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') DEFAULT 'solicitado' NOT NULL,
    fecha_solicitud DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_aceptacion DATETIME NULL,
    fecha_inicio DATETIME NULL,
    fecha_fin DATETIME NULL,
    latitud_origen DECIMAL(9, 6) NOT NULL,
    longitud_origen DECIMAL(9, 6) NOT NULL,
    latitud_destino DECIMAL(9, 6) NOT NULL,
    longitud_destino DECIMAL(9, 6) NOT NULL,
    origen_direccion VARCHAR(255) NOT NULL,
    destino_direccion VARCHAR(255) NOT NULL,
    distancia_km DECIMAL(10, 2) NULL,
    cancelado_por ENUM('rider', 'conductor', 'sistema') NULL,
    motivo_cancelacion VARCHAR(255) NULL,

    PRIMARY KEY (id_viaje),
    CONSTRAINT fk_viaje_rider FOREIGN KEY (id_rider)
        REFERENCES rider(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viaje_conductor FOREIGN KEY (id_conductor)
        REFERENCES conductor(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viaje_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo(id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT ck_viaje_lat_origen CHECK (latitud_origen BETWEEN -90 AND 90),
    CONSTRAINT ck_viaje_lng_origen CHECK (longitud_origen BETWEEN -180 AND 180),
    CONSTRAINT ck_viaje_lat_destino CHECK (latitud_destino BETWEEN -90 AND 90),
    CONSTRAINT ck_viaje_lng_destino CHECK (longitud_destino BETWEEN -180 AND 180),
    CONSTRAINT ck_viaje_distancia CHECK (distancia_km IS NULL OR distancia_km >= 0),

    INDEX idx_viaje_estado_fecha (estado, fecha_solicitud),
    INDEX idx_viaje_conductor_fecha (id_conductor, fecha_solicitud),
    INDEX idx_viaje_rider_fecha (id_rider, fecha_solicitud)

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS oferta (

    id_oferta BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    id_conductor BIGINT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_respuesta DATETIME NULL,
    estado_oferta ENUM('pendiente', 'aceptada', 'rechazada', 'expirada') DEFAULT 'pendiente' NOT NULL,
    importe_ofrecido DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (id_oferta),
    CONSTRAINT uk_oferta_viaje_conductor UNIQUE (id_viaje, id_conductor),
    CONSTRAINT fk_oferta_viaje FOREIGN KEY (id_viaje)
        REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_oferta_conductor FOREIGN KEY (id_conductor)
        REFERENCES conductor(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_oferta_importe CHECK (importe_ofrecido >= 0),

    INDEX idx_oferta_estado (estado_oferta),
    INDEX idx_oferta_viaje_conductor_estado (id_viaje, id_conductor, estado_oferta),
    INDEX idx_oferta_viaje_estado (id_viaje, estado_oferta)

) ENGINE = InnoDB;

-- 4. ECONOMIA Y VALORACIONES

CREATE TABLE IF NOT EXISTS pago (

    id_pago BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    importe_total DECIMAL(10, 2) NOT NULL,
    comision_company DECIMAL(10, 2) NOT NULL,
    importe_conductor DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM('tarjeta_credito', 'efectivo', 'wallet') DEFAULT 'tarjeta_credito' NOT NULL,
    estado_pago ENUM('pendiente', 'completado', 'fallido', 'reembolsado') DEFAULT 'pendiente' NOT NULL,
    fecha_pago DATETIME NOT NULL,

    PRIMARY KEY (id_pago),
    CONSTRAINT uk_pago_viaje UNIQUE (id_viaje),
    CONSTRAINT fk_pago_viaje FOREIGN KEY (id_viaje)
        REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pago_sumas CHECK (importe_total = comision_company + importe_conductor),
    CONSTRAINT ck_pago_total CHECK (importe_total >= 0),
    CONSTRAINT ck_pago_comision CHECK (comision_company >= 0),
    CONSTRAINT ck_pago_conductor CHECK (importe_conductor >= 0)

) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS valoracion (

    id_valoracion BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    id_usuario_valorador BIGINT NOT NULL,
    id_usuario_valorado BIGINT NOT NULL,
    rol_valorado ENUM('rider', 'conductor') NOT NULL,
    puntuacion TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario VARCHAR(255) NULL,
    fecha_valoracion DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,

    PRIMARY KEY (id_valoracion),
    CONSTRAINT fk_val_viaje FOREIGN KEY (id_viaje)
        REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorador FOREIGN KEY (id_usuario_valorador)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorado FOREIGN KEY (id_usuario_valorado)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE = InnoDB;

-- 5. AUDITORIA

CREATE TABLE IF NOT EXISTS viaje_estado_log (

    id_historial BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    estado_anterior ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') NOT NULL,
    estado_nuevo ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    comentario VARCHAR(255),

    PRIMARY KEY (id_historial),
    CONSTRAINT fk_log_viaje FOREIGN KEY (id_viaje)
        REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,

    INDEX idx_log_viaje_fecha (id_viaje, fecha_cambio)

) ENGINE = InnoDB;

-- 6. PROCEDIMIENTOS ALMACENADOS

DROP PROCEDURE IF EXISTS sp_solicitar_viaje;
DELIMITER $$

CREATE PROCEDURE sp_solicitar_viaje(
    IN p_id_rider BIGINT,
    IN p_origen_lat DECIMAL(9,6),
    IN p_origen_lng DECIMAL(9,6),
    IN p_destino_lat DECIMAL(9,6),
    IN p_destino_lng DECIMAL(9,6),
    IN p_origen_dir VARCHAR(255),
    IN p_destino_dir VARCHAR(255),
    IN p_distancia_km DECIMAL(10,2),
    OUT p_id_viaje BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_importe_base DECIMAL(10,2);
    DECLARE v_ofertas_generadas INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    INSERT INTO viaje (
        id_rider,
        estado,
        latitud_origen,
        longitud_origen,
        latitud_destino,
        longitud_destino,
        origen_direccion,
        destino_direccion,
        distancia_km,
        fecha_solicitud
    ) VALUES (
        p_id_rider,
        'solicitado',
        p_origen_lat,
        p_origen_lng,
        p_destino_lat,
        p_destino_lng,
        p_origen_dir,
        p_destino_dir,
        p_distancia_km,
        CURRENT_TIMESTAMP
    );

    SET p_id_viaje = LAST_INSERT_ID();
    SET v_importe_base = p_distancia_km * 1.50;

    INSERT INTO oferta (
        id_viaje,
        id_conductor,
        importe_ofrecido,
        estado_oferta
    )
    SELECT
        p_id_viaje,
        c.id_usuario,
        v_importe_base,
        'pendiente'
    FROM conductor c
    WHERE c.estado_conductor = 'disponible'
      AND EXISTS (
            SELECT 1
            FROM conductor_vehiculo cv
            JOIN vehiculo v ON v.id_vehiculo = cv.id_vehiculo
            WHERE cv.id_conductor = c.id_usuario
              AND cv.fecha_hasta IS NULL
              AND v.activo = TRUE
      );

    SET v_ofertas_generadas = ROW_COUNT();

    IF v_ofertas_generadas = 0 THEN
        ROLLBACK;
        SET p_id_viaje = NULL;
        SET p_resultado = 'ERROR_SIN_CONDUCTORES_DISPONIBLES';
    ELSE
        COMMIT;
        SET p_resultado = 'OK';
    END IF;
END$$

DELIMITER ;

-- Asigna el viaje al primer conductor que acepte usando bloqueos pesimistas.
DROP PROCEDURE IF EXISTS sp_aceptar_oferta;
DELIMITER $$

CREATE PROCEDURE sp_aceptar_oferta(
    IN p_id_viaje BIGINT,
    IN p_id_conductor BIGINT,
    IN p_id_vehiculo BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    DECLARE v_oferta_pendiente INT DEFAULT 0;
    DECLARE v_vehiculo_valido INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    SELECT estado
    INTO v_estado_actual
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    IF v_estado_actual <> 'solicitado' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';
    ELSE
        SELECT COUNT(*)
        INTO v_oferta_pendiente
        FROM oferta
        WHERE id_viaje = p_id_viaje
          AND id_conductor = p_id_conductor
          AND estado_oferta = 'pendiente';

        IF v_oferta_pendiente = 0 THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_OFERTA_NO_VALIDA';
        ELSE
            SELECT COUNT(*)
            INTO v_vehiculo_valido
            FROM conductor_vehiculo cv
            JOIN vehiculo v ON v.id_vehiculo = cv.id_vehiculo
            WHERE cv.id_conductor = p_id_conductor
              AND cv.id_vehiculo = p_id_vehiculo
              AND cv.fecha_hasta IS NULL
              AND v.activo = TRUE;

            IF v_vehiculo_valido = 0 THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_VEHICULO_NO_VALIDO';
            ELSE
                UPDATE viaje
                SET
                    estado = 'aceptado',
                    id_conductor = p_id_conductor,
                    id_vehiculo = p_id_vehiculo,
                    fecha_aceptacion = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje;

                UPDATE oferta
                SET
                    estado_oferta = 'aceptada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND id_conductor = p_id_conductor
                  AND estado_oferta = 'pendiente';

                UPDATE oferta
                SET
                    estado_oferta = 'expirada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND id_conductor <> p_id_conductor
                  AND estado_oferta = 'pendiente';

                UPDATE conductor
                SET estado_conductor = 'en_viaje'
                WHERE id_usuario = p_id_conductor;

                COMMIT;
                SET p_resultado = 'OK';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- Cierra el viaje, libera al conductor y liquida el pago calculando la comisión.
DROP PROCEDURE IF EXISTS sp_finalizar_viaje_y_pagar;
DELIMITER $$

CREATE PROCEDURE sp_finalizar_viaje_y_pagar(
    IN p_id_viaje BIGINT,
    IN p_metodo_pago VARCHAR(20),
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    DECLARE v_id_conductor BIGINT;
    DECLARE v_importe_ofrecido DECIMAL(10,2);
    DECLARE v_importe_total DECIMAL(10,2);
    DECLARE v_comision DECIMAL(10,2);
    DECLARE v_pago_existente INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    SELECT estado, id_conductor
    INTO v_estado_actual, v_id_conductor
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    IF v_estado_actual <> 'en_curso' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';
    ELSE
        SELECT COUNT(*)
        INTO v_pago_existente
        FROM pago
        WHERE id_viaje = p_id_viaje;

        IF v_pago_existente > 0 THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_PAGO_YA_EXISTE';
        ELSE
            SELECT importe_ofrecido
            INTO v_importe_ofrecido
            FROM oferta
            WHERE id_viaje = p_id_viaje
              AND estado_oferta = 'aceptada'
            LIMIT 1;

            IF v_importe_ofrecido IS NULL THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_SIN_OFERTA_ACEPTADA';
            ELSE
                UPDATE viaje
                SET
                    estado = 'finalizado',
                    fecha_fin = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje;

                UPDATE conductor
                SET estado_conductor = 'disponible'
                WHERE id_usuario = v_id_conductor;

                SET v_importe_total = ROUND(v_importe_ofrecido * 1.20, 2);
                SET v_comision = ROUND(v_importe_total - v_importe_ofrecido, 2);

                INSERT INTO pago (
                    id_viaje,
                    importe_total,
                    comision_company,
                    importe_conductor,
                    metodo_pago,
                    estado_pago,
                    fecha_pago
                )
                VALUES (
                    p_id_viaje,
                    v_importe_total,
                    v_comision,
                    v_importe_ofrecido,
                    p_metodo_pago,
                    'completado',
                    CURRENT_TIMESTAMP
                );

                COMMIT;
                SET p_resultado = 'OK';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- 7. TRIGGERS

DROP TRIGGER IF EXISTS tr_audit_viaje_estado;
DELIMITER $$

CREATE TRIGGER tr_audit_viaje_estado
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    IF NOT (OLD.estado <=> NEW.estado) THEN
        INSERT INTO viaje_estado_log (
            id_viaje,
            estado_anterior,
            estado_nuevo,
            comentario
        )
        VALUES (
            NEW.id_viaje,
            OLD.estado,
            NEW.estado,
            'Actualizacion de estado'
        );
    END IF;
END$$

DELIMITER ;