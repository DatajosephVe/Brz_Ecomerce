# 🗄️ Brz Ecommerce — SQL Server Analysis

> **Modelado relacional, vistas analíticas y consultas de negocio sobre +100,000 órdenes de un marketplace brasileño (2016–2018)**  
> Herramientas: SQL Server · T-SQL · SSMS

**Autor:** Joseph Velasco — Data Analyst

---

## 🏷️ Tecnologías

![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-009688?style=for-the-badge)
![SSMS](https://img.shields.io/badge/SSMS-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Kaggle](https://img.shields.io/badge/Dataset-Kaggle-20BEFF?style=for-the-badge&logo=kaggle&logoColor=white)

---

## 📌 Descripción del Proyecto

Este proyecto aplica un flujo completo de ingeniería y análisis de datos sobre el **Brazilian E-Commerce Public Dataset by Olist** (Kaggle), construido íntegramente en SQL Server.

El proyecto demuestra la capacidad de diseñar una base de datos relacional desde cero, construir una capa analítica de vistas optimizadas y responder preguntas de negocio concretas con T-SQL — todo siguiendo buenas prácticas de modelado, integridad referencial y rendimiento de consultas.

> 📊 Este proyecto es la base técnica del análisis visual en Power BI, disponible en:  
> **[Brz Ecommerce — Power BI Analytics](./README.md)**

### ¿Qué hace especial a este proyecto?

El flujo está diseñado en **3 capas progresivas**: Setup → Vistas → Consultas de negocio. Cada capa depende de la anterior, lo que garantiza integridad referencial, reutilización de lógica y consultas más limpias. La tabla de normalización `Geolocation_ZipCode` y los índices compuestos diseñados según patrones de consulta son detalles de modelado avanzado que van más allá de lo básico.

---

## ⚡ Quick Start — Cómo ejecutar el proyecto

Este proyecto está pensado para ejecutarse en **SQL Server** con **SSMS**.

Orden recomendado de ejecución:

**1.** Ejecutar el script de creación y carga de la base de datos:
```
01_Brz_Ecommerce_Database_Setup.sql
```
Crea la base de datos, tablas, claves primarias, foráneas e índices.

**2.** Ejecutar el script de vistas analíticas:
```
02_Brz_Ecommerce_Data_Model_Views.sql
```
Construye las 6 vistas analíticas utilizadas en el proyecto.

**3.** Ejecutar el script de análisis de negocio:
```
03_Brz_Ecommerce_Business_Analysis.sql
```
Responde las 18 preguntas de negocio utilizando las vistas creadas.

> ⚠️ Las consultas del análisis dependen de las vistas del paso 2. Ejecuta los scripts en el orden indicado para evitar errores de dependencia.

---

## 📑 Índice

### 🧭 Instrucciones de navegación

- Los apartados siguen el flujo completo del proyecto: **Setup → Vistas → Consultas de negocio**.
- Puedes volver al índice usando `Ctrl+F` y escribiendo **"📑 Índice"**.

---

- [1 — Creación de la Base de Datos (Setup)](#1--creación-de-la-base-de-datos-setup)
  - [1.1 — Creación de la base de datos](#11--creación-de-la-base-de-datos)
  - [1.2 — Carga de datos](#12--carga-de-datos)
  - [1.3 — Llaves primarias y foráneas](#13--llaves-primarias-y-foráneas)
  - [1.4 — Normalización de geolocalización](#14--normalización-de-geolocalización)
  - [1.5 — Índices](#15--índices)
  - [1.6 — Validaciones](#16--validaciones)
- [2 — Vistas Analíticas (Data Model Views)](#2--vistas-analíticas-data-model-views)
  - [2.1 — Vista base de órdenes (`vw_orders_detail`)](#21--vista-base-de-órdenes-vw_orders_detail)
  - [2.2 — Vista de clientes (`vw_info_clientes`)](#22--vista-de-clientes-vw_info_clientes)
  - [2.3 — Vista de vendedores (`vw_info_vendedores`)](#23--vista-de-vendedores-vw_info_vendedores)
  - [2.4 — Vista de productos (`vw_info_producto`)](#24--vista-de-productos-vw_info_producto)
  - [2.5 — Vista de métodos de pago (`vw_info_pagos`)](#25--vista-de-métodos-de-pago-vw_info_pagos)
  - [2.6 — Vista por zonas (`vw_info_zonas`)](#26--vista-por-zonas-vw_info_zonas)
- [3 — Consultas de Negocio (Business Analysis)](#3--consultas-de-negocio-business-analysis)
  - [3.1 — Clientes y mercado](#31--clientes-y-mercado)
  - [3.2 — Ventas y productos](#32--ventas-y-productos)
  - [3.3 — Vendedores](#33--vendedores)
  - [3.4 — Logística y entregas](#34--logística-y-entregas)
  - [3.5 — Pagos y facturación](#35--pagos-y-facturación)
  - [3.6 — Satisfacción del cliente](#36--satisfacción-del-cliente)
- [4 — Estructura del Repositorio](#4--estructura-del-repositorio)
- [5 — Dataset](#5--dataset)
- [Contacto](#contacto)

---

## 1 — Creación de la Base de Datos (Setup)

### 1.1 — Creación de la base de datos

**Objetivo:** Crear la base de datos `Brz_Ecomerce` en SQL Server y preparar el entorno para cargar las tablas del dataset de Kaggle.

**Qué incluye:** Creación de la base de datos y activación del contexto con `USE Brz_Ecomerce`.

**Supuestos:** Si la base ya existe, se elimina primero con `DROP DATABASE`.

**Uso recomendado:** Ejecutar este bloque como primer paso del proyecto.

```sql
IF DB_ID('Brz_Ecomerce') IS NOT NULL
    DROP DATABASE Brz_Ecomerce;

CREATE DATABASE Brz_Ecomerce;
USE Brz_Ecomerce;
```

---

### 1.2 — Carga de datos

**Objetivo:** Importar los archivos CSV del dataset a las tablas de SQL Server.

**Qué incluye:** Uso del asistente de importación de SSMS para cargar las tablas: `orders`, `customers`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`.

**Supuestos:** Los CSV contienen errores intencionales en tipos de datos que se corrigen en el script posterior. La carga se realiza manualmente con el asistente, no con `BULK INSERT`.

**Uso recomendado:** Importar todos los CSV antes de ejecutar las correcciones de llaves y tipos.

> *(Este paso no tiene query directo — se documenta como procedimiento manual en SSMS.)*

---

### 1.3 — Llaves primarias y foráneas

**Objetivo:** Establecer claves primarias y foráneas para garantizar la integridad referencial del modelo.

**Qué incluye:**
- PK en `orders`, `customers`, `products`, `sellers`, `product_category_name_translation`.
- FK entre `orders → customers`, `order_items → products`, `order_items → sellers`, `order_items → orders`, `order_payments → orders`, `order_reviews → orders`.

**Supuestos:** Se corrigen incompatibilidades de tipo en `customer_id` y `order_id` antes de definir las llaves.

**Uso recomendado:** Ejecutar después de cargar los CSV para garantizar consistencia.

```sql
ALTER TABLE orders
ADD CONSTRAINT PK_orders_Order_Id PRIMARY KEY (order_id);

ALTER TABLE customer
ADD CONSTRAINT PK_customer_Customer_Id PRIMARY KEY (customer_id);

ALTER TABLE orders
ADD CONSTRAINT FK_orders_Customer_Id FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

ALTER TABLE products
ADD CONSTRAINT PK_products_Product_Id PRIMARY KEY (product_id);

ALTER TABLE order_item
ADD CONSTRAINT FK_order_items_Product_Id FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE sellers
ADD CONSTRAINT PK_sellers_Seller_Id PRIMARY KEY (seller_id);

ALTER TABLE order_item
ADD CONSTRAINT FK_order_item_Seller_Id FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_item
ADD CONSTRAINT FK_Order_Item_Order_Id FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
ALTER COLUMN order_id NVARCHAR(100) NOT NULL;

ALTER TABLE order_reviews
ADD CONSTRAINT FK_order_reviews_Order_Id FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE product_category_name_translation
ADD CONSTRAINT PK_product_category_name_translation_Product_Category_Name PRIMARY KEY (product_category_name);

ALTER TABLE products
ADD CONSTRAINT FK_products_Product_Category_Name FOREIGN KEY (product_category_name) REFERENCES product_category_name_translation(product_category_name);
```

---

### 1.4 — Normalización de geolocalización

**Objetivo:** Crear la tabla `Geolocation_ZipCode` para eliminar duplicaciones de códigos postales y relacionar clientes, vendedores y geolocalización con una clave única.

**Qué incluye:**
- Tabla `Geolocation_ZipCode` con PK en `zip_code_prefix`.
- FK desde `customer`, `sellers` y `geolocation` hacia `Geolocation_ZipCode`.

**Supuestos:** Se usa `zip_code_prefix` como clave única de ubicación, mejorando integridad y evitando redundancias en lat/lng.

**Uso recomendado:** Ejecutar después de definir PK/FK en tablas principales.

```sql
CREATE TABLE Geolocation_ZipCode(
    geolocation_zip_code_prefix NVARCHAR(100) PRIMARY KEY
);

INSERT INTO Geolocation_ZipCode(geolocation_zip_code_prefix)
SELECT DISTINCT geolocation_zip_code_prefix
FROM geolocation;

ALTER TABLE customer
ADD CONSTRAINT FK_Customer_ZipCode FOREIGN KEY (customer_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);

ALTER TABLE sellers
ADD CONSTRAINT FK_Sellers_ZipCode FOREIGN KEY (seller_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);

ALTER TABLE geolocation
ADD CONSTRAINT FK_Geolocation_Zipcode FOREIGN KEY (geolocation_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);
```

---

### 1.5 — Índices

**Objetivo:** Optimizar consultas frecuentes mediante índices simples y compuestos diseñados según los patrones de acceso del proyecto.

**Qué incluye:**
- Índices en `customer` (state, city), `orders` (purchase_timestamp, status).
- Índices en `order_items` (product_id, seller_id, order_id).
- Índices en `order_payments` (payment_type, payment_value).
- Índices en `order_reviews` (review_score, order_id, review_id).
- Índices en `products` y `product_category_name_translation`.
- Índices compuestos para joins y agrupaciones por ciudad/estado.

**Uso recomendado:** Ejecutar después de normalizar datos y definir PK/FK.

```sql
CREATE NONCLUSTERED INDEX IX_Customer_State ON customer(customer_state);
CREATE NONCLUSTERED INDEX IX_Customer_City ON customer(customer_city);

CREATE NONCLUSTERED INDEX IX_Orders_Purchase_Timestamp ON orders(order_purchase_timestamp);
CREATE NONCLUSTERED INDEX IX_Orders_Order_Status ON orders(order_status);

CREATE NONCLUSTERED INDEX IX_Order_Item_Product_Id ON order_item(product_id);
CREATE NONCLUSTERED INDEX IX_Order_Item_Seller_Id ON order_item(seller_id);
CREATE NONCLUSTERED INDEX IX_Order_Item_Order_Id ON order_item(order_id);

CREATE NONCLUSTERED INDEX IX_Order_Payments_Payment_Type ON order_payments(payment_type);
CREATE NONCLUSTERED INDEX IX_OrderPayments_Type_Value ON order_payments(payment_type, payment_value);

CREATE NONCLUSTERED INDEX IX_Order_Reviews_Review_Score ON order_reviews(review_score);
CREATE NONCLUSTERED INDEX IX_Order_Reviews_Order_Id ON order_reviews(order_id);
CREATE NONCLUSTERED INDEX IX_Order_Reviews_ReviewID ON order_reviews(review_id);
CREATE NONCLUSTERED INDEX IX_OrderReviews_Order_Score ON order_reviews(order_id, review_score);

CREATE NONCLUSTERED INDEX IX_Products_Product_Category_Name ON products(product_category_name);
CREATE NONCLUSTERED INDEX IX_Product_Category_Name_Translation_Product_Category_Name_English 
ON product_category_name_translation(product_category_name_english);

CREATE NONCLUSTERED INDEX IX_Sellers_Seller_State ON sellers(seller_state);
CREATE NONCLUSTERED INDEX IX_Sellers_Seller_City ON sellers(seller_city);
CREATE NONCLUSTERED INDEX IX_Sellers_City_State ON sellers(seller_city, seller_state);

CREATE NONCLUSTERED INDEX IX_Customer_City_State ON customer(customer_city, customer_state);
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Status ON orders(customer_id, order_status);
```

---

### 1.6 — Validaciones

**Objetivo:** Verificar integridad y consistencia de la base de datos antes de proceder con las vistas.

**Qué incluye:** Conteo total de órdenes, top 10 clientes, status únicos de órdenes y validación de integridad referencial.

**Supuestos:** Si la última consulta devuelve filas, hay errores de integridad que deben corregirse antes de continuar.

**Uso recomendado:** Ejecutar al final del setup para confirmar que la base está lista.

```sql
-- Total de órdenes
SELECT COUNT(*) FROM orders;

-- Top 10 clientes
SELECT TOP 10 * FROM customer;

-- Status únicos de órdenes
SELECT DISTINCT order_status FROM Orders;

-- Validación de integridad
SELECT * FROM orders WHERE customer_id NOT IN(SELECT customer_id FROM customer);
```

---

## 2 — Vistas Analíticas (Data Model Views)

### 2.1 — Vista base de órdenes `vw_orders_detail`

**Objetivo:** Reunir en una sola vista toda la información de una orden: cliente, vendedor, producto, pago, flete y reseña. Sirve como base granular para construir vistas más agregadas.

**Qué incluye:** Identificación de orden e ítem, datos de cliente y vendedor, categoría del producto, tipo y valor de pago, costo de flete y puntaje de reseña.

**Supuestos:**
- Los pagos se integran a nivel de orden (no por ítem) para mantener consistencia.
- Las reseñas se conectan por `order_id`, garantizando que cada orden aporte su evaluación.
- No aplica agregaciones: es la vista más detallada del modelo.

**Uso recomendado:** Usar como base para análisis más específicos — clientes, vendedores, productos, zonas.

```sql
CREATE OR ALTER VIEW vw_orders_detail AS
SELECT 
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp AS fecha_compra,
    o.order_approved_at AS fecha_aprobacion,
    o.order_delivered_carrier_date AS fecha_envio_transportista,
    o.order_estimated_delivery_date AS fecha_entrega_estimada,
    oi.shipping_limit_date AS fecha_limite_envio,
    o.order_delivered_customer_date AS fecha_entrega_cliente,
    p.product_id,
    pct.product_category_name_english AS categoria_producto,
    oi.order_item_id,
    orv.review_score AS puntaje_resena,
    pg.payment_type AS tipo_pago,
    pg.payment_value AS valor_pago,
    oi.price AS precio,
    oi.freight_value AS valor_flete,
    c.customer_id,
    c.customer_zip_code_prefix AS codigo_postal_cliente,
    c.customer_city AS ciudad_cliente,
    c.customer_state AS estado_cliente,
    s.seller_id,
    s.seller_zip_code_prefix AS codigo_postal_vendedor,
    s.seller_city AS ciudad_vendedor,
    s.seller_state AS estado_vendedor
FROM orders AS o
LEFT JOIN order_item AS oi ON o.order_id = oi.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation AS pct ON p.product_category_name = pct.product_category_name
LEFT JOIN order_payments AS pg ON o.order_id = pg.order_id
LEFT JOIN customer AS c ON o.customer_id = c.customer_id
LEFT JOIN sellers AS s ON oi.seller_id = s.seller_id
LEFT JOIN order_reviews AS orv ON orv.order_id = o.order_id;
GO
```

---

### 2.2 — Vista de clientes `vw_info_clientes`

**Objetivo:** Crear un perfil de cada cliente con métricas de compra, reseñas y costos de flete.

**Qué incluye:** Total de productos comprados, ticket promedio por producto, total gastado en compras y en flete, porcentaje del flete sobre el total de compra y cantidad de reseñas.

**Supuestos:**
- Se eliminó la dependencia de la tabla `geolocation` para evitar duplicados.
- Se agrupan métricas a nivel de cliente para obtener resultados consistentes.

**Uso recomendado:** Identificar clientes más valiosos y analizar comportamiento de compra.

```sql
CREATE OR ALTER VIEW vw_info_clientes AS
WITH cliente_base AS (
    SELECT
        c.customer_id,
        c.customer_zip_code_prefix AS codigo_postal_cliente,
        c.customer_city AS ciudad_cliente,
        c.customer_state AS estado_cliente,
        oi.order_item_id,
        p.payment_value AS valor_pago,
        oi.freight_value AS valor_flete,
        r.review_score AS puntaje_resena
    FROM customer AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    LEFT JOIN order_item AS oi ON o.order_id = oi.order_id
    LEFT JOIN order_payments AS p ON o.order_id = p.order_id
    LEFT JOIN order_reviews AS r ON o.order_id = r.order_id
)
SELECT
    customer_id,
    codigo_postal_cliente,
    ciudad_cliente,
    estado_cliente,
    COUNT(puntaje_resena) AS cantidad_resenas,
    COUNT(DISTINCT order_item_id) AS total_productos_comprados,
    SUM(valor_pago) * 1.0 / NULLIF(COUNT(DISTINCT order_item_id), 0) AS ticket_promedio_por_producto,
    SUM(valor_pago) AS total_compra_cliente,
    SUM(valor_flete) AS total_pago_flete,
    (SUM(valor_flete) * 100.0 / NULLIF(SUM(valor_pago), 0)) AS porcentaje_flete_sobre_compra
FROM cliente_base
GROUP BY customer_id, codigo_postal_cliente, ciudad_cliente, estado_cliente;
GO
```

---

### 2.3 — Vista de vendedores `vw_info_vendedores`

**Objetivo:** Resumir el desempeño de cada vendedor en ventas, alcance de clientes y reseñas.

**Qué incluye:** Número de órdenes atendidas, total de unidades vendidas, total de ventas y ticket promedio, alcance geográfico (clientes, ciudades y estados atendidos), y cantidad y promedio de reseñas.

**Supuestos:** Los pagos y reseñas se pre-agregan por orden para evitar duplicaciones.

**Uso recomendado:** Identificar vendedores más exitosos y evaluar concentración del mercado.

```sql
CREATE OR ALTER VIEW vw_info_vendedores AS
WITH pagos_por_orden AS (
    SELECT order_id, SUM(payment_value) AS total_pago
    FROM order_payments
    GROUP BY order_id
),
resenas_por_orden AS (
    SELECT order_id, AVG(review_score) AS promedio_resena, COUNT(review_score) AS cantidad_resenas
    FROM order_reviews
    GROUP BY order_id
),
items_por_vendedor AS (
    SELECT
        s.seller_id,
        s.seller_zip_code_prefix AS codigo_postal_vendedor,
        s.seller_city AS ciudad_vendedor,
        s.seller_state AS estado_vendedor,
        o.order_id,
        oi.order_item_id,
        c.customer_id,
        c.customer_city AS ciudad_cliente,
        c.customer_state AS estado_cliente
    FROM sellers AS s
    INNER JOIN order_item AS oi ON s.seller_id = oi.seller_id
    INNER JOIN orders AS o ON oi.order_id = o.order_id
    LEFT JOIN customer AS c ON o.customer_id = c.customer_id
)
SELECT
    i.seller_id,
    i.codigo_postal_vendedor,
    i.ciudad_vendedor,
    i.estado_vendedor,
    COUNT(DISTINCT i.order_id) AS cant_ordenes,
    COUNT(DISTINCT i.order_item_id) AS total_unidades_vendidas,
    COUNT(DISTINCT i.customer_id) AS cant_clientes_atendidos,
    COUNT(DISTINCT i.ciudad_cliente) AS cant_ciudades_atendidas,
    COUNT(DISTINCT i.estado_cliente) AS cant_estados_atendidos,
    SUM(p.total_pago) AS total_ventas,
    SUM(p.total_pago) * 1.0 / NULLIF(COUNT(DISTINCT i.order_id), 0) AS ticket_promedio_por_orden,
    COUNT(DISTINCT i.customer_id) * 1.0 / NULLIF(COUNT(DISTINCT i.ciudad_cliente), 0) AS promedio_clientes_por_ciudad,
    SUM(r.cantidad_resenas) AS total_resenas,
    AVG(r.promedio_resena) AS promedio_resena
FROM items_por_vendedor AS i
LEFT JOIN pagos_por_orden AS p ON i.order_id = p.order_id
LEFT JOIN resenas_por_orden AS r ON i.order_id = r.order_id
GROUP BY i.seller_id, i.codigo_postal_vendedor, i.ciudad_vendedor, i.estado_vendedor;
GO
```

---

### 2.4 — Vista de productos `vw_info_producto`

**Objetivo:** Resumir información de productos vendidos, agrupada por categoría y región del cliente, con métricas de precio y volumen de ventas.

**Qué incluye:** Precios mínimos, máximos y promedio, total acumulado de ventas, número de órdenes únicas y unidades vendidas.

**Supuestos:**
- Se usan `LEFT JOIN` para incluir registros incompletos y detectar huecos en la información.
- Vista refleja datos reales sin duplicaciones.

**Uso recomendado:** Analizar comportamiento de productos y categorías, detectar variaciones de precio y volumen.

```sql
CREATE OR ALTER VIEW vw_info_producto AS
WITH items_unicos AS (
    SELECT DISTINCT 
        o.order_id,
        oi.order_item_id,
        oi.product_id,
        pc.product_category_name_english AS categoria_producto,
        oi.price AS precio,
        c.customer_city AS ciudad_cliente,
        c.customer_state AS estado_cliente
    FROM orders AS o
    LEFT JOIN order_item AS oi ON o.order_id = oi.order_id
    LEFT JOIN customer AS c ON c.customer_id = o.customer_id
    LEFT JOIN products AS p ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation AS pc ON pc.product_category_name = p.product_category_name
)
SELECT  
    product_id,
    categoria_producto,
    estado_cliente AS estado,
    ciudad_cliente AS ciudad,
    MIN(precio) AS precio_minimo,
    MAX(precio) AS precio_maximo,
    AVG(precio) AS precio_promedio,
    SUM(precio) AS total_acumulado_real,
    COUNT(DISTINCT order_id) AS total_ordenes_del_producto,
    COUNT(*) AS total_unidades_vendidas
FROM items_unicos
GROUP BY product_id, categoria_producto, ciudad_cliente, estado_cliente;
GO

-- Ejemplo de uso: top 10 productos con mayor acumulado de ventas
SELECT TOP 10 *
FROM vw_info_producto
ORDER BY total_acumulado_real DESC;
```

---

### 2.5 — Vista de métodos de pago `vw_info_pagos`

**Objetivo:** Resumir el uso de métodos de pago por ciudad y estado con métricas limpias y reales sobre cómo los clientes pagan sus órdenes.

**Qué incluye:** Método de pago, cantidad de órdenes únicas, número total de veces usado y total pagado por cada método.

**Supuestos:** Cada orden se cuenta una sola vez. Los pagos reflejan montos reales sin duplicaciones.

**Uso recomendado:** Identificar métodos de pago más populares y analizar diferencias por región.

```sql
CREATE OR ALTER VIEW vw_info_pagos AS
WITH agrupar_pago AS (
    SELECT  
        o.order_id,
        oi.order_item_id,
        p.payment_type AS metodo_pago,
        p.payment_value AS valor_pago,
        c.customer_state AS estado_cliente,
        c.customer_city AS ciudad_cliente
    FROM orders o
    INNER JOIN order_payments AS p ON o.order_id = p.order_id
    INNER JOIN order_item AS oi ON o.order_id = oi.order_id
    INNER JOIN customer AS c ON o.customer_id = c.customer_id
)
SELECT
    metodo_pago,
    estado_cliente,
    ciudad_cliente,
    COUNT(DISTINCT order_id) AS cantidad_de_ordenes,
    COUNT(*) AS veces_usado,
    SUM(valor_pago) AS total_pagado
FROM agrupar_pago
GROUP BY metodo_pago, estado_cliente, ciudad_cliente;
GO

-- Ejemplo: ciudad con mayor volumen de pagos por método
WITH ciudad_top AS (
    SELECT 
        metodo_pago,
        ciudad_cliente,
        estado_cliente,
        SUM(total_pagado) AS total_pagado_ciudad,
        SUM(cantidad_de_ordenes) AS cant_ordenes,
        ROW_NUMBER() OVER(PARTITION BY metodo_pago ORDER BY SUM(total_pagado) DESC) AS rn
    FROM vw_info_pagos
    GROUP BY metodo_pago, ciudad_cliente, estado_cliente
)
SELECT 
    metodo_pago,
    ciudad_cliente AS ciudad_mas_vendedora,
    estado_cliente,
    cant_ordenes,
    total_pagado_ciudad
FROM ciudad_top
WHERE rn = 1
ORDER BY total_pagado_ciudad DESC;
```

---

### 2.6 — Vista por zonas `vw_info_zonas`

**Objetivo:** Resumir información de ventas y entregas por ciudad y código postal, consolidando pagos, ítems, tiempos de entrega y reseñas en una sola vista.

**Qué incluye:** Total de pagos y promedio por orden, cantidad de clientes y vendedores únicos, total de órdenes y productos vendidos, puntaje promedio de reseñas, y tiempos y costos de flete (mínimo, máximo y promedio).

**Supuestos:** Cada orden se consolida primero en un CTE para evitar duplicaciones. Solo se incluyen órdenes con fechas de compra y entrega válidas.

**Uso recomendado:** Identificar zonas con mayor volumen de ventas y analizar desempeño logístico por región.

```sql
CREATE OR ALTER VIEW vw_info_zonas AS
WITH geo_unicos AS (
    SELECT DISTINCT 
        g.geolocation_zip_code_prefix,
        g.geolocation_city,
        g.geolocation_state
    FROM geolocation AS g
),
ordenes_unicas AS (
    SELECT 
        o.order_id,
        c.customer_id,
        oi.seller_id,
        c.customer_zip_code_prefix AS codigo_postal_cliente,
        MIN(o.order_purchase_timestamp) AS fecha_compra,
        MAX(o.order_delivered_customer_date) AS fecha_entrega_cliente,
        SUM(p.payment_value) AS total_pago_orden,
        AVG(r.review_score) AS puntaje_prom_resena,
        AVG(oi.freight_value) AS costo_prom_flete,
        MIN(oi.freight_value) AS costo_min_flete,
        MAX(oi.freight_value) AS costo_max_flete,
        COUNT(oi.order_item_id) AS total_items_orden
    FROM orders o
    INNER JOIN customer AS c ON o.customer_id = c.customer_id
    INNER JOIN order_payments AS p ON o.order_id = p.order_id
    INNER JOIN order_item AS oi ON o.order_id = oi.order_id
    LEFT JOIN order_reviews AS r ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL 
      AND o.order_purchase_timestamp IS NOT NULL
      AND DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) >= 0
    GROUP BY o.order_id, c.customer_zip_code_prefix, c.customer_id, oi.seller_id
)
SELECT
    g.geolocation_state AS estado,
    g.geolocation_city AS ciudad,
    g.geolocation_zip_code_prefix AS codigo_zip,
    COUNT(DISTINCT o.customer_id) AS cant_clientes,
    COUNT(DISTINCT o.seller_id) AS cant_vendedores,
    SUM(o.total_pago_orden) AS total_pagado,
    AVG(o.total_pago_orden) AS pago_promedio,
    COUNT(DISTINCT o.order_id) AS total_ordenes,
    SUM(o.total_items_orden) AS total_items_vendidos,
    AVG(o.puntaje_prom_resena) AS puntaje_prom_resena_por_orden,
    MIN(DATEDIFF(DAY, o.fecha_compra, o.fecha_entrega_cliente)) AS cant_dias_min_de_entrega,
    MAX(DATEDIFF(DAY, o.fecha_compra, o.fecha_entrega_cliente)) AS cant_dias_max_de_entrega,
    AVG(DATEDIFF(DAY, o.fecha_compra, o.fecha_entrega_cliente)) AS cant_dias_prom_de_entrega,
    MIN(o.costo_min_flete) AS costo_min_flete,
    MAX(o.costo_max_flete) AS costo_max_flete,
    AVG(o.costo_prom_flete) AS costo_prom_flete
FROM geo_unicos AS g
LEFT JOIN ordenes_unicas AS o ON g.geolocation_zip_code_prefix = o.codigo_postal_cliente
GROUP BY g.geolocation_city, g.geolocation_state, g.geolocation_zip_code_prefix;
GO

-- Ejemplo de uso: top 5 zonas con mayor volumen de pagos
SELECT TOP 5 *
FROM vw_info_zonas
ORDER BY total_pagado DESC;
```

---

## 3 — Consultas de Negocio (Business Analysis)

### 3.1 — Clientes y mercado

*Análisis del alcance geográfico y la expansión de la base de usuarios.*

---

#### 3.1.1 — ¿Qué estados concentran la mayor cantidad de clientes?

**Objetivo:** Mostrar los estados con mayor concentración de clientes a partir de `vw_info_zonas`.

**Supuestos:** `vw_info_zonas` ya consolida órdenes/clientes por zona y evita duplicaciones. El resultado refleja concentración de la base de clientes, no transacciones ni ingresos.

**Uso recomendado:** Identificar mercados grandes y priorizar acciones de marketing o logística.

```sql
SELECT TOP 10
    estado, 
    SUM(cant_clientes) AS cant_clientes
FROM vw_info_zonas
GROUP BY estado
ORDER BY SUM(cant_clientes) DESC;
```

> **Resultado clave:** SP lidera con 40,300 clientes (~41% del mercado), seguido por RJ con 12,380.

---

#### 3.1.2 — ¿Cómo evoluciona la adquisición de nuevos clientes mes a mes?

**Objetivo:** Calcular la adquisición de clientes mes a mes y medir el porcentaje de crecimiento respecto al mes anterior.

**Supuestos:** Un cliente se considera "nuevo" en el mes de su primera compra. Si el mes anterior tiene 0 clientes o no existe, se muestra `NULL` para evitar división por cero.

**Uso recomendado:** Evaluar campañas de adquisición y detectar estacionalidad.

```sql
WITH primeras_compras AS (
    SELECT 
        customer_id,
        MIN(fecha_compra) AS fecha_primer_compra
    FROM vw_orders_detail
    GROUP BY customer_id
),
clientes_mensuales AS (
    SELECT
        YEAR(fecha_primer_compra) AS anio_compra,
        MONTH(fecha_primer_compra) AS mes_compra,
        COUNT(customer_id) AS nuevos_clientes
    FROM primeras_compras
    GROUP BY YEAR(fecha_primer_compra), MONTH(fecha_primer_compra)
),
clientes_lag AS (
    SELECT  
        anio_compra,
        mes_compra,
        nuevos_clientes,
        LAG(nuevos_clientes) OVER (ORDER BY anio_compra, mes_compra) AS clientes_mes_anterior
    FROM clientes_mensuales
)
SELECT *,
    CASE 
        WHEN clientes_mes_anterior IS NULL THEN NULL
        WHEN clientes_mes_anterior = 0 THEN NULL
        ELSE ((nuevos_clientes - clientes_mes_anterior) * 100.0) / clientes_mes_anterior
    END AS porcentaje_crecimiento
FROM clientes_lag
ORDER BY anio_compra, mes_compra;
GO
```

> **Resultado clave:** Crecimiento del 13,308.9% en 2016→2017 y 20.7% en 2017→2018.

---

#### 3.1.3 — ¿Cuáles son las ciudades con mayor volumen de clientes?

**Objetivo:** Mostrar las ciudades con mayor cantidad de clientes únicos según `vw_info_zonas`.

**Uso recomendado:** Operaciones locales, logística y segmentación por ciudad.

```sql
SELECT TOP 10
    ciudad, 
    SUM(cant_clientes) AS cant_clientes
FROM vw_info_zonas
GROUP BY ciudad
ORDER BY SUM(cant_clientes) DESC;
```

> **Resultado clave:** São Paulo lidera con $2,200,000 en volumen de venta, seguida de Rio de Janeiro con $1,160,000.

---

### 3.2 — Ventas y productos

*Identificación de los motores de ingresos y preferencias del consumidor.*

---

#### 3.2.1 — ¿Qué categorías tienen mayor y menor rotación de productos?

**Objetivo:** Identificar las categorías con mayor número de unidades vendidas y aquellas con menor rotación.

**Supuestos:** Se usa `vw_info_producto`. El conteo refleja unidades vendidas, no ingresos monetarios.

```sql
-- Categorías con mayor rotación
SELECT TOP 10 
    categoria_producto,
    SUM(total_unidades_vendidas) AS cant_unidades_vendidas
FROM vw_info_producto
GROUP BY categoria_producto
ORDER BY cant_unidades_vendidas DESC;

-- Categorías con menor rotación
SELECT TOP 10 
    categoria_producto,
    SUM(total_unidades_vendidas) AS cant_unidades_vendidas
FROM vw_info_producto
GROUP BY categoria_producto
ORDER BY cant_unidades_vendidas ASC;
```

> **Resultado clave:** `bed_bath_table` lidera con 11,115 unidades; `health_beauty` en segundo lugar con 9,670.

---

#### 3.2.2 — ¿Cuál es el ticket promedio por cliente y por orden?

**Objetivo:** Calcular el ticket promedio de compra por cliente y por orden.

**Supuestos:** Se usa `vw_info_clientes` para el cálculo por cliente y las tablas base para el cálculo por orden.

```sql
-- Ticket promedio por cliente
SELECT  
    customer_id,
    SUM(total_compra_cliente) / NULLIF(SUM(total_productos_comprados), 0) AS ticket_promedio_cliente
FROM vw_info_clientes
GROUP BY customer_id
ORDER BY ticket_promedio_cliente DESC;

-- Ticket promedio por orden
SELECT 
    o.order_id,
    SUM(op.payment_value) / NULLIF(COUNT(oi.order_item_id), 0) AS ticket_promedio
FROM order_payments AS op
INNER JOIN orders AS o ON o.order_id = op.order_id
INNER JOIN order_item AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id
ORDER BY ticket_promedio DESC;
```

> **Resultado clave:** Ticket promedio general de $161.07 por cliente.

---

#### 3.2.3 — ¿Qué productos concentran el mayor valor de ventas neto (descontando flete)?

**Objetivo:** Identificar los productos que generan mayor valor de ventas aproximado, descontando el costo de flete.

**Supuestos:** El campo `total_acumulado_real` representa el pago total a nivel de orden. El análisis por producto es una aproximación ya que el dataset no proporciona el valor pagado por ítem individual.

```sql
SELECT TOP 10
    vp.product_id,
    SUM(vp.total_acumulado_real) AS total_venta,
    SUM(oi.freight_value) AS total_flete,
    SUM(vp.total_acumulado_real) - SUM(oi.freight_value) AS total_acumulado_menos_flete
FROM vw_info_producto AS vp
LEFT JOIN order_item AS oi ON oi.product_id = vp.product_id
GROUP BY vp.product_id
ORDER BY total_acumulado_menos_flete DESC;
```

---

#### 3.2.4 — ¿Qué porcentaje de las ventas proviene del Top 10 de categorías?

**Objetivo:** Calcular qué porcentaje del total de ventas proviene de las 10 categorías más importantes.

```sql
-- Con CTE
WITH rankedcategorias AS (
    SELECT 
        categoria_producto,
        SUM(total_acumulado_real) AS totalventas,
        ROW_NUMBER() OVER (ORDER BY SUM(total_acumulado_real) DESC) AS rn
    FROM vw_info_producto
    GROUP BY categoria_producto
)
SELECT 
    SUM(CASE WHEN rn <= 10 THEN totalventas ELSE 0 END) * 100.0 / SUM(totalventas) AS porcentaje_top10,
    SUM(CASE WHEN rn > 10 THEN totalventas ELSE 0 END) * 100.0 / SUM(totalventas) AS porcentaje_resto
FROM rankedcategorias;
GO
```

---

### 3.3 — Vendedores

*Evaluación del ecosistema de socios y eficiencia operativa.*

---

#### 3.3.1 — ¿Qué vendedores concentran el mayor número de órdenes?

**Objetivo:** Identificar los vendedores que gestionan más órdenes en el marketplace.

**Supuestos:** Se detectaron 833 órdenes sin `seller_id`, documentadas en la nota técnica del script.

```sql
SELECT TOP 10
    seller_id,
    COUNT(DISTINCT order_id) AS cantidad_ordenes,
    DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT order_id) DESC) AS rango
FROM vw_orders_detail
GROUP BY seller_id;
```

> **Resultado clave:** El vendedor líder gestiona 1,841 órdenes; el segundo lugar 1,754.

---

#### 3.3.2 — ¿Cuál es el nivel de concentración del mercado en el Top 10 vendedores?

**Objetivo:** Calcular el porcentaje de ventas y órdenes en manos de los 10 principales vendedores.

```sql
WITH rango_vendedores AS (
    SELECT  
        seller_id,
        SUM(total_ventas) AS total_venta,
        SUM(cant_ordenes) AS cant_ordenes,
        ROW_NUMBER() OVER(ORDER BY SUM(total_ventas) DESC) AS rn
    FROM vw_info_vendedores
    GROUP BY seller_id
)
SELECT 
    SUM(CASE WHEN rn <= 10 THEN total_venta ELSE 0 END) * 100.0 / SUM(total_venta) AS [% top 10 vendedores],
    SUM(CASE WHEN rn <= 10 THEN cant_ordenes ELSE 0 END) AS [cant. ordenes top 10],
    SUM(CASE WHEN rn > 10 THEN total_venta ELSE 0 END) * 100.0 / SUM(total_venta) AS [% resto de vendedores],
    SUM(CASE WHEN rn > 10 THEN cant_ordenes ELSE 0 END) AS [cant. ordenes resto vendedores]
FROM rango_vendedores;
GO
```

> **Resultado clave:** El Top 10 concentra solo el **7.28%** del mercado — señal de un ecosistema competitivo y saludable.

---

#### 3.3.3 — ¿Qué vendedores tienen mejor desempeño en tiempos de entrega?

**Objetivo:** Identificar vendedores con mejores tiempos de entrega promedio para los pedidos con más de 50 órdenes.

```sql
WITH vendedores AS (
    SELECT  
        seller_id,
        DATEDIFF(DAY, fecha_compra, fecha_entrega_cliente) AS dias_de_entrega
    FROM vw_orders_detail
    WHERE seller_id IS NOT NULL
      AND fecha_compra IS NOT NULL
      AND fecha_entrega_cliente IS NOT NULL
      AND DATEDIFF(DAY, fecha_compra, fecha_entrega_cliente) > 0
)
SELECT TOP 10 
    seller_id,
    AVG(dias_de_entrega) AS promedio_dias_entrega,
    DENSE_RANK() OVER(ORDER BY AVG(dias_de_entrega)) AS ranking
FROM vendedores
GROUP BY seller_id
ORDER BY promedio_dias_entrega ASC;
```

> **Resultado clave:** El mejor vendedor entrega en promedio en **5 días**, frente a la media general de 12.5 días.

---

### 3.4 — Logística y entregas

*Análisis de cumplimiento de tiempos y distribución geográfica.*

---

#### 3.4.1 — ¿Cuál es el tiempo promedio de entrega por estado y por categoría de producto?

**Objetivo:** Calcular el tiempo promedio de entrega agrupado por estado y por categoría de producto.

```sql
-- Por estado
SELECT  
    estado,
    AVG(cant_dias_prom_de_entrega) AS dias_prom_de_entrega
FROM vw_info_zonas
GROUP BY estado
ORDER BY dias_prom_de_entrega;

-- Por categoría de producto
SELECT  
    categoria_producto,
    AVG(DATEDIFF(DAY, fecha_compra, fecha_entrega_cliente)) AS dia_prom_de_entrega
FROM vw_orders_detail
WHERE categoria_producto IS NOT NULL
GROUP BY categoria_producto;

-- Por estado y categoría combinados
SELECT  
    estado_cliente,
    categoria_producto,
    AVG(DATEDIFF(DAY, fecha_compra, fecha_entrega_cliente)) AS dia_prom_de_entrega
FROM vw_orders_detail
GROUP BY estado_cliente, categoria_producto;
```

> **Resultado clave:** SP entrega en mínimo 8.70 días; RR en máximo 29.34 días.

---

#### 3.4.2 — ¿Qué porcentaje de órdenes se entregan dentro del tiempo estimado (SLA)?

**Objetivo:** Calcular el porcentaje de órdenes entregadas dentro del tiempo estimado.

```sql
WITH tiempo AS (
    SELECT 
        order_id,
        DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS tiempo_entrega_dias,
        DATEDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date) AS tiempo_estimado_dias
    FROM orders
    WHERE order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT 
    COUNT(*) AS total_ordenes,
    SUM(CASE WHEN tiempo_entrega_dias <= tiempo_estimado_dias THEN 1 ELSE 0 END) AS ordenes_a_tiempo,
    SUM(CASE WHEN tiempo_entrega_dias > tiempo_estimado_dias THEN 1 ELSE 0 END) AS ordenes_fuera_tiempo,
    SUM(CASE WHEN tiempo_entrega_dias <= tiempo_estimado_dias THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS porcentaje_a_tiempo,
    SUM(CASE WHEN tiempo_entrega_dias > tiempo_estimado_dias THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS porcentaje_fuera_tiempo
FROM tiempo;
GO
```

> **Resultado clave:** **90.8%** de las órdenes (89,944 de 99,000) se entregaron dentro del SLA estimado.

---

#### 3.4.3 — ¿Qué estados tienen el mayor índice de entregas fuera del tiempo estimado?

**Objetivo:** Identificar las regiones con más problemas de entregas tardías.

```sql
WITH orden_estado AS (
    SELECT  
        o.order_id,
        s.seller_state AS estado,
        MIN(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS dias_entrega,
        MIN(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date)) AS dias_estimados
    FROM orders AS o
    INNER JOIN order_item AS oi ON oi.order_id = o.order_id
    INNER JOIN sellers AS s ON s.seller_id = oi.seller_id
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY o.order_id, s.seller_state
)
SELECT 
    estado,
    COUNT(*) AS total_ordenes,
    SUM(CASE WHEN dias_entrega > dias_estimados THEN 1 ELSE 0 END) AS ordenes_fuera_tiempo,
    SUM(CASE WHEN dias_entrega > dias_estimados THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS porcentaje_fuera_tiempo
FROM orden_estado
GROUP BY estado
ORDER BY porcentaje_fuera_tiempo DESC;
```

> **Resultado clave:** AL (21.41%), MA (17.43%) y SE (15.22%) lideran los retrasos — todos en el noreste del país.

---

### 3.5 — Pagos y facturación

*Análisis de preferencias financieras y modalidades de pago.*

---

#### 3.5.1 — ¿Qué métodos de pago prefieren los clientes?

**Objetivo:** Identificar los métodos de pago más utilizados en las órdenes.

```sql
SELECT 
    metodo_pago,
    SUM(veces_usado) AS veces_usado
FROM vw_info_pagos
GROUP BY metodo_pago
ORDER BY veces_usado DESC;
```

> **Resultado clave:** La tarjeta de crédito domina ampliamente, seguida por el boleto bancario.

---

#### 3.5.2 — ¿Cuál es el valor promedio de transacción por tipo de pago?

**Objetivo:** Calcular el valor promedio de transacción según el método de pago.

```sql
WITH agrupar_order_pago AS (
    SELECT 
        o.order_id,
        op.payment_type AS metodo_pago,
        op.payment_value AS valor_pago
    FROM orders AS o
    LEFT JOIN order_payments AS op ON op.order_id = o.order_id
    WHERE op.payment_type IS NOT NULL
      AND op.payment_value IS NOT NULL
)
SELECT 
    metodo_pago,
    AVG(valor_pago) AS prom_pago
FROM agrupar_order_pago
GROUP BY metodo_pago
ORDER BY prom_pago DESC;
GO
```

> **Resultado clave:** Tarjeta de crédito lidera con ticket promedio de $163.32, frente a $65.70 del voucher.

---

#### 3.5.3 — ¿Qué porcentaje de órdenes se paga en cuotas vs. pago único?

**Objetivo:** Calcular qué porcentaje de órdenes se paga en cuotas frente a pago único.

```sql
WITH pagos_acumulados AS (
    SELECT 
        order_id,
        COUNT(payment_sequential) AS cantidad_pagos 
    FROM order_payments
    GROUP BY order_id
)
SELECT
    SUM(CASE WHEN cantidad_pagos > 1 THEN 1 ELSE 0 END) AS cant_ordenes_pago_cuotas,
    SUM(CASE WHEN cantidad_pagos > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(cantidad_pagos) AS porcentaje_cuotas,
    SUM(CASE WHEN cantidad_pagos = 1 THEN 1 ELSE 0 END) AS cant_ordenes_pago_unicos,
    SUM(CASE WHEN cantidad_pagos = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(cantidad_pagos) AS porcentaje_pago_unico,
    COUNT(cantidad_pagos) AS total_ordenes
FROM pagos_acumulados;
GO
```

> **Resultado clave:** El **96.94%** de las órdenes se paga en una sola transacción.

---

### 3.6 — Satisfacción del cliente

*Correlación entre la operatividad logística y la percepción del usuario.*

---

#### 3.6.1 — ¿Cuál es el puntaje promedio de reseñas por estado del cliente?

**Objetivo:** Calcular el puntaje promedio de reseñas agrupado por estado del cliente e identificar diferencias regionales de satisfacción.

```sql
WITH review_estado AS (
    SELECT  
        o.order_id,
        c.customer_state AS estado,
        orv.review_score
    FROM orders AS o
    INNER JOIN customer AS c ON c.customer_id = o.customer_id
    INNER JOIN order_reviews AS orv ON orv.order_id = o.order_id
)
SELECT 
    estado,
    AVG(review_score) AS puntaje_promedio
FROM review_estado
GROUP BY estado;
```

> **Resultado clave:** Puntaje promedio general de **4.09/5.00**, con el 57% de reseñas en puntuación máxima (5 estrellas).

---

#### 3.6.2 — ¿Qué categorías concentran más reseñas negativas?

**Objetivo:** Identificar las categorías de producto con más reseñas negativas o devoluciones.

**Supuestos:** La tabla `order_reviews` puede contener múltiples reseñas por orden, cada una con su propio `review_id`. El promedio integra todas las reseñas válidas.

> ⚠️ **Nota técnica:** La clasificación usa comparaciones de enteros exactos sobre `AVG(review_score)`. Como los promedios son decimales (ej: 3.8, 4.2), casi todos los registros caerán en la categoría `Malo`. Se recomienda usar rangos con `BETWEEN` en una versión futura.

```sql
WITH agrupar_categoria_review AS (
    SELECT 
        o.order_id,
        vp.categoria_producto,
        orv.review_score
    FROM orders AS o
    INNER JOIN order_item AS oi ON oi.order_id = o.order_id
    INNER JOIN vw_info_producto AS vp ON vp.product_id = oi.product_id
    INNER JOIN order_reviews AS orv ON orv.order_id = o.order_id
    WHERE vp.categoria_producto IS NOT NULL 
      AND orv.review_score IS NOT NULL 
),
puntaje AS (
    SELECT  
        categoria_producto,
        AVG(review_score) AS puntaje_promedio
    FROM agrupar_categoria_review
    GROUP BY categoria_producto
)
SELECT *,
    CASE 
        WHEN puntaje_promedio = 5 THEN 'Excelente'
        WHEN puntaje_promedio = 4 THEN 'Muy bueno'
        WHEN puntaje_promedio = 3 THEN 'Bueno'
        WHEN puntaje_promedio = 2 THEN 'No tan bueno'
        ELSE 'Malo'
    END AS calificacion
FROM puntaje
ORDER BY puntaje_promedio ASC;
```

---

#### 3.6.3 — ¿Existe relación entre tiempos de entrega y satisfacción del cliente?

**Objetivo:** Analizar si existe correlación entre tiempos de entrega y puntaje de reseñas, agrupando órdenes en rangos de tiempo.

```sql
WITH tiempo_satisfaccion AS (
    SELECT  
        o.order_id,
        c.customer_state,
        c.customer_city,
        DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS tiempo_entrega,
        orv.review_score
    FROM orders AS o
    INNER JOIN customer AS c ON c.customer_id = o.customer_id
    INNER JOIN order_reviews AS orv ON orv.order_id = o.order_id
    WHERE DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) IS NOT NULL
      AND orv.review_score IS NOT NULL
      AND orv.review_score > 0
)
SELECT
    CASE 
        WHEN tiempo_entrega BETWEEN 0 AND 5 THEN '0-5 días'
        WHEN tiempo_entrega BETWEEN 6 AND 10 THEN '6-10 días'
        WHEN tiempo_entrega BETWEEN 11 AND 20 THEN '11-20 días'
        WHEN tiempo_entrega BETWEEN 21 AND 30 THEN '21-30 días'
        ELSE '30+ días'
    END AS rango_tiempo_entrega,
    COUNT(DISTINCT order_id) AS cant_ordenes,
    AVG(tiempo_entrega) AS prom_tiempo_entrega,
    AVG(review_score) AS prom_review
FROM tiempo_satisfaccion
GROUP BY 
    CASE 
        WHEN tiempo_entrega BETWEEN 0 AND 5 THEN '0-5 días'
        WHEN tiempo_entrega BETWEEN 6 AND 10 THEN '6-10 días'
        WHEN tiempo_entrega BETWEEN 11 AND 20 THEN '11-20 días'
        WHEN tiempo_entrega BETWEEN 21 AND 30 THEN '21-30 días'
        ELSE '30+ días'
    END
ORDER BY rango_tiempo_entrega;
```

> **Conclusión:** El tiempo de entrega influye, pero no es el único factor. AM entrega en 26 días con reseña de 4.21; RR entrega en 29 días con reseña de 3.61 — la calidad de atención durante la espera marca la diferencia.

---

## 4 — Estructura del Repositorio

```
📁 Proyecto2-BrzEcommerce/
│
├── 📝 README_SQL.md                      ← Este archivo (SQL Server)
├── 📝 README_BRZ_PowerBI.md              ← Documentación Power BI
├── 📋 BRZ_Ecommerce_Documentacion.pdf        ← Documentación ejecutiva completa
│
├── 🗄️ 01_Brz_Ecommerce_Database_Setup.sql
├── 🗄️ 02_Brz_Ecommerce_Data_Model_Views.sql
├── 🗄️ 03_Brz_Ecommerce_Business_Analysis.sql
│
└── 📁 screenshots/
    ├── Ventas.png
    ├── Ventas_2.png
    ├── Ventas_Dark_mode.png
    ├── Ventas_2_Dark_Mode.png
    ├── Desempeno.png
    ├── Desempeno_2.png
    ├── Desempeno_Dark_Mode.png
    ├── Desempeno_2_Dark_Mode.png
    ├── Historico_de_ventas.png
    ├── Historico_de_ventas_Dark_Mode.png
    ├── Tabla_Categoria_Productos.png
    ├── Tabla_Categorias_Productos_Dark_Mode.png
    ├── Tabla_de_Productos.png
    └── Tabla_Productos_Dark_Mode.png
```

---

## 5 — Dataset

- **Fuente:** [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Período:** Septiembre 2016 – Octubre 2018
- **Registros:** 99,441 órdenes / 112,650 ítems
- **Tablas originales:** orders, customers, order_items, order_payments, order_reviews, products, sellers, geolocation, product_category_name_translation.

---

## 🛠️ Stack Tecnológico

| Herramienta | Aplicación en el Proyecto |
|---|---|
| **SQL Server** | Motor de base de datos relacional |
| **T-SQL** | Modelado, vistas, índices y consultas de negocio |
| **SSMS** | Entorno de desarrollo y ejecución de scripts |
| **Markdown** | Documentación técnica y comunicación de hallazgos |

---

## 📬 Contacto

**Joseph Velasco** — *Data Analyst | SQL Server · Power BI · Business Intelligence*

- 🔗 **LinkedIn:** [linkedin.com/in/Joseph_Velasco](https://linkedin.com/in/joseph-velasco)
- 💼 **Portfolio:** [Tu enlace aquí]
- 🐙 **GitHub:** [github.com/Joseph_Velasco](https://github.com/DatajosephVe)

---

