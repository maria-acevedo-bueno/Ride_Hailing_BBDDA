-- =========================================================
-- CONFIGURACION DEL ESQUEMA OPERATIVO
-- =========================================================
-- Se elimina la base de datos previa para reconstruir el entorno
-- desde cero en cada carga del esquema.
DROP DATABASE IF EXISTS ride_hailing;

-- Se crea la base de datos principal del proyecto.
CREATE DATABASE ride_hailing;

-- A partir de aquí todas las sentencias se ejecutan sobre esta base.
USE ride_hailing;

-- =========================================================
-- 1. TABLAS MAESTRAS Y COMPANIES
-- =========================================================

-- Tabla company:
-- almacena las empresas o flotas que operan en la plataforma.
-- Cada conductor y cada vehículo pertenecen a una company.
-- Se usa una restricción UNIQUE sobre cif para evitar duplicados.
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

-- Tabla usuario:
-- almacena la información común de cualquier persona registrada en el sistema.
-- Esta tabla centraliza los atributos personales básicos para evitar duplicidad.
-- A partir de esta tabla se especializan riders y conductores.
-- También se obliga a que email y teléfono sean únicos dentro del sistema.
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

-- =========================================================
-- 2. ESPECIALIZACION DE USUARIOS
-- =========================================================

-- Tabla rider:
-- especializa a un usuario como cliente que solicita viajes.
-- Su clave primaria es también clave foránea a usuario.
-- Esto obliga a que un rider no pueda existir sin un usuario base.
CREATE TABLE IF NOT EXISTS rider (

    id_usuario BIGINT NOT NULL,

    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_rider_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT

) ENGINE = InnoDB;

-- Tabla conductor:
-- especializa a un usuario como conductor.
-- Guarda su licencia, su estado operativo y la empresa a la que pertenece.
-- El estado_conductor ayuda a controlar si puede recibir ofertas o no.
-- Se indexa id_company para búsquedas por empresa y estado_conductor
-- para búsquedas operativas frecuentes.
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

-- =========================================================
-- 3. GESTION DE FLOTA Y VIAJES
-- =========================================================

-- Tabla vehiculo:
-- almacena los vehículos gestionados por cada company.
-- Un vehículo puede ser asignado a diferentes conductores a lo largo del tiempo.
-- La matrícula se define como única porque identifica de forma natural al vehículo.
-- capacidad > 0 evita datos imposibles o incoherentes.
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

-- Tabla conductor_vehiculo:
-- resuelve la relación N:N entre conductores y vehículos.
-- Permite registrar asignaciones históricas y saber cuál está vigente.
-- Si fecha_hasta es NULL, la asignación sigue activa.
-- La PK compuesta impide duplicar exactamente la misma asignación temporal.
-- Los índices con fecha_hasta ayudan a localizar asignaciones actuales.
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

-- Tabla viaje:
-- representa el ciclo de vida completo de un trayecto.
-- Empieza solicitado, puede ser aceptado, iniciado, finalizado o cancelado.
-- Guarda rider, conductor, vehículo, tiempos y datos de origen y destino.
-- id_conductor e id_vehiculo se permiten NULL al inicio porque un viaje
-- puede existir antes de que alguien lo acepte.
-- Se añaden CHECK para validar coordenadas geográficas y distancia.
-- Los índices responden a las consultas más probables del sistema:
-- por estado, por conductor y por rider.
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

-- Tabla oferta:
-- registra las ofertas enviadas a los conductores para un viaje.
-- Para un mismo viaje se pueden generar varias ofertas, pero solo una termina aceptada.
-- La restricción UNIQUE evita que el mismo conductor reciba dos veces el mismo viaje.
-- Los índices están pensados para consultas por estado, por viaje y por conductor.
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
    INDEX idx_oferta_viaje_estado (id_viaje, estado_oferta),
    INDEX idx_oferta_conductor_estado (id_conductor, estado_oferta)

) ENGINE = InnoDB;

-- =========================================================
-- 4. ECONOMIA Y VALORACIONES
-- =========================================================

-- Tabla pago:
-- guarda la liquidación económica final de un viaje.
-- Cada viaje puede tener como máximo un pago asociado.
-- El CHECK principal garantiza consistencia contable:
-- total = comisión + importe del conductor.
-- Se usa tolerancia con ABS(... ) < 0.01 para evitar problemas de redondeo.
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
    CONSTRAINT ck_pago_sumas CHECK (
        ABS(importe_total - (comision_company + importe_conductor)) < 0.01
    ),
    CONSTRAINT ck_pago_total CHECK (importe_total >= 0),
    CONSTRAINT ck_pago_comision CHECK (comision_company >= 0),
    CONSTRAINT ck_pago_conductor CHECK (importe_conductor >= 0),

    INDEX idx_pago_estado_fecha (estado_pago, fecha_pago)

) ENGINE = InnoDB;

-- Tabla valoracion:
-- almacena las valoraciones emitidas por los usuarios al finalizar un viaje.
-- Permite valorar tanto al rider como al conductor.
-- La puntuación se restringe entre 1 y 5.
-- Se indexa el usuario valorado para explotar métricas y rankings.
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
        REFERENCES usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,

    INDEX idx_valoracion_valorado_fecha (id_usuario_valorado, fecha_valoracion)

) ENGINE = InnoDB;

-- =========================================================
-- 5. AUDITORIA
-- =========================================================

-- Tabla viaje_estado_log:
-- almacena el historial de cambios de estado de los viajes.
-- Se alimenta automáticamente mediante un trigger de auditoría.
-- Sirve tanto para trazabilidad funcional como para análisis posteriores.
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

-- =========================================================
-- 6. PROCEDIMIENTOS ALMACENADOS
-- =========================================================

DROP PROCEDURE IF EXISTS sp_solicitar_viaje;
DELIMITER $$

-- Procedimiento sp_solicitar_viaje:
-- crea un viaje nuevo y genera automáticamente ofertas para
-- los conductores disponibles con vehículo activo y asignación vigente.
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
    -- Importe base calculado a partir de la distancia.
    DECLARE v_importe_base DECIMAL(10,2);
    -- Número de ofertas finalmente generadas.
    DECLARE v_ofertas_generadas INT DEFAULT 0;
    -- Controla si el rider existe y está activo.
    DECLARE v_rider_valido INT DEFAULT 0;

    -- Cualquier error SQL cancela la transacción completa.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Paso 1:
    -- Comprobar que el rider existe y está activo.
    -- Se bloquea para mantener consistencia durante la operación.
    SELECT COUNT(*)
    INTO v_rider_valido
    FROM rider r
    JOIN usuario u ON u.id_usuario = r.id_usuario
    WHERE r.id_usuario = p_id_rider
      AND u.activo = TRUE
    FOR UPDATE;

    -- Paso 2:
    -- Si no existe o no está activo, no se crea el viaje.
    IF v_rider_valido = 0 THEN
        ROLLBACK;
        SET p_id_viaje = NULL;
        SET p_resultado = 'ERROR_RIDER_NO_VALIDO';
    ELSE
        -- Paso 3:
        -- Insertar el viaje en estado solicitado.
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

        -- Paso 4:
        -- Recuperar el id del viaje recién creado.
        SET p_id_viaje = LAST_INSERT_ID();

        -- Paso 5:
        -- Calcular el importe base de la oferta.
        SET v_importe_base = p_distancia_km * 1.50;

        -- Paso 6:
        -- Generar ofertas para conductores disponibles que tengan:
        -- asignación vigente con un vehículo activo
        -- y coherencia de company entre conductor y vehículo.
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
                  AND v.id_company = c.id_company
          );

        -- Paso 7:
        -- Guardar cuántas ofertas se han insertado.
        SET v_ofertas_generadas = ROW_COUNT();

        -- Paso 8:
        -- Si no se generó ninguna oferta, se deshace el viaje.
        IF v_ofertas_generadas = 0 THEN
            ROLLBACK;
            SET p_id_viaje = NULL;
            SET p_resultado = 'ERROR_SIN_CONDUCTORES_DISPONIBLES';
        ELSE
            -- Paso 9:
            -- Confirmar viaje + ofertas en bloque.
            COMMIT;
            SET p_resultado = 'OK';
        END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_aceptar_oferta;
DELIMITER $$

-- Procedimiento sp_aceptar_oferta:
-- asigna el viaje al primer conductor que acepta correctamente.
-- Usa bloqueo pesimista sobre el viaje para evitar dobles aceptaciones.
CREATE PROCEDURE sp_aceptar_oferta(
    IN p_id_viaje BIGINT,
    IN p_id_conductor BIGINT,
    IN p_id_vehiculo BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_oferta BIGINT DEFAULT NULL;
    DECLARE v_vehiculo_valido INT DEFAULT 0;
    DECLARE v_viaje_encontrado BOOLEAN DEFAULT TRUE;
    DECLARE v_oferta_encontrada BOOLEAN DEFAULT TRUE;

    -- Si un SELECT ... INTO no devuelve filas, se controla aquí.
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        IF v_estado_actual IS NULL THEN
            SET v_viaje_encontrado = FALSE;
        ELSE
            SET v_oferta_encontrada = FALSE;
        END IF;
    END;

    -- Cualquier error SQL provoca rollback completo.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Paso 1:
    -- Bloquear el viaje. Solo una sesión podrá aceptarlo.
    SELECT estado
    INTO v_estado_actual
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Paso 2:
    -- Si el viaje no existe, terminar con error controlado.
    IF v_viaje_encontrado = FALSE THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Paso 3:
    -- Solo se puede aceptar un viaje en estado solicitado.
    ELSEIF v_estado_actual <> 'solicitado' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    ELSE
        -- Paso 4:
        -- Buscar y bloquear la oferta pendiente de ese conductor.
        SELECT id_oferta
        INTO v_id_oferta
        FROM oferta
        WHERE id_viaje = p_id_viaje
          AND id_conductor = p_id_conductor
          AND estado_oferta = 'pendiente'
        FOR UPDATE;

        -- Paso 5:
        -- Si no existe oferta pendiente, abortar.
        IF v_oferta_encontrada = FALSE OR v_id_oferta IS NULL THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_OFERTA_NO_PENDIENTE';

        ELSE
            -- Paso 6:
            -- Validar vehículo y asignación vigente.
            -- También se comprueba que el conductor siga disponible.
            SELECT COUNT(*)
            INTO v_vehiculo_valido
            FROM conductor_vehiculo cv
            JOIN vehiculo v
                ON v.id_vehiculo = cv.id_vehiculo
            JOIN conductor c
                ON c.id_usuario = cv.id_conductor
            WHERE cv.id_conductor = p_id_conductor
              AND cv.id_vehiculo = p_id_vehiculo
              AND cv.fecha_hasta IS NULL
              AND v.activo = TRUE
              AND v.id_company = c.id_company
              AND c.estado_conductor = 'disponible'
            FOR UPDATE;

            -- Paso 7:
            -- Si el vehículo no es válido, abortar.
            IF v_vehiculo_valido = 0 THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_VEHICULO_NO_VALIDO';

            ELSE
                -- Paso 8:
                -- Asignar el viaje al conductor ganador.
                UPDATE viaje
                SET
                    estado = 'aceptado',
                    id_conductor = p_id_conductor,
                    id_vehiculo = p_id_vehiculo,
                    fecha_aceptacion = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND estado = 'solicitado';

                -- Paso 9:
                -- Marcar su oferta como aceptada.
                UPDATE oferta
                SET
                    estado_oferta = 'aceptada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_oferta = v_id_oferta;

                -- Paso 10:
                -- Expirar el resto de ofertas pendientes del mismo viaje.
                UPDATE oferta
                SET
                    estado_oferta = 'expirada',
                    fecha_respuesta = CURRENT_TIMESTAMP
                WHERE id_viaje = p_id_viaje
                  AND id_oferta <> v_id_oferta
                  AND estado_oferta = 'pendiente';

                -- Paso 11:
                -- Cambiar el conductor a estado en_viaje.
                UPDATE conductor
                SET estado_conductor = 'en_viaje'
                WHERE id_usuario = p_id_conductor;

                -- Paso 12:
                -- Confirmar todos los cambios juntos.
                COMMIT;
                SET p_resultado = 'OK';
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_iniciar_viaje;
DELIMITER $$

-- Procedimiento sp_iniciar_viaje:
-- cambia un viaje aceptado a en_curso y registra fecha_inicio.
CREATE PROCEDURE sp_iniciar_viaje(
    IN p_id_viaje BIGINT,
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_conductor BIGINT DEFAULT NULL;
    DECLARE v_id_vehiculo BIGINT DEFAULT NULL;
    DECLARE v_viaje_encontrado BOOLEAN DEFAULT TRUE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_viaje_encontrado = FALSE;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Paso 1:
    -- Bloquear el viaje antes de cambiar su estado.
    SELECT estado, id_conductor, id_vehiculo
    INTO v_estado_actual, v_id_conductor, v_id_vehiculo
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Paso 2:
    -- Validar existencia.
    IF v_viaje_encontrado = FALSE THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Paso 3:
    -- Solo puede iniciarse si ya fue aceptado.
    ELSEIF v_estado_actual <> 'aceptado' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    -- Paso 4:
    -- Debe tener conductor y vehículo asignados.
    ELSEIF v_id_conductor IS NULL OR v_id_vehiculo IS NULL THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_SIN_ASIGNACION';

    ELSE
        -- Paso 5:
        -- Marcar el viaje como en curso.
        UPDATE viaje
        SET
            estado = 'en_curso',
            fecha_inicio = CURRENT_TIMESTAMP
        WHERE id_viaje = p_id_viaje;

        -- Paso 6:
        -- Confirmar la transición.
        COMMIT;
        SET p_resultado = 'OK';
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_finalizar_viaje_y_pagar;
DELIMITER $$

-- Procedimiento sp_finalizar_viaje_y_pagar:
-- cierra el viaje, libera al conductor y genera el pago final.
CREATE PROCEDURE sp_finalizar_viaje_y_pagar(
    IN p_id_viaje BIGINT,
    IN p_metodo_pago VARCHAR(20),
    OUT p_resultado VARCHAR(50)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(20) DEFAULT NULL;
    DECLARE v_id_conductor BIGINT DEFAULT NULL;
    DECLARE v_importe_ofrecido DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_importe_total DECIMAL(10,2);
    DECLARE v_comision DECIMAL(10,2);
    DECLARE v_pago_existente INT DEFAULT 0;
    DECLARE v_metodo_pago_valido INT DEFAULT 0;
    DECLARE v_viaje_encontrado BOOLEAN DEFAULT TRUE;
    DECLARE v_oferta_encontrada BOOLEAN DEFAULT TRUE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        IF v_estado_actual IS NULL THEN
            SET v_viaje_encontrado = FALSE;
        ELSE
            SET v_oferta_encontrada = FALSE;
        END IF;
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR_TRANSACCION';
    END;

    START TRANSACTION;

    -- Paso 1:
    -- Bloquear el viaje y recuperar estado y conductor.
    SELECT estado, id_conductor
    INTO v_estado_actual, v_id_conductor
    FROM viaje
    WHERE id_viaje = p_id_viaje
    FOR UPDATE;

    -- Paso 2:
    -- Validar existencia.
    IF v_viaje_encontrado = FALSE THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_VIAJE_NO_EXISTE';

    -- Paso 3:
    -- Solo puede finalizarse un viaje en curso.
    ELSEIF v_estado_actual <> 'en_curso' THEN
        ROLLBACK;
        SET p_resultado = 'ERROR_ESTADO_NO_VALIDO';

    ELSE
        -- Paso 4:
        -- Validar método de pago dentro del dominio permitido.
        SET v_metodo_pago_valido = (
            p_metodo_pago IN ('tarjeta_credito', 'efectivo', 'wallet')
        );

        IF v_metodo_pago_valido = 0 THEN
            ROLLBACK;
            SET p_resultado = 'ERROR_METODO_PAGO_NO_VALIDO';

        ELSE
            -- Paso 5:
            -- Asegurar que no existe ya un pago para ese viaje.
            SELECT COUNT(*)
            INTO v_pago_existente
            FROM pago
            WHERE id_viaje = p_id_viaje
            FOR UPDATE;

            IF v_pago_existente > 0 THEN
                ROLLBACK;
                SET p_resultado = 'ERROR_PAGO_YA_EXISTE';

            ELSE
                -- Paso 6:
                -- Recuperar la oferta aceptada, base del pago.
                SELECT importe_ofrecido
                INTO v_importe_ofrecido
                FROM oferta
                WHERE id_viaje = p_id_viaje
                  AND estado_oferta = 'aceptada'
                LIMIT 1
                FOR UPDATE;

                -- Paso 7:
                -- Si no hay oferta aceptada, no se puede liquidar.
                IF v_oferta_encontrada = FALSE OR v_importe_ofrecido IS NULL THEN
                    ROLLBACK;
                    SET p_resultado = 'ERROR_SIN_OFERTA_ACEPTADA';

                ELSE
                    -- Paso 8:
                    -- Finalizar el viaje.
                    UPDATE viaje
                    SET
                        estado = 'finalizado',
                        fecha_fin = CURRENT_TIMESTAMP
                    WHERE id_viaje = p_id_viaje;

                    -- Paso 9:
                    -- Liberar al conductor.
                    UPDATE conductor
                    SET estado_conductor = 'disponible'
                    WHERE id_usuario = v_id_conductor;

                    -- Paso 10:
                    -- Calcular total y comisión.
                    SET v_importe_total = ROUND(v_importe_ofrecido * 1.20, 2);
                    SET v_comision = ROUND(v_importe_total - v_importe_ofrecido, 2);

                    -- Paso 11:
                    -- Insertar el pago.
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

                    -- Paso 12:
                    -- Confirmar todo en bloque.
                    COMMIT;
                    SET p_resultado = 'OK';
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- 7. TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS tr_audit_viaje_estado;
DELIMITER $$

-- Trigger tr_audit_viaje_estado:
-- registra automáticamente en viaje_estado_log cualquier cambio real
-- de estado que sufra un viaje.
CREATE TRIGGER tr_audit_viaje_estado
AFTER UPDATE ON viaje
FOR EACH ROW
BEGIN
    -- Paso 1:
    -- Comprobar si el estado ha cambiado de verdad.
    -- Se usa <=> para comparar de forma segura incluso con NULL.
    IF NOT (OLD.estado <=> NEW.estado) THEN
        -- Paso 2:
        -- Insertar el cambio en el historial.
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