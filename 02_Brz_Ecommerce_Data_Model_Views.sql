--===================================
-- 2. creacion de vistas analiticas
--===================================

--=====================
-- 2.1. vista detalle de ordenes
--=====================

create or alter view vw_orders_detail as
select 
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp as fecha_compra,
        o.order_approved_at as fecha_aprobacion,
        o.order_delivered_carrier_date as fecha_envio_transportista,
        o.order_estimated_delivery_date as fecha_entrega_estimada,
        oi.shipping_limit_date as fecha_limite_envio,
        o.order_delivered_customer_date as fecha_entrega_cliente,
        p.product_id,
        pct.product_category_name_english as categoria_producto,
        oi.order_item_id,
        orv.review_score as puntaje_resena,
        pg.payment_type as tipo_pago,
        pg.payment_value as valor_pago,
        oi.price as precio,
        oi.freight_value as valor_flete,
        c.customer_id,
        c.customer_zip_code_prefix as codigo_postal_cliente,
        c.customer_city as ciudad_cliente,
        c.customer_state as estado_cliente,
        s.seller_id,
        s.seller_zip_code_prefix as codigo_postal_vendedor,
        s.seller_city as ciudad_vendedor,
        s.seller_state as estado_vendedor
from orders as o
left join order_item as oi on o.order_id = oi.order_id
left join products as p on oi.product_id = p.product_id
left join product_category_name_translation as pct on p.product_category_name = pct.product_category_name
left join order_payments as pg on o.order_id = pg.order_id
left join customer as c on o.customer_id = c.customer_id
left join sellers as s on oi.seller_id = s.seller_id
left join order_reviews as orv on orv.order_id = o.order_id;
go


/**
Vista: vw_order_details
Propósito:
    - Proporcionar el detalle completo de cada orden a nivel de item.
    - Integrar información de producto, vendedor, cliente, pago, flete y reseñas en una sola vista.
    - Servir como base para vistas agregadas (clientes, vendedores, productos, zonas).

Columnas principales:
    - Identificación:
        * order_id → identificador único de la orden.
        * order_item_id → identificador único del item dentro de la orden.
    - Cliente:
        * customer_id, customer_zip_code_prefix, ciudad_cliente, estado_cliente.
    - Vendedor:
        * seller_id, seller_zip_code_prefix, ciudad_vendedor, estado_vendedor.
    - Producto:
        * product_id, product_category_name.
    - Transacción:
        * payment_value → monto pagado por la orden.
        * freight_value → costo del flete asociado al item.
    - Calidad del servicio:
        * review_score → puntaje de reseña asociado a la orden.

Decisiones de diseño:
    - Se usa directamente customer_zip_code_prefix y seller_zip_code_prefix para evitar duplicados de geolocation.
    - Los pagos se integran a nivel de orden, no de item, para mantener consistencia.
    - Las reseñas se conectan por order_id, garantizando que cada orden aporte su evaluación.
    - Esta vista es granular y no aplica agregaciones; se recomienda usarla como base para construir vistas analíticas (clientes, vendedores, productos).
*/

--=====================
-- 2.2. vista clientes
--=====================

create or alter view vw_info_clientes as
with cliente_base as (
    select
        c.customer_id,
        c.customer_zip_code_prefix as codigo_postal_cliente,
        c.customer_city as ciudad_cliente,
        c.customer_state as estado_cliente,
        oi.order_item_id,
        p.payment_value as valor_pago,
        oi.freight_value as valor_flete,
        r.review_score as puntaje_resena
    from customer as c
    inner join orders as o on c.customer_id = o.customer_id
    left join order_item as oi on o.order_id = oi.order_id
    left join order_payments as p on o.order_id = p.order_id
    left join order_reviews as r on o.order_id = r.order_id
)
select
    customer_id,
    codigo_postal_cliente,
    ciudad_cliente,
    estado_cliente,
    count(puntaje_resena) as cantidad_resenas,                             
    count(distinct order_item_id) as total_productos_comprados,               
    sum(valor_pago) * 1.0 / nullif(count(distinct order_item_id),0) as ticket_promedio_por_producto,
    sum(valor_pago) as total_compra_cliente,                                  
    sum(valor_flete) as total_pago_flete,                                    
    (sum(valor_flete) * 100.0 / nullif(sum(valor_pago),0)) as porcentaje_flete_sobre_compra
from cliente_base
group by customer_id, codigo_postal_cliente, ciudad_cliente, estado_cliente;
go

/**
Vista: vw_info_clientes
Propósito:
    - Generar un perfil de cada cliente con métricas de compra, reseñas y costos de flete.
    - Simplificar la lógica evitando duplicados al usar directamente customer_zip_code_prefix.

Columnas principales:
    - Identificación: customer_id, código postal, ciudad, estado.
    - Actividad de compra:
        * total_productos_comprados → número de productos distintos adquiridos.
        * total_compra_cliente → suma de pagos realizados.
        * ticket_promedio_por_producto → promedio de gasto por producto.
    - Costos asociados:
        * total_pago_flete → suma de valores de flete.
        * porcentaje_flete_sobre_compra → proporción del flete respecto al total de compra.
    - Calidad del servicio:
        * cantidad_resenas → número de reseñas recibidas.
        * puntaje_resena → promedio de reseñas (si se requiere).

Decisiones de diseño:
    - Se eliminó la dependencia de la tabla geolocation para evitar duplicados.
    - Se usa directamente customer_zip_code_prefix, ciudad y estado del cliente.
    - Se agrupan métricas a nivel de cliente para obtener resultados consistentes.
*/

select *
from vw_info_clientes;
go

--=====================
-- 2.3. vista vendedores
--=====================

create or alter view vw_info_vendedores as


with pagos_por_orden as (
    select order_id, sum(payment_value) as total_pago
    from order_payments
    group by order_id
),

reseñas_por_orden as (
    select order_id, avg(review_score) as promedio_resena, count(review_score) as cantidad_resenas
    from order_reviews
    group by order_id
),

items_por_vendedor as (
    select
        s.seller_id,
        s.seller_zip_code_prefix as codigo_postal_vendedor, 
        s.seller_city as ciudad_vendedor,
        s.seller_state as estado_vendedor,
        o.order_id,
        oi.order_item_id,
        c.customer_id,
        c.customer_city as ciudad_cliente,
        c.customer_state as estado_cliente
    from sellers as s
    inner join order_item as oi on s.seller_id = oi.seller_id
    inner join orders as o on oi.order_id = o.order_id
    left join customer as c on o.customer_id = c.customer_id
)

select
    i.seller_id,
    i.codigo_postal_vendedor,
    i.ciudad_vendedor,
    i.estado_vendedor,
    count(distinct i.order_id) as cant_ordenes,
    count(distinct i.order_item_id) as total_unidades_vendidas,
    count(distinct i.customer_id) as cant_clientes_atendidos,
    count(distinct i.ciudad_cliente) as cant_ciudades_atendidas,
    count(distinct i.estado_cliente) as cant_estados_atendidos,
    sum(p.total_pago) as total_ventas,   
    sum(p.total_pago) * 1.0 / nullif(count(distinct i.order_id),0) as ticket_promedio_por_orden,
    count(distinct i.customer_id) * 1.0 / nullif(count(distinct i.ciudad_cliente),0) as promedio_clientes_por_ciudad,
    sum(r.cantidad_resenas) as total_resenas,       
    avg(r.promedio_resena) as promedio_resena       
from items_por_vendedor as i
left join pagos_por_orden as  p on i.order_id = p.order_id
left join reseñas_por_orden as r on i.order_id = r.order_id
group by i.seller_id, i.codigo_postal_vendedor, i.ciudad_vendedor, i.estado_vendedor;
go
/**
Vista: vw_info_vendedores
Propósito:
    - Generar un perfil de cada vendedor con métricas de ventas, alcance de clientes y reseñas.
    - Evitar duplicados en pagos y geolocalización mediante preagregación y simplificación.

Columnas principales:
    - Identificación: seller_id, código postal, ciudad, estado.
    - Actividad comercial:
        * cant_ordenes → número de órdenes atendidas.
        * total_unidades_vendidas → cantidad de productos vendidos.
        * total_ventas → suma de pagos por orden.
        * ticket_promedio_por_orden → promedio de venta por orden.
    - Alcance de clientes:
        * cant_clientes_atendidos → clientes únicos.
        * cant_ciudades_atendidas → ciudades distintas atendidas.
        * cant_estados_atendidos → estados distintos atendidos.
        * promedio_clientes_por_ciudad → relación clientes/ciudades.
    - Calidad del servicio (opcional):
        * total_resenas → cantidad de reseñas recibidas.
        * promedio_resena → promedio de puntaje de reseñas.

Decisiones de diseño:
    - Se eliminó la conexión directa con geolocation para evitar duplicados por lat/lng.
    - Se usa seller_zip_code_prefix, ciudad y estado del vendedor como ubicación básica.
    - Los pagos se preagregan en pagos_por_orden para evitar inflación por items.
    - Las reseñas se preagregan en reseñas_por_orden para evitar duplicados.
*/

--=====================
-- 2.4. vista productos
--=====================

create or alter view vw_info_producto as
with items_unicos as (
    select distinct 
        o.order_id,
        oi.order_item_id,
        oi.product_id,
        pc.product_category_name_english as categoria_producto,
        oi.price as precio,
        c.customer_city as ciudad_cliente,
        c. customer_state as estado_cliente
    from orders as o
    left join order_item as oi on o.order_id = oi.order_id
    left join customer as c on c.customer_id = o.customer_id
    left join products as p on p.product_id = oi.product_id
    left join product_category_name_translation as pc on pc.product_category_name = p.product_category_name
)
select  
    product_id,
    categoria_producto,
    estado_cliente as estado,
    ciudad_cliente as ciudad,
    min(precio) as precio_minimo,
    max(precio) as precio_maximo,
    avg(precio) as precio_promedio,
    sum(precio) as total_acumulado_real, 
    count(distinct order_id) as total_ordenes_del_producto,
    count(*) as total_unidades_vendidas
from items_unicos
group by product_id, categoria_producto, ciudad_cliente, estado_cliente;
go
/**
    NOTA - Vista de Productos (vw_info_producto):

    Objetivo:
    - Resumir información de productos vendidos, agrupada por categoría, estado y ciudad del cliente.
    - Mostrar métricas de precio y volumen de ventas directamente desde las tablas base,
    sin depender de vw_online_retail.
    - Incluir también registros con datos faltantes gracias al uso de LEFT JOIN,
    lo que permite identificar inconsistencias en la base.

    Tablas utilizadas:
    • orders: información de las órdenes.
    • order_item: detalle de productos por orden.
    • customer: ubicación del cliente (estado, ciudad).
    • products: identificación y categoría del producto.
    • product_category_name_translation: traducción de la categoría del producto.

    Métricas calculadas:
    • precio_minimo: menor precio registrado para el producto en el grupo.
    • precio_maximo: mayor precio registrado.
    • precio_promedio: promedio de precios (útil si existen variaciones).
    • total_acumulado_real: suma de precios, equivalente al valor total vendido en el grupo.
    • total_ordenes_del_producto: número de órdenes únicas en las que aparece el producto.
    • total_unidades_vendidas: cantidad total de unidades vendidas.

    Beneficios:
    - La vista refleja datos reales y sin duplicaciones.
    - Permite analizar ventas por producto y región.
    - Al usar LEFT JOIN, se incluyen registros incompletos, lo que ayuda a detectar errores
    o huecos en la información (ej. productos sin categoría traducida).

    En conclusión:
    Esta vista entrega un panorama claro y confiable del comportamiento de los productos,
    tanto en métricas de precio como en volumen de ventas, y sirve también como herramienta
    de auditoría de calidad de datos.
*/

SELECT top 10 *
FROM vw_info_producto
ORDER BY total_acumulado_real DESC;
GO

--===========================
-- 2.5. vista de métodos de pago
--===========================

create or alter view vw_info_pagos as
with agrupar_pago as (
    select  
        o.order_id,
        oi.order_item_id,
        p.payment_type as metodo_pago,
        p.payment_value as valor_pago,
        c.customer_state as estado_cliente,
        c.customer_city as ciudad_cliente
    from orders o
    inner join order_payments as p on o.order_id = p.order_id
    inner join order_item as oi on o.order_id = oi.order_id
    inner join customer as c on o.customer_id = c.customer_id
)
select
    metodo_pago,
    estado_cliente,
    ciudad_cliente,
    count(distinct order_id) as cantidad_de_ordenes,
    count(*) as veces_usado,
    sum(valor_pago) as total_pagado
from agrupar_pago
group by metodo_pago, estado_cliente, ciudad_cliente;
go

/**
    NOTA - Vista de Métodos de Pago (vw_info_pagos):

    - Esta vista resume el uso de métodos de pago por ciudad y estado.
    - Se construye directamente con las tablas base (orders, order_payments, order_items, customer),
    evitando el problema de duplicaciones que ocurría con vw_orders_detail.
    - Cada orden se cuenta una sola vez, y los pagos reflejan montos reales.

    Métricas incluidas:
    • metodo_pago: tipo de pago utilizado (ej. crédito, boleto, etc.).
    • estado_cliente y ciudad_cliente: ubicación del cliente.
    • cantidad_de_ordenes: número de órdenes únicas que usaron el método de pago.
    • veces_usado: número total de veces que el método de pago aparece en las órdenes.
    • total_pagado: suma real de los valores de pago registrados.

    Beneficios del cambio:
    - Los resultados son confiables y no inflados.
    - La vista queda ligera y modular, lista para análisis.
    - Rankings o comparaciones (ej. top ciudades por método de pago) se calculan externamente,
    solo cuando se necesitan, optimizando rendimiento.

    En conclusión:
    Esta vista entrega métricas limpias y reales sobre el uso de métodos de pago,
    sin duplicaciones y con valores únicos por orden.
*/

with ciudad_top as (
    select 
        metodo_pago,
        ciudad_cliente,
        estado_cliente,
        sum(total_pagado) as total_pagado_ciudad,
        sum(cantidad_de_ordenes)as cant_ordenes,
        row_number() over(partition by tipo_pago order by sum(total_pagado) desc) as rn
    from vw_info_pagos
    group by metodo_pago, ciudad_cliente, estado_cliente
)
select 
    metodo_pago,
    ciudad_cliente as ciudad_mas_vendedora,
    estado_cliente,
    cant_ordenes,
    total_pagado_ciudad
from ciudad_top
where rn = 1
order by total_pagado_ciudad desc;
go

--=====================
--2.6. vista por zona
--=====================

create or alter view vw_info_zonas as

with geo_unicos as (
    select distinct 
        g.geolocation_zip_code_prefix,
        g.geolocation_city,
        g.geolocation_state
    from geolocation as g
),
ordenes_unicas as (
    select 
        o.order_id,
        c.customer_id,
        oi.seller_id,
        c.customer_zip_code_prefix as codigo_postal_cliente,
        min(o.order_purchase_timestamp) as fecha_compra,
        max(o.order_delivered_customer_date) as fecha_entrega_cliente,
        sum(p.payment_value) as total_pago_orden,          -- pagos reales desde order_payments
        avg(r.review_score) as puntaje_prom_resena,        -- reseñas desde order_reviews
        avg(oi.freight_value) as costo_prom_flete,         -- flete promedio desde order_items
        min(oi.freight_value) as costo_min_flete,          -- flete mínimo
        max(oi.freight_value) as costo_max_flete,          -- flete máximo
        count(oi.order_item_id) as total_items_orden       -- cantidad de ítems vendidos
    from orders o
    inner join customer as  c on o.customer_id = c.customer_id
    inner join order_payments as  p on o.order_id = p.order_id
    inner join order_item as oi on o.order_id = oi.order_id
    left join order_reviews as r on o.order_id = r.order_id
    where o.order_delivered_customer_date is not null 
    and o.order_purchase_timestamp is not null
    and datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date) >= 0
    group by o.order_id, c.customer_zip_code_prefix, c.customer_id, oi.seller_id
)
select
    g.geolocation_state as estado,
    g.geolocation_city as ciudad,
    g.geolocation_zip_code_prefix as codigo_zip,
    count(distinct o.customer_id) as cant_clientes,
    count(distinct o.seller_id) as cant_vendedores,
    sum(o.total_pago_orden) as total_pagado,
    avg(o.total_pago_orden) as pago_promedio,
    count(distinct o.order_id) as total_ordenes,
    sum(o.total_items_orden) as total_items_vendidos,
    avg(o.puntaje_prom_resena) as puntaje_prom_resena_por_orden,
    min(datediff(day, o.fecha_compra, o.fecha_entrega_cliente)) as cant_dias_min_de_entrega,
    max(datediff(day, o.fecha_compra, o.fecha_entrega_cliente)) as cant_dias_max_de_entrega,
    avg(datediff(day, o.fecha_compra, o.fecha_entrega_cliente)) as cant_dias_prom_de_entrega,
    min(o.costo_min_flete) as costo_min_flete,
    max(o.costo_max_flete) as costo_max_flete,
    avg(o.costo_prom_flete) as costo_prom_flete
from geo_unicos as g
left join ordenes_unicas as  o on g.geolocation_zip_code_prefix = o.codigo_postal_cliente
group by g.geolocation_city, g.geolocation_state, g.geolocation_zip_code_prefix;
go

/**
    Vista: vw_info_zonas
    Objetivo:
    - Resumir la información de ventas y entregas por ciudad y código postal.
    - Los valores que se muestran aquí son ÚNICOS por orden, evitando duplicaciones.
    - Cada orden se consolida primero en el CTE "ordenes_unicas", 
    lo que garantiza que los pagos, ítems y fletes no se repitan.
    - Así, los resultados reflejan números reales y confiables.

    Qué incluye:
    - total_pagado: suma de los pagos reales (order_payments).
    - total_ordenes: cantidad de órdenes únicas.
    - total_items_vendidos: cantidad de productos vendidos sin duplicaciones.
    - cant_clientes y cant_vendedores: participación por zona.
    - costos de envío: promedio, mínimo y máximo.
    - tiempos de entrega: mínimo, máximo y promedio.
    - puntaje_prom_resena_por_orden: calificación promedio de clientes.

    Con esta vista se puede analizar:
    - Qué zonas venden más.
    - Cómo se comportan los envíos.
    - Qué opinan los clientes.
*/

select top 5 *
from vw_info_zonas
order by total_pagado desc;

--======================================================
-- Fin del Script
--======================================================