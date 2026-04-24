# Memoria Técnica Integral del Sistema de Base de Datos para Plataforma de Ride-Hailing

Este documento constituye la memoria técnica exhaustiva y el manual de referencia arquitectónica para el proyecto de base de datos orientado a una plataforma de transporte compartido (Ride-Hailing). A lo largo de los siguientes apartados se desglosa el diseño conceptual, lógico y físico del sistema, así como la implementación de la lógica de negocio, los mecanismos de seguridad, las estrategias de control de concurrencia y el plan de continuidad del servicio.

---

## 1. Arquitectura de Despliegue e Infraestructura

El sistema ha sido diseñado para ejecutarse en un entorno altamente aislado y reproducible mediante la tecnología de contenerización de Docker. La orquestación de los servicios se define en el archivo `compose.yml`, el cual levanta una infraestructura compuesta por cuatro nodos fundamentales:

1. **Motor de Base de Datos (MySQL 8.0)**: Actúa como el núcleo del sistema. Se ha configurado con volúmenes persistentes (`mysql_data`) para garantizar que la información sobreviva a la destrucción del contenedor. Se exponen los puertos estándar y se inyectan variables de entorno para la configuración inicial de credenciales.
2. **Exportador de Métricas (mysqld-exporter)**: Un servicio intermediario cuya única función es conectarse a la instancia de MySQL mediante un usuario con privilegios restringidos, extraer variables de estado internas (uso de memoria, conexiones, consultas lentas) y exponerlas en un formato compatible para su recolección.
3. **Almacenamiento de Series Temporales (Prometheus)**: Configurado mediante el archivo `prometheus.yml`, este servicio realiza peticiones periódicas (scraping) al exportador para almacenar el histórico del rendimiento del servidor, permitiendo el análisis retrospectivo.
4. **Plataforma de Visualización (Grafana)**: Interfaz gráfica conectada a Prometheus y directamente a MySQL, utilizada para la renderización de cuadros de mando (dashboards) que muestran tanto el estado técnico del clúster como los indicadores clave de rendimiento (KPIs) del negocio.

---

## 2. Secuencia de Inicialización

Para garantizar la consistencia y la correcta resolución de dependencias, la base de datos debe ser inicializada ejecutando los scripts en un orden estrictamente secuencial:

1. **`schema.sql`**: Construye el esquema de datos (tablas, restricciones, índices) y todos los objetos lógicos (procedimientos, funciones, eventos y disparadores).
2. **`data.sql`**: Procesa la carga masiva de datos iniciales (mock data), estableciendo el estado base necesario para la validación de las consultas.
3. **`permissions.sql`**: Aplica la capa de seguridad, creando los roles, asignando privilegios y definiendo los usuarios de conexión.

---

## 3. Modelo Relacional y Diccionario de Datos (`schema.sql`)

El diseño de la base de datos se rige por los principios de normalización para evitar anomalías de inserción, actualización o borrado.

### 3.1. Gestión de Entidades e Identidad

Se ha implementado un patrón de especialización/generalización para la jerarquía de usuarios:

- **`usuario`**: Entidad superclase que centraliza la información de contacto e identidad. Los campos críticos, como el `telefono`, se han definido bajo el tipo `VARBINARY(255)` para permitir su almacenamiento cifrado nativo. Incorpora metadatos de auditoría temporal (`created_at`, `updated_at`).
- **`rider`**: Entidad subclase que representa a los clientes. Su clave primaria actúa simultáneamente como clave foránea hacia la tabla `usuario`, garantizando una relación 1:1.
- **`conductor`**: Entidad subclase para los operarios. Incluye su número de licencia y una máquina de estados gestionada mediante el tipo `ENUM` (`disponible`, `en_viaje`, `desconectado`, `suspendido`). Mantiene una relación de cardinalidad N:1 con la entidad `company`.
- **`company`**: Representa a las flotas de transporte. El identificador fiscal (`cif`) se almacena cifrado (`VARBINARY`).
- **`vehiculo`**: Define el inventario físico, enlazando una matrícula única con una empresa propietaria.

### 3.2. Operativa Central: Viajes y Ofertas

La gestión logística se articula en torno a dos entidades altamente transaccionales:

- **`viaje`**: Almacena la solicitud de transporte.
  - **Datos Espaciales**: Las coordenadas geográficas de origen y destino se almacenan utilizando el tipo de dato `POINT` bajo el estándar SRID 4326 (WGS 84). Esto habilita el uso de índices espaciales (`SPATIAL INDEX`), lo cual reduce drásticamente la complejidad computacional en búsquedas de proximidad frente a los cálculos tradicionales basados en tipos `DECIMAL`.
  - **Máquina de Estados**: El ciclo de vida (`solicitado`, `aceptado`, `en_curso`, `finalizado`, `cancelado`) se controla estrictamente mediante un tipo `ENUM`.
  - **Índices Compuestos**: Se ha definido un índice sobre `(id_rider, estado)` para acelerar las lecturas en la interfaz del cliente.
- **`oferta`**: Representa una propuesta económica de un viaje enviada a un conductor. Permite el seguimiento del tiempo de respuesta y la cuantía ofrecida.

### 3.3. Facturación y Feedback

- **`pago`**: Registra las transacciones económicas. Implementa restricciones de integridad a nivel de fila (`CHECK constraint`) para forzar que el campo `importe_total` sea matemáticamente igual a la suma de `comision_company` e `importe_conductor`, previniendo corrupciones en la contabilidad.
- **`valoracion`**: Almacena las calificaciones bidireccionales, restringiendo los valores numéricos entre 1 y 5 mediante una restricción `CHECK`.

### 3.4. Auditoría y Particionado de Históricos

- **`viaje_estado_log`**: Diseñada para registrar cada transición de estado de todos los viajes del sistema. Dado que su volumen de inserciones es crítico y de crecimiento constante, la tabla ha sido diseñada con **Particionado por Rango** (Partitioning by Range) basado en el año de inserción. Esta arquitectura fragmenta físicamente los datos, lo que agiliza las consultas sobre el año en curso y facilita el archivado o purgado (dropping) de particiones históricas sin recurrir a operaciones de borrado masivo (`DELETE`), las cuales son altamente costosas en I/O.

---

## 4. Lógica de Negocio Programada (`schema.sql`)

Toda la lógica crítica se ha centralizado en el motor de base de datos para asegurar el cumplimiento de las reglas de negocio independientemente del cliente o API que se conecte.

### 4.1. Procedimientos Almacenados (Stored Procedures)

Se ha aplicado la convención de nomenclatura `sp_` para identificar inequívocamente los procedimientos:

- **`sp_aceptar_oferta`**: Resolución del problema de concurrencia principal. Cuando múltiples conductores compiten por un mismo viaje simultáneamente, el sistema debe garantizar que solo uno lo adquiera. Este procedimiento ejecuta un bloque `START TRANSACTION` y emplea un bloqueo pesimista a nivel de fila mediante `SELECT ... FOR UPDATE`. Este mecanismo detiene las lecturas concurrentes de otros hilos sobre esa fila específica hasta que la transacción en curso finaliza. Si la fila sigue en estado 'solicitado', se procesa la aceptación, se asigna el conductor, se expiran las demás ofertas mediante un `UPDATE` masivo y se ejecuta un `COMMIT`. De lo contrario, se realiza un `ROLLBACK`.
- **`sp_generar_liquidaciones`**: Un proceso orientado a operaciones por lotes (batch) que inserta registros en la tabla de pagos únicamente para los viajes con estado 'finalizado' que no posean un pago previo asociado.

### 4.2. Funciones Almacenadas (Stored Functions)

- **`fn_calcular_precio_total`**: Encapsula el cálculo del coste final para el cliente, aplicando un recargo sobre la oferta base. Esta abstracción garantiza que el algoritmo de precios, sujeto a cambios fiscales o comerciales, se modifique en un único nodo lógico (Single Source of Truth). Se declara como `DETERMINISTIC` para optimizar su rendimiento en consultas recurrentes.

### 4.3. Automatización de Sistema (Eventos y Triggers)

- **`ev_limpiar_ofertas_caducadas`**: Utiliza el planificador de eventos interno de MySQL (Event Scheduler). Ejecutado cada minuto, identifica y marca como `expirada` cualquier oferta en estado `pendiente` cuyo tiempo de emisión supere los 5 minutos.
- **`tr_audit_viaje_estado`**: Disparador (`Trigger`) asociado al evento `AFTER UPDATE` sobre la tabla `viaje`. Su función es comparar los pseudo-registros `OLD.estado` y `NEW.estado`. Si detecta una mutación, inserta automáticamente un registro en la tabla particionada de logs `viaje_estado_log`, garantizando un registro inmutable e imperceptible para el cliente.

---

## 5. Implementación de Carga de Datos (`data.sql`)

El script de inserción de datos proporciona un contexto operable. Destacan dos implementaciones técnicas avanzadas:

1. **Cifrado Simétrico**: Los datos sensibles definidos como `VARBINARY` (CIF, Teléfono) se insertan utilizando la función nativa `AES_ENCRYPT()`, utilizando una variable de sesión (`@key_str`) como clave de encriptación.
2. **Conversión Espacial**: Las coordenadas GPS se insertan utilizando la función constructora `ST_GeomFromText()`, que transforma la representación textual geométrica estándar en el formato binario requerido por el sistema de referencia espacial 4326.

---

## 6. Seguridad y Control de Acceso (`permissions.sql`)

El diseño de seguridad se rige por el Principio de Mínimo Privilegio (PoLP), implementando el modelo de Control de Acceso Basado en Roles (RBAC):

1. **Vistas de Anonimización**: Se declara la vista `v_usuarios_anonimizados` sobre la tabla `usuario`. Esta vista expone exclusivamente campos de identificación pública (ID, nombre, fechas), ocultando deliberadamente las columnas que contienen la Información Personal Identificable (PII) cifrada.
2. **Definición de Roles**:
   - `rol_admin`: Otorga `ALL PRIVILEGES`, reservado para el Administrador de Base de Datos (DBA).
   - `rol_app`: Rol operacional asignado al backend. Cuenta con privilegios completos de manipulación de datos (DML) como `SELECT`, `INSERT`, `UPDATE` y `DELETE`. Adicionalmente, cuenta con el privilegio `EXECUTE` explícito sobre los procedimientos `sp_` y funciones `fn_` necesarios para su operativa. Carece de privilegios de definición de datos (DDL).
   - `rol_analista`: Rol de inteligencia de negocio. Restringido a sentencias `SELECT` y limitado exclusivamente a la lectura de la vista anonimizada y a las tablas puramente numéricas o de registro histórico.
3. **Cuentas de Usuario**: Se han creado los usuarios de conexión específicos vinculados a los roles correspondientes mediante la instrucción `GRANT` e inicializados con `SET DEFAULT ROLE`.

---

## 7. Analítica de Operaciones y Sistema (`dashboard.sql` y `queries.sql`)

Se provee una colección de sentencias DQL optimizadas para la extracción de conocimiento:

- **Operativa Diaria (`queries.sql`)**: Ejemplificación de cruces de datos (Joins) que interconectan hasta seis tablas simultáneamente para reconstruir la factura detallada o "ticket" de un servicio finalizado. Se expone de nuevo la implementación práctica de la protección por concurrencia.
- **Inteligencia de Negocio (`dashboard.sql`)**: Agrupaciones (`GROUP BY`) complejas combinadas con expresiones condicionales (`SUM(CASE WHEN...)`) para calcular la tasa porcentual de aceptación de ofertas por conductor y compañía, así como el cálculo de las métricas de rentabilidad operativa (EUR/km y EUR/min).
- **Diagnóstico del Motor (`dashboard.sql`)**: Lecturas dirigidas a la base de datos interna `performance_schema`. Destaca el cálculo del "Buffer Pool Hit Ratio", una métrica esencial que indica el porcentaje de lecturas que han sido resueltas directamente desde la memoria RAM (InnoDB Buffer Pool) sin necesidad de acceso a disco físico, determinando la salud general de la memoria asignada al clúster.

---

## 8. Plan de Continuidad y Disaster Recovery (`backup.sql`)

El diseño del sistema contempla un plan de mitigación frente a catástrofes lógicas o físicas.

- **Recovery Point Objective (RPO)**: Se ha fijado un margen de pérdida de datos máximo de 1 hora. La estrategia combina un respaldo (backup) lógico completo y periódico mediante la utilidad `mysqldump` (ejecutado con el parámetro `--single-transaction` para no bloquear las tablas en producción), sumado a la retención activa de los Registros Binarios de MySQL (`binlogs`), los cuales almacenan cada transacción ejecutada secuencialmente.
- **Recovery Time Objective (RTO)**: Estimado en 2 horas. La contenerización proporciona una reconstrucción casi instantánea del binario del servidor. El tiempo está determinado exclusivamente por el proceso de carga del volcado de seguridad.
- **Point-In-Time Recovery (PITR)**: El documento `backup.sql` contiene la sintaxis precisa para la utilización de la herramienta `mysqlbinlog`. Esta técnica permite a los administradores filtrar las transacciones ocurridas entre la fecha del último backup y un segundo exacto del tiempo, posibilitando la recuperación quirúrgica frente a sentencias erróneas masivas (e.g. un `UPDATE` sin cláusula `WHERE` ejecutado por error humano).ñ