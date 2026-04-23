DROP DATABASE IF EXISTS cabify;

CREATE DATABASE cabify;

USE cabify;

CREATE TABLE cabify.company (
    id_company INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(120) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_company),
    UNIQUE KEY uk_company_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE cabify.rider (
    id_rider INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_rider),
    UNIQUE KEY uk_rider_email (email)
) ENGINE = InnoDB;

CREATE TABLE cabify.conductor (
    id_conductor INT NOT NULL AUTO_INCREMENT,
    id_company INT NOT NULL,
    dni VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_conductor),
    UNIQUE KEY uk_conductor_dni (dni),
    UNIQUE KEY uk_conductor_email (email),
    KEY idx_conductor_company (id_company),
    CONSTRAINT fk_conductor_company FOREIGN KEY (id_company) REFERENCES cabify.company (id_company) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE cabify.vehiculo (
    id_vehiculo INT NOT NULL AUTO_INCREMENT,
    id_conductor INT NOT NULL,
    matricula VARCHAR(16) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    color VARCHAR(30),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_vehiculo),
    UNIQUE KEY uk_vehiculo_matricula (matricula),
    KEY idx_vehiculo_conductor (id_conductor),
    CONSTRAINT fk_vehiculo_conductor FOREIGN KEY (id_conductor) REFERENCES cabify.conductor (id_conductor) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE cabify.viaje (
    id_viaje INT NOT NULL AUTO_INCREMENT,
    id_rider INT NOT NULL,
    id_conductor INT NULL,
    origen_latitud DECIMAL(9, 6) NOT NULL,
    origen_longitud DECIMAL(9, 6) NOT NULL,
    destino_latitud DECIMAL(9, 6) NOT NULL,
    destino_longitud DECIMAL(9, 6) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'solicitado',
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_inicio DATETIME NULL,
    fecha_fin DATETIME NULL,
    distancia_km DECIMAL(10, 2) NULL,
    duracion_minutos DECIMAL(10, 2) NULL,
    importe_total DECIMAL(10, 2) NULL,
    PRIMARY KEY (id_viaje),
    KEY idx_viaje_rider (id_rider),
    KEY idx_viaje_conductor (id_conductor),
    KEY idx_viaje_estado_fecha (estado, fecha_solicitud),
    CONSTRAINT fk_viaje_rider FOREIGN KEY (id_rider) REFERENCES cabify.rider (id_rider) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_viaje_conductor FOREIGN KEY (id_conductor) REFERENCES cabify.conductor (id_conductor) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_viaje_estado CHECK (
        estado IN (
            'solicitado',
            'aceptado',
            'en_curso',
            'finalizado',
            'cancelado'
        )
    ),
    CONSTRAINT chk_viaje_origen_latitud CHECK (
        origen_latitud BETWEEN -90 AND 90
    ),
    CONSTRAINT chk_viaje_origen_longitud CHECK (
        origen_longitud BETWEEN -180 AND 180
    ),
    CONSTRAINT chk_viaje_destino_latitud CHECK (
        destino_latitud BETWEEN -90 AND 90
    ),
    CONSTRAINT chk_viaje_destino_longitud CHECK (
        destino_longitud BETWEEN -180 AND 180
    ),
    CONSTRAINT chk_viaje_distancia CHECK (
        distancia_km IS NULL
        OR distancia_km >= 0
    ),
    CONSTRAINT chk_viaje_duracion CHECK (
        duracion_minutos IS NULL
        OR duracion_minutos >= 0
    ),
    CONSTRAINT chk_viaje_importe CHECK (
        importe_total IS NULL
        OR importe_total >= 0
    )
) ENGINE = InnoDB;

CREATE TABLE cabify.oferta (
    id_oferta INT NOT NULL AUTO_INCREMENT,
    id_viaje INT NOT NULL,
    id_conductor INT NOT NULL,
    estado_oferta VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta DATETIME NULL,
    PRIMARY KEY (id_oferta),
    UNIQUE KEY uk_oferta_viaje_conductor (id_viaje, id_conductor),
    KEY idx_oferta_conductor_estado (id_conductor, estado_oferta),
    KEY idx_oferta_viaje_estado (id_viaje, estado_oferta),
    CONSTRAINT fk_oferta_viaje FOREIGN KEY (id_viaje) REFERENCES cabify.viaje (id_viaje) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_oferta_conductor FOREIGN KEY (id_conductor) REFERENCES cabify.conductor (id_conductor) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_oferta_estado CHECK (
        estado_oferta IN (
            'pendiente',
            'aceptada',
            'rechazada'
        )
    )
) ENGINE = InnoDB;

CREATE TABLE cabify.auditoria (
    id_auditoria INT NOT NULL AUTO_INCREMENT,
    entidad VARCHAR(50) NOT NULL,
    id_entidad INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    detalle VARCHAR(255),
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria),
    KEY idx_auditoria_entidad_id (entidad, id_entidad),
    KEY idx_auditoria_fecha (fecha_evento),
    CONSTRAINT chk_auditoria_accion CHECK (
        accion IN ('INSERT', 'UPDATE', 'DELETE')
    )
) ENGINE = InnoDB;