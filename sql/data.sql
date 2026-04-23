USE cabify;

INSERT INTO
    cabify.company (nombre, activo)
VALUES ('MoveFast', TRUE),
    ('UrbanDrive', TRUE);

INSERT INTO
    cabify.rider (
        nombre,
        email,
        telefono,
        activo
    )
VALUES (
        'Ana Pérez',
        'ana.rider@cabify.test',
        '600000001',
        TRUE
    ),
    (
        'Luis García',
        'luis.rider@cabify.test',
        '600000002',
        TRUE
    ),
    (
        'Marta López',
        'marta.rider@cabify.test',
        '600000003',
        TRUE
    );

INSERT INTO
    cabify.conductor (
        id_company,
        dni,
        nombre,
        email,
        telefono,
        activo
    )
VALUES (
        1,
        '11111111A',
        'Carlos Ruiz',
        'carlos.conductor@cabify.test',
        '611000001',
        TRUE
    ),
    (
        1,
        '22222222B',
        'Elena Martín',
        'elena.conductor@cabify.test',
        '611000002',
        TRUE
    ),
    (
        2,
        '33333333C',
        'Javier Sánchez',
        'javier.conductor@cabify.test',
        '611000003',
        TRUE
    ),
    (
        2,
        '44444444D',
        'Laura Díaz',
        'laura.conductor@cabify.test',
        '611000004',
        TRUE
    );

INSERT INTO
    cabify.vehiculo (
        id_conductor,
        matricula,
        marca,
        modelo,
        color,
        activo
    )
VALUES (
        1,
        '1111AAA',
        'Toyota',
        'Corolla',
        'Blanco',
        TRUE
    ),
    (
        2,
        '2222BBB',
        'Seat',
        'León',
        'Negro',
        TRUE
    ),
    (
        3,
        '3333CCC',
        'Renault',
        'Clio',
        'Azul',
        TRUE
    ),
    (
        4,
        '4444DDD',
        'Hyundai',
        'i30',
        'Gris',
        TRUE
    );

INSERT INTO
    cabify.viaje (
        id_rider,
        id_conductor,
        origen_latitud,
        origen_longitud,
        destino_latitud,
        destino_longitud,
        estado,
        fecha_solicitud,
        fecha_inicio,
        fecha_fin,
        distancia_km,
        duracion_minutos,
        importe_total
    )
VALUES (
        1,
        1,
        40.416775,
        -3.703790,
        40.430000,
        -3.700000,
        'finalizado',
        '2026-04-20 10:00:00',
        '2026-04-20 10:05:00',
        '2026-04-20 10:25:00',
        6.50,
        20.00,
        14.80
    ),
    (
        2,
        2,
        40.420000,
        -3.705000,
        40.440000,
        -3.690000,
        'en_curso',
        '2026-04-20 11:00:00',
        '2026-04-20 11:04:00',
        NULL,
        4.20,
        12.00,
        10.30
    ),
    (
        3,
        NULL,
        40.415000,
        -3.702000,
        40.450000,
        -3.710000,
        'solicitado',
        '2026-04-20 12:00:00',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    ),
    (
        1,
        3,
        40.418000,
        -3.699000,
        40.425000,
        -3.680000,
        'aceptado',
        '2026-04-20 12:30:00',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    );

INSERT INTO
    cabify.oferta (
        id_viaje,
        id_conductor,
        estado_oferta,
        fecha_envio,
        fecha_respuesta
    )
VALUES (
        1,
        1,
        'aceptada',
        '2026-04-20 10:01:00',
        '2026-04-20 10:02:00'
    ),
    (
        1,
        2,
        'rechazada',
        '2026-04-20 10:01:00',
        '2026-04-20 10:03:00'
    ),
    (
        2,
        2,
        'aceptada',
        '2026-04-20 11:01:00',
        '2026-04-20 11:02:00'
    ),
    (
        2,
        3,
        'rechazada',
        '2026-04-20 11:01:00',
        '2026-04-20 11:05:00'
    ),
    (
        3,
        1,
        'pendiente',
        '2026-04-20 12:01:00',
        NULL
    ),
    (
        3,
        4,
        'pendiente',
        '2026-04-20 12:01:00',
        NULL
    ),
    (
        4,
        3,
        'aceptada',
        '2026-04-20 12:31:00',
        '2026-04-20 12:32:00'
    ),
    (
        4,
        2,
        'rechazada',
        '2026-04-20 12:31:00',
        '2026-04-20 12:33:00'
    );

INSERT INTO
    cabify.auditoria (
        entidad,
        id_entidad,
        accion,
        detalle,
        fecha_evento
    )
VALUES (
        'viaje',
        1,
        'INSERT',
        'Creación inicial del viaje 1',
        '2026-04-20 10:00:00'
    ),
    (
        'oferta',
        1,
        'INSERT',
        'Oferta enviada al conductor 1 para el viaje 1',
        '2026-04-20 10:01:00'
    ),
    (
        'oferta',
        1,
        'UPDATE',
        'Oferta aceptada por el conductor 1',
        '2026-04-20 10:02:00'
    ),
    (
        'viaje',
        1,
        'UPDATE',
        'Viaje 1 marcado como finalizado',
        '2026-04-20 10:25:00'
    ),
    (
        'viaje',
        3,
        'INSERT',
        'Creación inicial del viaje 3',
        '2026-04-20 12:00:00'
    );