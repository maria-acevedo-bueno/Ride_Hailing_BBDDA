# DISEÑO DE LA BASE DE DATOS

## 1. Docker

Explicar cómo hemos decidido crear el docker compose y las configuraciones del .cnf

## 2. Tabla entidad-relación

Poner la tabla entidad relaión. Explicar cada tabla, relaciones y limitaciones en cada una de ellas

## 3. Roles y permisos

Explicar usuarios y roles, por qué se han creado y las funciones que hacen cada uno de ellos.

## 4. Vistas e Índices

Explicar todas las vistas que se han creado, para qué sirven y quién tiene acceso a ellas.

Explicar los índices que se han creado, por qué se han creado y para qué sirven.

## 5. Procedimientos almacenados y triggers

Procedimiento: `sp_solicitar_viaje`
Genera un nuevo viaje en el sistema y distribuye las ofertas a la flota. Tras insertar el registro del viaje con sus coordenadas y calcular el precio base según la distancia, el procedimiento utiliza un cursor para iterar sobre todos los conductores que estén libres. A cada uno se le asigna una oferta en estado "pendiente". Todo el bloque se ejecuta dentro de una transacción para asegurar que el viaje y las ofertas se publiquen en bloque, garantizando la consistencia de los datos.

Procedimiento: `sp_aceptar_oferta`
Asigna el viaje al primer conductor que lo acepta. Para evitar condiciones de carrera (por ejemplo, que dos conductores acepten la misma oferta en el mismo milisegundo), se aplica un bloqueo pesimista (SELECT ... FOR UPDATE) sobre la fila del viaje. El primero en llegar bloquea el registro, cambia su estado a "aceptado", actualiza su oferta como ganadora y expira automáticamente las del resto. Si un segundo conductor intenta acceder a la vez, la base de datos lo pondrá en espera y acabará rechazándolo porque el viaje ya no estará disponible.

Procedimiento: `sp_finalizar_viaje_y_pagar`
Cierra el ciclo operativo del viaje y gestiona el reparto económico. Primero, bloquea la fila y verifica que el servicio siga en curso. Al confirmarlo, finaliza el viaje y devuelve al conductor al estado "disponible". A nivel financiero, recupera el importe pactado en la oferta, aplica el 20% de margen comercial para la plataforma y vuelca los datos desglosados en la tabla de pagos para dejar el servicio liquidado en una única transacción.

Trigger: `tr_audit_viaje_estado`
Mantiene un historial inmutable de cualquier cambio de estado en los viajes. Al comparar el valor anterior (OLD) con el nuevo (NEW) mediante un operador de igualdad seguro, el disparador detecta si realmente ha habido una modificación. De ser así, vuelca una traza en la tabla de auditoría. Al delegar esto a la base de datos, garantizamos que quede un registro temporal sin importar si el cambio lo hizo el backend, un administrador o un proceso automático.

## 6. Backup

Explicar el RTO decidido, cómo están automatizados los backups y cómo hacemos PITR

## 7. Monitorización

Explicar el sistema de monitorización que hayamos usado.