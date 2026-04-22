USE ride_hailing;

-- MÉTRICAS DE NEGOCIO 

-- Tasa de aceptación por CONDUCTOR (Ofertas aceptadas / Total de ofertas enviadas)
SELECT 
    u.nombre AS conductor,
    COUNT(o.id_oferta) AS total_ofertas_recibidas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND((SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) / COUNT(o.id_oferta)) * 100, 2) AS tasa_aceptacion_pct
FROM oferta o
JOIN usuario u ON o.id_conductor = u.id_usuario
GROUP BY u.id_usuario, u.nombre
ORDER BY tasa_aceptacion_pct DESC;

-- Tasa de aceptación por COMPANY
SELECT 
    c.nombre AS company,
    COUNT(o.id_oferta) AS total_ofertas,
    SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) AS ofertas_aceptadas,
    ROUND((SUM(CASE WHEN o.estado_oferta = 'aceptada' THEN 1 ELSE 0 END) / COUNT(o.id_oferta)) * 100, 2) AS tasa_aceptacion_pct
FROM oferta o
JOIN conductor cond ON o.id_conductor = cond.id_usuario
JOIN company c ON cond.id_company = c.id_company
GROUP BY c.id_company, c.nombre;

-- Métricas de eficiencia: Tiempo medio y kilometraje por viaje
SELECT 
    ROUND(AVG(distancia_km), 2) AS kilometraje_medio_km,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)), 2) AS duracion_media_minutos
FROM viaje
WHERE estado = 'finalizado';

-- Ingresos por CONDUCTOR y rentabilidad (euros/km y euros/minuto)
SELECT 
    u.nombre AS conductor,
    SUM(p.importe_conductor) AS ingresos_totales,
    ROUND(SUM(p.importe_conductor) / SUM(v.distancia_km), 2) AS euros_por_km,
    ROUND(SUM(p.importe_conductor) / SUM(TIMESTAMPDIFF(MINUTE, v.fecha_inicio, v.fecha_fin)), 2) AS euros_por_minuto
FROM pago p
JOIN viaje v ON p.id_viaje = v.id_viaje
JOIN usuario u ON v.id_conductor = u.id_usuario
WHERE v.estado = 'finalizado'
GROUP BY u.id_usuario, u.nombre;

-- Ingresos por COMPANY (Suma de las comisiones de sus conductores)
SELECT 
    c.nombre AS company,
    SUM(p.comision_company) AS ingresos_totales_company,
    ROUND(SUM(p.comision_company) / SUM(v.distancia_km), 2) AS revenue_company_por_km
FROM pago p
JOIN viaje v ON p.id_viaje = v.id_viaje
JOIN conductor cond ON v.id_conductor = cond.id_usuario
JOIN company c ON cond.id_company = c.id_company
WHERE v.estado = 'finalizado'
GROUP BY c.id_company, c.nombre;

-- Demanda temporal: Viajes solicitados por HORA (Para un histograma)
SELECT 
    HOUR(fecha_solicitud) AS hora_del_dia,
    COUNT(*) AS total_viajes_solicitados
FROM viaje
GROUP BY HOUR(fecha_solicitud)
ORDER BY hora_del_dia ASC;


-- MÉTRICAS DE BASE DE DATOS (Monitorización DBA)
-- Estas consultas las puede usar Prometheus/Grafana o un DBA para revisar la salud.

-- Comprobar cuántas conexiones activas hay contra el límite máximo
SELECT 
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Threads_connected') AS conexiones_activas,
    @@max_connections AS limite_conexiones;

-- Calcular el Hit Ratio del Buffer Pool de InnoDB
-- Queremos asegurarnos de que sea > 99% (que los datos se lean de RAM y no del disco lento)
SELECT 
  ROUND((1 - (
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') /
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests')
  )) * 100, 4) AS buffer_pool_hit_ratio_pct;

-- Analizar el rendimiento de la consulta más pesada usando EXPLAIN
-- Para demostrar en la presentación que los índices que creamos funcionan
EXPLAIN SELECT o.id_oferta, o.estado_oferta, o.fecha_envio
FROM oferta o
WHERE o.estado_oferta = 'pendiente' 
ORDER BY o.fecha_envio DESC;

-- Ver si hay transacciones que se han quedado colgadas o tardan mucho (Bloqueos)
SELECT 
    trx_id, 
    trx_state, 
    trx_started, 
    trx_query
FROM information_schema.innodb_trx 
ORDER BY trx_started ASC;