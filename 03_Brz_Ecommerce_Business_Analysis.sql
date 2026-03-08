--====================================================================================================================================================================
-- 								preguntas a responder con consultas y vistas
--====================================================================================================================================================================

--===================================
-- 3.1 clientes y mercado
--===================================

-- 3.1.1. ¿en qué estados o ciudades tenemos la mayor concentración de clientes?
USE [brz_ecomerce];

select  top 10
        estado, 
        sum(cant_clientes) as cant_clientes
from vw_info_zonas
group by estado
order by sum(cant_clientes) desc;

-- 3.1.2.¿cuál es el crecimiento de nuevos clientes a lo largo del tiempo?

with primeras_compras as (
    select 
        customer_id,
        min(fecha_compra) as fecha_primer_compra
    from vw_orders_detail
    group by customer_id
),
clientes_mensuales as (
    select
        year(fecha_primer_compra) as anio_compra,
        month(fecha_primer_compra) as mes_compra,
        count(customer_id) as nuevos_clientes
    from primeras_compras
    group by year(fecha_primer_compra), month(fecha_primer_compra)
),
clientes_lag as (
    select  
        anio_compra,
        mes_compra,
        nuevos_clientes,
        lag(nuevos_clientes) over (order by anio_compra, mes_compra) as clientes_mes_anterior
    from clientes_mensuales
)
select *,
       case 
            when clientes_mes_anterior is null then null
            when clientes_mes_anterior = 0 then null
            else ((nuevos_clientes - clientes_mes_anterior) * 100.0) / clientes_mes_anterior
       end as porcentaje_crecimiento
from clientes_lag
order by anio_compra, mes_compra;
go

-- 3.1.3. ¿qué ciudades aportan el mayor volumen de órdenes?

select  top 10
        ciudad, 
        sum(cant_clientes) as cant_clientes
from vw_info_zonas
group by ciudad
order by sum(cant_clientes) desc;

--===================================
-- 3.2. ventas y productos
--===================================

-- 3.2.1. ¿qué categorías de producto son las más vendidas y cuáles tienen menor rotación?

-- categorias con items mas vendidos
select  top 10 
        categoria_producto,     
        sum(total_unidades_vendidas) cant_unidades_vendidas
from vw_info_producto
group by categoria_producto
order by cant_unidades_vendidas desc;

-- categorias con menos items vendidos
select  top 10 
        categoria_producto,     
        sum(total_unidades_vendidas) cant_unidades_vendidas
from vw_info_producto
group by categoria_producto
order by cant_unidades_vendidas asc;

-- 3.2.2. ¿cuál es el ticket promedio por cliente y por orden?

-- ticket promedio por cliente
select  customer_id,
        sum(total_compra_cliente)/nullif(sum(total_productos_comprados),0) as ticket_promedio_cliente
from vw_info_clientes
group by customer_id
ORDER BY ticket_promedio_cliente desc;


-- ticket promedio por orden

select o.order_id,
       sum(op.payment_value)/nullif(count(oi.order_item_id),0) as ticket_promedio
from order_payments as op
inner join orders as o on o.order_id = op.order_id
inner join order_item as oi on oi.order_id = o.order_id
group by o.order_id
order by ticket_promedio desc;

-- 3.2.3 ¿qué productos concentran el mayor valor de ventas aproximado, descontando el costo de flete?

select  top 10
        vp.product_id,
        sum(vp.total_acumulado_real)as total_venta,
        sum(oi.freight_value) as total_flete,
        sum(vp.total_acumulado_real) - sum(oi.freight_value) as total_acumulado_menos_flete
from vw_info_producto as vp
left join order_item as oi on oi.product_id = vp.product_id
group by vp.product_id
order by total_acumulado_menos_flete desc;

/* 
Nota:
El campo total_acumulado_real representa el pago total realizado por el cliente a nivel de orden,
obtenido a partir de la agregación de la información disponible en la tabla de pagos.
Dado que el dataset no proporciona el valor pagado ni el costo asociado a cada ítem individual, 
los análisis por producto se realizan como una aproximación, utilizando el total de pago de la orden y descontando 
el costo de flete acumulado correspondiente a los productos incluidos.

Este enfoque permite identificar productos con mayor concentración de ingresos,
manteniendo coherencia con las limitaciones del modelo de datos y evitando duplicaciones en los cálculos.
*/

-- 3.2.4 ¿qué porcentaje de las ventas proviene del top 10 categorías?

-- hecho con with
with rankedcategorias as (
    select 
        categoria_producto,
        sum(total_acumulado_real) as totalventas,
        row_number() over (order by sum(total_acumulado_real) desc) as rn
    from vw_info_producto
    group by categoria_producto
)
select 
    sum(case when rn <= 10 then totalventas else 0 end) * 100.0 / sum(totalventas) as porcentajetop10,
    sum(case when rn > 10 then totalventas else 0 end) * 100.0 / sum(totalventas) as porcentajeresto
from rankedcategorias;
go

-- hecho con subconsulta
select 
        sum(case when rn > 10 then totalventas else 0 end) * 100.0 / sum(totalventas) as porcentaje_top10,
        sum(case when rn <= 10 then totalventas else 0 end) * 100.0 / sum(totalventas) as porcentaje_resto
from(
    select
        categoria_producto,
        sum(total_acumulado_real) as totalventas,
        row_number() over(order by sum(total_acumulado_real) desc) as rn
    from vw_info_producto
    group by categoria_producto
) as ranked;

--===================================
-- 3.3. vendedores
--===================================

-- 3.3.1.¿qué vendedores concentran el mayor número de órdenes?

select top 10
        seller_id,
        count(distinct order_id) as cantidad_ordenes,
        dense_rank() over(order by count(distinct order_id) desc) as rango
from vw_orders_detail
group by seller_id;

select  top 10
        seller_id,
        sum(cant_ordenes) as cant_ordenes,
        dense_rank() over(order by  sum(cant_ordenes) desc) as rango
from vw_info_vendedores
group by seller_id;

 /*
 nota:
 gracias a este query:
 
 select	
        seller_id,
        count(distinct order_id) as cantidad_ordenes,
        dense_rank() over(order by count(order_id) desc) as rango
from vw_orders_detail
where seller_id is null
group by seller_id;

se observo que hay 833 ordenes las cuales no tienen seller_id
*/

-- 3.3.2. ¿cuál es el nivel de concentración del mercado y el % de ventas en manos del top 10 vendedores?

with rango_vendedores as (
    select  seller_id,
            sum(total_ventas) as total_venta,
            sum(cant_ordenes) as cant_ordenes,
            row_number() over(order by sum(total_ventas) desc) as rn
    from vw_info_vendedores
    group by seller_id
)
select 
        sum(case when rn <= 10 then total_venta else 0 end) * 100.0 / sum(total_venta) as '% top 10 vendedores',
        sum(case when rn <= 10 then cant_ordenes else 0 end) as 'cant. ordenes % top 10',
        sum(case when rn > 10 then total_venta else 0 end) * 100.0 / sum(total_venta) as '% resto de vendedores',
        sum(case when rn > 10 then cant_ordenes else 0 end) as 'cant. ordenes de resto vendedores'
from rango_vendedores
go
-- 3.3.3.  ¿qué vendedores tienen mejor desempeño en tiempos de entrega?

--with con row_number:
with vendedores as (
    select	
        seller_id,
        datediff(day, fecha_compra, fecha_entrega_cliente) as dias_de_entrega
    from vw_orders_detail
    where seller_id is not null
      and fecha_compra is not null
      and fecha_entrega_cliente is not null
      and datediff(day, fecha_compra, fecha_entrega_cliente) > 0
)
select top 10 seller_id,
       avg(dias_de_entrega) as promedio_dia_entrega,
       row_number() over(order by avg(dias_de_entrega)) as ranking
from vendedores
group by seller_id
order by promedio_dia_entrega;

--with con dense_rank:
with vendedores as (
    select	
        seller_id,
        datediff(day, fecha_compra, fecha_entrega_cliente) as dias_de_entrega
    from vw_orders_detail
    where seller_id is not null
      and fecha_entrega_cliente is not null
      and fecha_compra is not null
      and datediff(day, fecha_compra, fecha_entrega_cliente) > 0
)
select
    seller_id,
    avg(dias_de_entrega) as promedio_dias_entrega,
    dense_rank() over (order by avg(dias_de_entrega)) as ranking
from vendedores
group by seller_id
order by promedio_dias_entrega asc;

--===================================
-- 3.4. logística y entregas
--===================================

-- 3.4.1.¿cuál es el tiempo promedio de entrega por estado y por categoría de producto?

--tiempo promedio de entrega por estado
select  estado,
        avg(cant_dias_prom_de_entrega) as dias_prom_de_entrega
FROM vw_info_zonas
group by estado
order by  dias_prom_de_entrega;

-- tiempo promedio de entrega por categoria de producto

select  categoria_producto,
        avg(datediff(day,fecha_compra,fecha_entrega_cliente)) as dia_prom_de_entrega
from vw_orders_detail
where categoria_producto is not null
group by categoria_producto;

--tiempo promedio de netrega por estado y y categoria

select  estado_cliente,
        categoria_producto,
        avg(datediff(day,fecha_compra,fecha_entrega_cliente)) as dia_prom_de_entrega
from vw_orders_detail
group by estado_cliente,categoria_producto;

-- 3.4.2. ¿qué porcentaje de órdenes se entregan dentro del tiempo estimado?

with tiempo as (
    select 
        order_id,
        DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date) as tiempo_prom_entrega_dias,
        DATEDIFF(DAY,order_purchase_timestamp,order_estimated_delivery_date) as tiempo_prom_entrega_estimada_dias
    from orders
    where order_purchase_timestamp is not null
    and order_delivered_customer_date is not null
    and order_estimated_delivery_date is not null
)
select 
    count(*) as total_ordenes,
    sum(case when tiempo_prom_entrega_dias <= tiempo_prom_entrega_estimada_dias then 1 else 0 end) as ordenes_a_tiempo,
    sum(case when tiempo_prom_entrega_dias > tiempo_prom_entrega_estimada_dias then 1 else 0 end) as ordenes_fuera_tiempo,
    sum(case when tiempo_prom_entrega_dias <= tiempo_prom_entrega_estimada_dias then 1 else 0 end) * 100.0 / count(*) as porcentaje_a_tiempo,
    sum(case when tiempo_prom_entrega_dias > tiempo_prom_entrega_estimada_dias  then 1 else 0 end) * 100.0 / count(*) as porcentaje_fuera_tiempo
from tiempo
go
-- 3.4.3.¿Qué estados o ciudades tienen el porcentaje más alto de órdenes entregadas fuera del tiempo estimado?

-- porcentaje de entrega fuera de tiempo más elevado agrupados por ciudades
with orden_ciudad as (
    select  
        o.order_id,
        s.seller_city as ciudad,
        min(datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) as dias_entrega,
        min(datediff(day, o.order_purchase_timestamp, o.order_estimated_delivery_date)) as dias_estimados
    from orders as o
    inner join order_item as oi on oi.order_id = o.order_id
    inner join sellers as s on s.seller_id = oi.seller_id
    where o.order_purchase_timestamp is not null
    and o.order_delivered_customer_date is not null
    and o.order_estimated_delivery_date is not null
    group by o.order_id, s.seller_city
)
select 
    ciudad,
    count(*) as total_ordenes,
    sum(case when dias_entrega > dias_estimados then 1 else 0 end) as ordenes_fuera_tiempo,
    sum(case when dias_entrega > dias_estimados then 1 else 0 end) * 100.0 / count(*) as porcentaje_fuera_tiempo
from orden_ciudad
group by ciudad
order by porcentaje_fuera_tiempo desc;

-- porcentaje de entrega fuera de tiempo más elevado agrupados por estados
with orden_estado as (
    select  
        o.order_id,
        s.seller_state as estado,
        min(datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) as dias_entrega,
        min(datediff(day, o.order_purchase_timestamp, o.order_estimated_delivery_date)) as dias_estimados
    from orders as o
    inner join order_item as oi on oi.order_id = o.order_id
    inner join sellers as s on s.seller_id = oi.seller_id
    where o.order_purchase_timestamp is not null
    and o.order_delivered_customer_date is not null
    and o.order_estimated_delivery_date is not null
    group by o.order_id, s.seller_state
)
select 
    estado,
    count(*) as total_ordenes,
    sum(case when dias_entrega > dias_estimados then 1 else 0 end) as ordenes_fuera_tiempo,
    sum(case when dias_entrega > dias_estimados then 1 else 0 end) * 100.0 / count(*) as porcentaje_fuera_tiempo
from orden_estado
group by estado
order by porcentaje_fuera_tiempo desc;

--===================================
-- 3.5. pagos y facturación
--===================================

-- 3.5.1. ¿qué métodos de pago son más usados por los clientes?

select 
        metodo_pago,
        sum(veces_usado) veces_usado
from vw_info_pagos
group by metodo_pago
order by veces_usado desc;

-- 3.5.2. ¿cuál es el valor promedio de transacción por tipo de pago?

with agrupar_order_pago as(
    select 
            o.order_id,
            op.payment_type as metodo_pago,
            op.payment_value as valor_pago
    from orders as o
    left join order_payments as op on op.order_id = o.order_id
    where op.payment_type is not null
    and op.payment_value is not null
)
select 
        metodo_pago,
        AVG(valor_pago) prom_pago
from agrupar_order_pago
group by metodo_pago
order by prom_pago desc
go

-- 3.5.3. ¿qué porcentaje de órdenes se paga en cuotas vs. pago único?
with pagos_acumulados as (
select 
        order_id,
        count(payment_sequential) as cantidad_pagos 
from order_payments
group by order_id
)
select
        SUM(case  when cantidad_pagos > 1 then 1 else 0 end) as cant_ordenes_pago_cuotas,
        SUM(case  when cantidad_pagos > 1 then 1 else 0 end) * 100.0/count(cantidad_pagos) as porcentaje_ordenes_pago_cuotas,
        SUM(case  when cantidad_pagos = 1 then 1 else 0 end) as cant_ordenes_pago_unicos,
        SUM(case  when cantidad_pagos = 1 then 1 else 0 end) * 100.0/count(cantidad_pagos) as porcentaje_ordenes_pago_unicos,
        count(cantidad_pagos) as total_ordenes
from pagos_acumulados;
go

--===================================
-- 3.6. satisfacción del cliente
--===================================

-- 3.6.1. ¿cuál es el puntaje promedio de reseñas por estado de la orden?

with review_estado as (
select  o.order_id,
        c.customer_state as estado,
        orv.review_score
from  orders as o
inner join customer as c on c.customer_id = o.customer_id
inner join order_reviews as orv on orv.order_id = o.order_id
)
select 
        estado,
        avg(review_score) as puntaje_promedio
from review_estado
group by estado;

/*
NOTA - Puntaje promedio de reseñas por estado:
- Este query calcula el promedio de review_score agrupado por estado del cliente.
- Permite identificar en qué estados los clientes muestran mayor o menor satisfacción.
- Se usa un CTE para organizar la información y luego se agrupa por estado.
- Resultado: ranking de estados con puntajes promedio de reseñas.
*/

-- 3.6.2. ¿qué categorías tienen mayor nivel de devoluciones o reseñas negativas?


with agrupar_categoria_review as (
        select 
                o.order_id,
                vp.categoria_producto,
                orv.review_score
        from orders as o
        inner join order_item as oi on oi.order_id = o.order_id
        inner join vw_info_producto as vp on vp.product_id = oi.product_id
        inner join order_reviews as orv on orv.order_id = o.order_id
        where vp.categoria_producto is not null 
        and orv.review_score is not null 
),
puntaje as(
    select  
            categoria_producto,
            AVG(review_score) as puntaje_promedio
    from agrupar_categoria_review
    group by categoria_producto
)
select *,
       case 
            when puntaje_promedio = 5 then 'Excelente'
            when puntaje_promedio = 4 then 'Muy bueno'
            when puntaje_promedio = 3 then 'Bueno'
            when puntaje_promedio = 2 then 'No tan bueno'
            else 'Malo'
        end as calificacion
from puntaje
order by puntaje_promedio asc;

/*
NOTA - Categorías con reseñas negativas:
- Al agrupar por categoría se observaron registros con valores nulos en review_score o categoría. 
  Por ello, se filtraron únicamente los datos válidos para asegurar consistencia en los resultados.
- En el primer CTE pueden aparecer registros aparentemente duplicados, pero en realidad no lo son: 
  la tabla order_reviews contiene un review_id que permite identificar múltiples reseñas asociadas 
  a una misma orden. Cada review_id corresponde a una evaluación distinta, por lo que se considera 
  un valor independiente.
- Este comportamiento se corrige al calcular el promedio de review_score por categoría, ya que 
  el promedio integra todas las reseñas válidas y refleja la tendencia real de satisfacción.
- El query clasifica las categorías según su puntaje promedio, asignando etiquetas cualitativas 
  (Excelente, Muy bueno, Bueno, No tan bueno, Malo), lo que facilita interpretar cuáles concentran 
  mayor nivel de reseñas negativas o devoluciones.
*/

-- 3.6.3. ¿existe relación entre tiempos de entrega y satisfacción del cliente?
with tiempo_satisfaccion as (
    select  o.order_id,
            c.customer_state,
            c.customer_city,
            datediff(day,o.order_purchase_timestamp,o.order_delivered_customer_date) as tiempo_entrega,
            orv.review_score
    from orders as o
    inner join customer as c on c.customer_id = o.customer_id
    inner join  order_reviews as orv on orv.order_id = o.order_id
    where datediff(day,o.order_purchase_timestamp,o.order_delivered_customer_date) is not null
    and orv.review_score is not null
    and orv.review_score > 0

)
select
      case 
            when tiempo_entrega between 0 and 5 then '0-5 dias'
            when tiempo_entrega between 6 and 10 then '6-10 dias'
            when tiempo_entrega between 11 and 20 then '11-20 dias'
            when tiempo_entrega between 21 and 30 then '21-30 dias'
            else '30+ dias'
      end as rango_tiempo_entrega,
      count(distinct order_id) as cant_ordenes,
      avg(tiempo_entrega) as prom_tiempo_entrega,
      avg(review_score) as prom_review
from tiempo_satisfaccion
group by case 
            when tiempo_entrega between 0 and 5 then '0-5 dias'
            when tiempo_entrega between 6 and 10 then '6-10 dias'
            when tiempo_entrega between 11 and 20 then '11-20 dias'
            when tiempo_entrega between 21 and 30 then '21-30 dias'
            else '30+ dias'
      end
order by rango_tiempo_entrega

/*
NOTA - Relación entre tiempos de entrega y satisfacción:
- Este query agrupa las órdenes en rangos de tiempo de entrega (0-5, 6-10, 11-20, 21-30, 30+ días).
- Calcula el promedio de días de entrega y el promedio de reseñas en cada rango.
- Permite observar si entregas rápidas están asociadas a mejores reseñas y si tiempos largos afectan la satisfacción.
- Se usa count(distinct order_id) para evitar duplicados y asegurar métricas confiables.
*/

--=========================================
-- fin del script
--=========================================