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
        ENUM estado_conductor
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
        ENUM estado
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
        ENUM estado_oferta
        DECIMAL importe_ofrecido
    }

    PAGO {
        BIGINT id_pago PK
        BIGINT id_viaje FK
        DECIMAL importe_total
        DECIMAL comision_company
        DECIMAL importe_conductor
        VARCHAR metodo_pago
        ENUM estado_pago
        DATETIME fecha_pago
    }

    VIAJE_ESTADO_LOG {
        BIGINT id_historial PK
        BIGINT id_viaje FK
        ENUM estado_anterior
        ENUM estado_nuevo
        DATETIME fecha_cambio
        BIGINT id_usuario_actor FK
        VARCHAR comentario
    }

    VALORACION {
        BIGINT id_valoracion PK
        BIGINT id_viaje FK
        BIGINT id_usuario_valorador FK
        BIGINT id_usuario_valorado FK
        ENUM rol_valorado
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
---
# Dominios de atributos

En el modelo conceptual, los atributos de tipo estado o rol se consideran atributos con dominio finito. Estos dominios se implementarán en el modelo lógico mediante tipos ENUM de MySQL.

### Estado del conductor (CONDUCTOR.estado_conductor)

#### Dominio:

- disponible
- en_viaje
- desconectado
- suspendido

### Estado del viaje (VIAJE.estado)

#### Dominio:

- solicitado
- aceptado
- en_curso
- finalizado
- cancelado

Este atributo define implícitamente una máquina de estados, cuyas transiciones válidas deberán ser controladas mediante lógica de aplicación o procedimientos almacenados.

### Estado de la oferta (OFERTA.estado_oferta)

#### Dominio:

- pendiente
- aceptada
- rechazada
- expirada

Para cada viaje, como máximo una oferta puede alcanzar el estado aceptada. Esta restricción no se garantiza a nivel del modelo conceptual, sino mediante control transaccional.

### Estado del pago (PAGO.estado_pago)

#### Dominio:

- pendiente
- completado
- fallido
- reembolsado

### Estados en historial de viaje (VIAJE_ESTADO_LOG)

#### Dominios:

- estado_anterior
- estado_nuevo

Ambos comparten el mismo dominio que VIAJE.estado:

- solicitado
- aceptado
- en_curso
- finalizado
- cancelado

### Rol valorado (VALORACION.rol_valorado)

#### Dominio:

- rider
- conductor

# Notas de diseño
La entidad USUARIO actúa como superentidad, especializándose en RIDER y CONDUCTOR. Esta decisión permite evitar redundancia en atributos comunes y centralizar la identidad del sistema.

La entidad OFERTA representa las propuestas de viaje enviadas a los conductores. Un viaje puede tener varias ofertas, pero solo una puede ser aceptada, lo cual se controla mediante transacciones.

La entidad VIAJE_ESTADO_LOG permite mantener trazabilidad completa sobre los cambios de estado de los viajes, separando el estado actual de su evolución histórica.

La entidad VALORACION referencia dos veces a USUARIO, puesto que una valoración implica dos roles distintos: el usuario que la emite y el usuario que la recibe, en este caso rider y conductor, respectivamente.

Los dominios de tipo estado no se modelan como entidades independientes en el MER, sino como atributos con valores específicos, ya que no tienen identidad propia ni relaciones adicionales en el dominio.
