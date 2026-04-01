CREATE DATABASE IF NOT EXISTS ride_hailing
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE ride_hailing;

SET NAMES utf8mb4;
SET time_zone = '+00:00';

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS valoracion;
DROP TABLE IF EXISTS viaje_estado_log;
DROP TABLE IF EXISTS pago;
DROP TABLE IF EXISTS oferta;
DROP TABLE IF EXISTS viaje;
DROP TABLE IF EXISTS vehiculo;
DROP TABLE IF EXISTS conductor;
DROP TABLE IF EXISTS rider;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS company;

CREATE TABLE company (
    id_company BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    cif VARCHAR(20) NOT NULL,
    fecha_alta DATE NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_company_nombre UNIQUE (nombre),
    CONSTRAINT uq_company_cif UNIQUE (cif)
) ENGINE=InnoDB;

CREATE TABLE usuario (
    id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido1 VARCHAR(80) NOT NULL,
    apellido2 VARCHAR(80) NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_alta DATE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT uq_usuario_telefono UNIQUE (telefono)
) ENGINE=InnoDB;

CREATE TABLE rider (
    id_usuario BIGINT UNSIGNED PRIMARY KEY,
    CONSTRAINT fk_rider_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE conductor (
    id_usuario BIGINT UNSIGNED PRIMARY KEY,
    numero_licencia VARCHAR(40) NOT NULL,
    estado_conductor ENUM('disponible','en_viaje','desconectado','suspendido') NOT NULL DEFAULT 'disponible',
    fecha_alta_conductor DATE NOT NULL,
    id_company BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_conductor_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_conductor_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_conductor_company
        FOREIGN KEY (id_company) REFERENCES company(id_company)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vehiculo (
    id_vehiculo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_company BIGINT UNSIGNED NOT NULL,
    id_conductor BIGINT UNSIGNED NULL,
    matricula VARCHAR(20) NOT NULL,
    marca VARCHAR(60) NOT NULL,
    modelo VARCHAR(60) NOT NULL,
    color VARCHAR(40) NOT NULL,
    anio INT NOT NULL,
    capacidad INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_vehiculo_matricula UNIQUE (matricula),
    CONSTRAINT chk_vehiculo_anio CHECK (anio BETWEEN 2000 AND 2100),
    CONSTRAINT chk_vehiculo_capacidad CHECK (capacidad BETWEEN 1 AND 9),
    CONSTRAINT fk_vehiculo_company
        FOREIGN KEY (id_company) REFERENCES company(id_company)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_vehiculo_conductor
        FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE viaje (
    id_viaje BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_rider BIGINT UNSIGNED NOT NULL,
    id_conductor BIGINT UNSIGNED NULL,
    id_vehiculo BIGINT UNSIGNED NULL,
    estado ENUM('solicitado','aceptado','en_curso','finalizado','cancelado') NOT NULL DEFAULT 'solicitado',
    fecha_solicitud DATETIME NOT NULL,
    fecha_aceptacion DATETIME NULL,
    fecha_inicio DATETIME NULL,
    fecha_fin DATETIME NULL,
    origen_lat DECIMAL(10,7) NOT NULL,
    origen_lng DECIMAL(10,7) NOT NULL,
    origen_direccion VARCHAR(255) NOT NULL,
    destino_lat DECIMAL(10,7) NOT NULL,
    destino_lng DECIMAL(10,7) NOT NULL,
    destino_direccion VARCHAR(255) NOT NULL,
    distancia_km DECIMAL(8,2) NULL,
    duracion_min DECIMAL(8,2) NULL,
    cancelado_por VARCHAR(20) NULL,
    motivo_cancelacion VARCHAR(255) NULL,
    id_oferta_aceptada BIGINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_viaje_cancelado_por CHECK (cancelado_por IN ('rider','conductor','company','sistema') OR cancelado_por IS NULL),
    CONSTRAINT fk_viaje_rider
        FOREIGN KEY (id_rider) REFERENCES rider(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_viaje_conductor
        FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_viaje_vehiculo
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE oferta (
    id_oferta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT UNSIGNED NOT NULL,
    id_conductor BIGINT UNSIGNED NOT NULL,
    fecha_envio DATETIME NOT NULL,
    fecha_respuesta DATETIME NULL,
    estado_oferta ENUM('pendiente','aceptada','rechazada','expirada') NOT NULL DEFAULT 'pendiente',
    importe_ofrecido DECIMAL(10,2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_oferta_viaje_conductor UNIQUE (id_viaje, id_conductor),
    CONSTRAINT fk_oferta_viaje
        FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_oferta_conductor
        FOREIGN KEY (id_conductor) REFERENCES conductor(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

ALTER TABLE viaje
ADD CONSTRAINT fk_viaje_oferta_aceptada
FOREIGN KEY (id_oferta_aceptada) REFERENCES oferta(id_oferta)
ON DELETE SET NULL
ON UPDATE CASCADE;

CREATE TABLE pago (
    id_pago BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT UNSIGNED NOT NULL,
    importe_total DECIMAL(10,2) NOT NULL,
    comision_company DECIMAL(10,2) NOT NULL,
    importe_conductor DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    estado_pago ENUM('pendiente','completado','fallido','reembolsado') NOT NULL DEFAULT 'pendiente',
    fecha_pago DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_pago_viaje UNIQUE (id_viaje),
    CONSTRAINT chk_pago_importes CHECK (
        importe_total >= 0 AND
        comision_company >= 0 AND
        importe_conductor >= 0
    ),
    CONSTRAINT fk_pago_viaje
        FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE viaje_estado_log (
    id_historial BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT UNSIGNED NOT NULL,
    estado_anterior ENUM('solicitado','aceptado','en_curso','finalizado','cancelado') NULL,
    estado_nuevo ENUM('solicitado','aceptado','en_curso','finalizado','cancelado') NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_usuario_actor BIGINT UNSIGNED NULL,
    comentario VARCHAR(255) NULL,
    CONSTRAINT fk_viaje_estado_log_viaje
        FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_viaje_estado_log_usuario
        FOREIGN KEY (id_usuario_actor) REFERENCES usuario(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE valoracion (
    id_valoracion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_viaje BIGINT UNSIGNED NOT NULL,
    id_usuario_valorador BIGINT UNSIGNED NOT NULL,
    id_usuario_valorado BIGINT UNSIGNED NOT NULL,
    rol_valorado ENUM('rider','conductor') NOT NULL,
    puntuacion INT NOT NULL,
    comentario VARCHAR(255) NULL,
    fecha_valoracion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_valoracion_puntuacion CHECK (puntuacion BETWEEN 1 AND 5),
    CONSTRAINT uq_valoracion_unica UNIQUE (id_viaje, id_usuario_valorador, id_usuario_valorado),
    CONSTRAINT fk_valoracion_viaje
        FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_valoracion_usuario_valorador
        FOREIGN KEY (id_usuario_valorador) REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_valoracion_usuario_valorado
        FOREIGN KEY (id_usuario_valorado) REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE audit_log (
    id_audit BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(64) NOT NULL,
    id_registro BIGINT UNSIGNED NULL,
    accion ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    detalle VARCHAR(500) NULL,
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

CREATE INDEX idx_conductor_company ON conductor(id_company);
CREATE INDEX idx_vehiculo_company ON vehiculo(id_company);
CREATE INDEX idx_vehiculo_conductor ON vehiculo(id_conductor);

CREATE INDEX idx_viaje_rider_fecha ON viaje(id_rider, fecha_solicitud);
CREATE INDEX idx_viaje_conductor_fecha ON viaje(id_conductor, fecha_solicitud);
CREATE INDEX idx_viaje_estado_fecha ON viaje(estado, fecha_solicitud);
CREATE INDEX idx_viaje_fechas_operativas ON viaje(fecha_solicitud, fecha_inicio, fecha_fin);

CREATE INDEX idx_oferta_viaje_estado ON oferta(id_viaje, estado_oferta);
CREATE INDEX idx_oferta_conductor_estado ON oferta(id_conductor, estado_oferta);
CREATE INDEX idx_oferta_fecha_envio ON oferta(fecha_envio);

CREATE INDEX idx_pago_estado_fecha ON pago(estado_pago, fecha_pago);
CREATE INDEX idx_viaje_estado_log_viaje_fecha ON viaje_estado_log(id_viaje, fecha_cambio);
CREATE INDEX idx_valoracion_viaje ON valoracion(id_viaje);
CREATE INDEX idx_audit_tabla_fecha ON audit_log(tabla_afectada, fecha_evento);