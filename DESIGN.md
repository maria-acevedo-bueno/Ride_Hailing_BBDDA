# Modelo Entidad-Relación (MER)

En esta sección se presenta el modelo ER del sistema de ride-hailing. Este modelo recoge las entidades principales del dominio, sus atributos y las relaciones entre ellas.

```mermaid
erDiagram
    USUARIO {
        BIGINT id_usuario PK
        VARCHAR nombre
        VARCHAR apellido1
        VARCHAR apellido2
        VARCHAR email
        VARCHAR telefono
        DATE fecha_alta
        BOOLEAN activo
        DATETIME created_at
        DATETIME updated_at
    }

    RIDER {
        BIGINT id_usuario PK, FK
    }

    CONDUCTOR {
        BIGINT id_usuario PK, FK
        VARCHAR numero_licencia
        ENUM estado_conductor "disponible|en_viaje|desconectado|suspendido"
        DATE fecha_alta_conductor
        BIGINT id_company FK
    }

    COMPANY {
        BIGINT id_company PK
        VARCHAR nombre
        VARCHAR cif
        DATE fecha_alta
        BOOLEAN activa
    }

    VEHICULO {
        BIGINT id_vehiculo PK
        BIGINT id_company FK
        VARCHAR matricula
        VARCHAR marca
        VARCHAR modelo
        VARCHAR color
        INT anio
        INT capacidad
        BOOLEAN activo
    }

    VIAJE {
        BIGINT id_viaje PK
        BIGINT id_rider FK
        BIGINT id_conductor FK
        BIGINT id_vehiculo FK
        ENUM estado "solicitado|aceptado|en_curso|finalizado|cancelado"
        DATETIME fecha_solicitud
        DATETIME fecha_aceptacion
        DATETIME fecha_inicio
        DATETIME fecha_fin
        DECIMAL origen_lat
        DECIMAL origen_lng
        VARCHAR origen_direccion
        DECIMAL destino_lat
        DECIMAL destino_lng
        VARCHAR destino_direccion
        DECIMAL distancia_km
        VARCHAR cancelado_por
        VARCHAR motivo_cancelacion
    }

    OFERTA {
        BIGINT id_oferta PK
        BIGINT id_viaje FK
        BIGINT id_conductor FK
        DATETIME fecha_envio
        DATETIME fecha_respuesta
        ENUM estado_oferta "pendiente|aceptada|rechazada|expirada"
        DECIMAL importe_ofrecido
    }

    PAGO {
        BIGINT id_pago PK
        BIGINT id_viaje FK
        DECIMAL importe_total
        DECIMAL comision_company
        DECIMAL importe_conductor
        VARCHAR metodo_pago
        ENUM estado_pago "pendiente|completado|fallido|reembolsado"
        DATETIME fecha_pago
    }

    VIAJE_ESTADO_LOG {
        BIGINT id_historial PK
        BIGINT id_viaje FK
        ENUM estado_anterior "solicitado|aceptado|en_curso|finalizado|cancelado"
        ENUM estado_nuevo "solicitado|aceptado|en_curso|finalizado|cancelado"
        DATETIME fecha_cambio
        BIGINT id_usuario_actor FK
        VARCHAR comentario
    }

    VALORACION {
        BIGINT id_valoracion PK
        BIGINT id_viaje FK
        BIGINT id_usuario_valorador FK
        BIGINT id_usuario_valorado FK
        ENUM rol_valorado "rider|conductor"
        INT puntuacion
        VARCHAR comentario
        DATETIME fecha_valoracion
    }

    USUARIO ||--o| RIDER : "se especializa en"
    USUARIO ||--o| CONDUCTOR : "se especializa en"

    COMPANY ||--o{ CONDUCTOR : "tiene"
    COMPANY ||--o{ VEHICULO : "gestiona"

    RIDER ||--o{ VIAJE : "solicita"
    CONDUCTOR ||--o{ VIAJE : "realiza"
    VEHICULO ||--o{ VIAJE : "se usa en"

    VIAJE ||--o{ OFERTA : "genera"
    CONDUCTOR ||--o{ OFERTA : "recibe"

    VIAJE ||--o| PAGO : "genera"
    VIAJE ||--o{ VIAJE_ESTADO_LOG : "tiene"
    USUARIO ||--o{ VIAJE_ESTADO_LOG : "provoca"

    VIAJE ||--o{ VALORACION : "origina"
    USUARIO ||--o{ VALORACION : "emite"
    USUARIO ||--o{ VALORACION : "recibe"
```
