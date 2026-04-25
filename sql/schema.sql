-- CONFIGURACION DEL ESQUEMA OPERATIVO
DROP DATABASE IF EXISTS ride_hailing;
CREATE DATABASE IF NOT EXISTS ride_hailing;
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

) ENGINE=InnoDB;

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

) ENGINE=InnoDB;

-- 2. ESPECIALIZACION DE USUARIOS

CREATE TABLE IF NOT EXISTS rider (

    id_usuario BIGINT NOT NULL,

    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_rider_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE=InnoDB;

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

) ENGINE=InnoDB;

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

    INDEX idx_vehiculo_company (id_company)

) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS conductor_vehiculo (
    id_conductor BIGINT NOT NULL,
    id_vehiculo BIGINT NOT NULL,
    fecha_desde DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_hasta DATETIME NULL, -- Si es NULL, la asignación está vigente

    PRIMARY KEY (id_conductor, id_vehiculo, fecha_desde),
    
    CONSTRAINT fk_cv_conductor FOREIGN KEY (id_conductor) 
        REFERENCES conductor(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cv_vehiculo FOREIGN KEY (id_vehiculo) 
        REFERENCES vehiculo(id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE=InnoDB;

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
    CONSTRAINT fk_viaje_rider FOREIGN KEY (id_rider) REFERENCES rider(id_usuario),
    CONSTRAINT fk_viaje_conductor FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario),
    CONSTRAINT fk_viaje_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo),

    INDEX idx_viaje_estado_fecha (estado, fecha_solicitud),
    INDEX idx_viaje_conductor_fecha (id_conductor, fecha_solicitud),
    INDEX idx_viaje_rider_fecha (id_rider, fecha_solicitud)

) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS oferta (

    id_oferta BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    id_conductor BIGINT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_respuesta DATETIME,
    estado_oferta ENUM('pendiente', 'aceptada', 'rechazada', 'expirada') DEFAULT 'pendiente' NOT NULL,
    importe_ofrecido DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (id_oferta),
    CONSTRAINT uk_oferta_viaje_conductor UNIQUE (id_viaje, id_conductor),
    CONSTRAINT fk_oferta_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_oferta_conductor FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    
    INDEX idx_oferta_estado (estado_oferta)

) ENGINE=InnoDB;

-- 4. ECONOMIA Y VALORACIONES

CREATE TABLE IF NOT EXISTS pago (

    id_pago BIGINT NOT NULL AUTO_INCREMENT ,
    id_viaje BIGINT NOT NULL,
    importe_total DECIMAL(10, 2) NOT NULL,
    comision_company DECIMAL(10, 2) NOT NULL,
    importe_conductor DECIMAL(10, 2) NOT NULL,
    metodo_pago ENUM('tarjeta_credito', 'efectivo', 'wallet') DEFAULT 'tarjeta_credito' NOT NULL,
    estado_pago ENUM('pendiente', 'completado', 'fallido', 'reembolsado') DEFAULT 'pendiente' NOT NULL,
    fecha_pago DATETIME NOT NULL,

    PRIMARY KEY (id_pago),
    CONSTRAINT uk_pago_viaje UNIQUE (id_viaje),
    CONSTRAINT fk_pago_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pago_sumas CHECK (importe_total = comision_company + importe_conductor)

) ENGINE=InnoDB;

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
    CONSTRAINT fk_val_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorador FOREIGN KEY (id_usuario_valorador) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_val_valorado FOREIGN KEY (id_usuario_valorado) REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE=InnoDB;

-- 5. AUDITORIA

CREATE TABLE IF NOT EXISTS viaje_estado_log (

    id_historial BIGINT NOT NULL AUTO_INCREMENT,
    id_viaje BIGINT NOT NULL,
    estado_anterior ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') NOT NULL,
    estado_nuevo ENUM('solicitado', 'aceptado', 'en_curso', 'finalizado', 'cancelado') NOT NULL,
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    comentario VARCHAR(255),

    PRIMARY KEY (id_historial, fecha_cambio),
    CONSTRAINT fk_log_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,

    INDEX idx_log_viaje_fecha (id_viaje, fecha_cambio)

) ENGINE=InnoDB;

-- 6. PROCEDIMIENTOS ALMACENADOS

DELIMITER $$

-- Crea un viaje y genera ofertas para los conductores disponibles mediante un cursor.
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
    DECLARE v_id_conductor BIGINT;
    DECLARE fin BOOLEAN DEFAULT FALSE;
    
    -- Cursor para extraer únicamente a los conductores libres
    DECLARE cur_conductores CURSOR FOR 
        SELECT id_usuario FROM conductor WHERE estado_conductor = 'disponible';
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = TRUE;
    
    -- Si algo falla, deshacemos todo para no dejar datos a medias
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Registramos el viaje inicial
    INSERT INTO viaje (
        id_rider, estado, latitud_origen, longitud_origen, latitud_destino, longitud_destino, 
        origen_direccion, destino_direccion, distancia_km, fecha_solicitud
    ) VALUES (
        p_id_rider, 'solicitado', p_origen_lat, p_origen_lng, p_destino_lat, p_destino_lng, 
        p_origen_dir, p_destino_dir, p_distancia_km, CURRENT_TIMESTAMP
    );
    
    -- Recuperamos el ID autogenerado y calculamos un precio base inicial
    SET p_id_viaje = LAST_INSERT_ID();
    SET v_importe_base = p_distancia_km * 1.50;

    -- Recorremos los conductores libres para crearles una oferta pendiente a cada uno
    OPEN cur_conductores;
    
    bucle_ofertas: LOOP
        FETCH cur_conductores INTO v_id_conductor;
        IF fin THEN 
            LEAVE bucle_ofertas; 
        END IF;
        
        INSERT INTO oferta (id_viaje, id_conductor, importe_ofrecido, estado_oferta)
        VALUES (p_id_viaje, v_id_conductor, v_importe_base, 'pendiente');
    END LOOP;
    
    CLOSE cur_conductores;

    SET p_resultado = 'OK';
    COMMIT;
END$$

-- Asigna el viaje al primer conductor que acepte usando bloqueos pesimistas.
CREATE PROCEDURE sp_aceptar_oferta(
    IN p_id_viaje BIGINT,
    IN p_id_conductor BIGINT,
    IN p_id_vehiculo BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;
    
    -- Bloqueamos la fila del viaje. Si dos conductores intentan aceptar al mismo tiempo, 
    -- el segundo se queda en espera aquí hasta que el primero termine.
    SELECT estado INTO v_estado_actual 
    FROM viaje 
    WHERE id_viaje = p_id_viaje 
    FOR UPDATE;
    
    -- Solo continuamos si nadie más se nos ha adelantado
    IF v_estado_actual = 'solicitado' THEN
        
        -- Asignamos el viaje al ganador
        UPDATE viaje SET 
            estado = 'aceptado', 
            id_conductor = p_id_conductor, 
            id_vehiculo = p_id_vehiculo,
            fecha_aceptacion = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje;
        
        -- Marcamos su oferta como aceptada
        UPDATE oferta SET 
            estado_oferta = 'aceptada', 
            fecha_respuesta = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje AND id_conductor = p_id_conductor;
        
        -- Cancelamos las ofertas del resto de conductores para este mismo viaje
        UPDATE oferta SET estado_oferta = 'expirada'
        WHERE id_viaje = p_id_viaje AND id_conductor <> p_id_conductor AND estado_oferta = 'pendiente';
        
        -- Marcamos al conductor ganador como ocupado
        UPDATE conductor SET estado_conductor = 'en_viaje' WHERE id_usuario = p_id_conductor;
        
        SET p_resultado = 'OK';
        COMMIT;
    ELSE
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';
        ROLLBACK;
    END IF;
END$$

-- Cierra el viaje, libera al conductor y liquida el pago calculando la comisión.
CREATE PROCEDURE sp_finalizar_viaje_y_pagar(
    IN p_id_viaje BIGINT,
    IN p_metodo_pago VARCHAR(50),
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20);
    DECLARE v_id_conductor BIGINT;
    DECLARE v_importe_ofrecido DECIMAL(10,2);
    DECLARE v_importe_total DECIMAL(10,2);
    DECLARE v_comision DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;
    
    -- Bloqueamos el viaje antes de operar
    SELECT estado, id_conductor INTO v_estado_actual, v_id_conductor 
    FROM viaje WHERE id_viaje = p_id_viaje FOR UPDATE;
    
    IF v_estado_actual = 'en_curso' THEN
        
        -- Finalizamos el viaje y volvemos a poner al conductor disponible
        UPDATE viaje SET estado = 'finalizado', fecha_fin = CURRENT_TIMESTAMP WHERE id_viaje = p_id_viaje;
        UPDATE conductor SET estado_conductor = 'disponible' WHERE id_usuario = v_id_conductor;
        
        -- Recuperamos el importe base que se acordó
        SELECT importe_ofrecido INTO v_importe_ofrecido 
        FROM oferta WHERE id_viaje = p_id_viaje AND estado_oferta = 'aceptada' LIMIT 1;
        
        -- Aplicamos el 20% de margen de la plataforma
        SET v_importe_total = v_importe_ofrecido * 1.20;
        SET v_comision = v_importe_total - v_importe_ofrecido;
        
        -- Guardamos el recibo
        INSERT INTO pago (id_viaje, importe_total, comision_company, importe_conductor, metodo_pago, estado_pago, fecha_pago)
        VALUES (p_id_viaje, v_importe_total, v_comision, v_importe_ofrecido, p_metodo_pago, 'completado', CURRENT_TIMESTAMP);
        
        SET p_resultado = 'OK';
        COMMIT;
    ELSE
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';
        ROLLBACK;
    END IF;
END$$

-- 7. TRIGGERS

-- Registra de forma automática cualquier cambio de estado en los viajes
CREATE TRIGGER tr_audit_viaje_estado
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    -- Comprobamos si el estado realmente ha cambiado usando <=> para evitar problemas con nulos
    IF NOT (OLD.estado <=> NEW.estado) THEN
        INSERT INTO viaje_estado_log (id_viaje, estado_anterior, estado_nuevo, comentario)
        VALUES (NEW.id_viaje, OLD.estado, NEW.estado, 'Actualizacion de estado');
    END IF;
END$$

DELIMITER ;