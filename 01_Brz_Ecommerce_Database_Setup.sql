/*======================================================
Nombre del Script: Proyecto-Brz_Ecomerce.sql
Fecha de inicio: 2024-06-10
Gestión para: SQL Server
Script para:
    - Crear base de datos Brz_Ecomerce
    - Tablas
    - Vistas
    - Procedimientos almacenados
Objetivos:
    - Crear KPI's
    - Tablas con la información principal del ecommerce
    - Dashboards
Autor: Joseph Velasco
Base de datos obtenida de: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
======================================================*/

--======================================================
-- 1.1 Crear Base de Datos(SETUP)
--======================================================

--======================================================
-- 1.1 Crear Base de Datos
--======================================================
IF DB_ID('Brz_Ecomerce') IS NOT NULL
    DROP DATABASE Brz_Ecomerce;

CREATE DATABASE Brz_Ecomerce;

USE Brz_Ecomerce;

--======================================================
-- 1.2. Carga de Datos (usando el asistente de importación en SSMS)
--======================================================
/*
Los datos se cargan usando el asistente de importación en SSMS:
- Clic derecho sobre la base de datos Brz_Ecomerce
- Seleccionar Tareas -> Importar Datos
- Seguir los pasos para importar los archivos CSV a las tablas
Nota: intencionalmente los archivos CSV fueron cargados con errores en el tipo de dato
para luego corregirlos en el script
*/

--======================================================
-- 1.3. Llaves Primarias y Foráneas
--======================================================

-- Orders
ALTER TABLE orders
ADD CONSTRAINT PK_orders_Order_Id PRIMARY KEY (order_id);

-- Customers
ALTER TABLE customer
ADD CONSTRAINT PK_customer_Customer_Id PRIMARY KEY (customer_id);

-- FK Orders → Customers
ALTER TABLE orders
ADD CONSTRAINT FK_orders_Customer_Id FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- Corrección de incompatibilidad de tipo de dato en customer_id
ALTER TABLE [dbo].[customer] DROP CONSTRAINT [PK_customer_Customer_Id] WITH (ONLINE = OFF);
GO
ALTER TABLE customer ALTER COLUMN customer_id NVARCHAR(100) NOT NULL;
GO
ALTER TABLE customer ADD CONSTRAINT PK_customer_Customer_Id PRIMARY KEY (customer_id);
ALTER TABLE orders ADD CONSTRAINT FK_orders_Customer_Id FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- Order Payments
ALTER TABLE order_payments
ADD CONSTRAINT FK_order_payments_Order_Id FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Products
ALTER TABLE products
ADD CONSTRAINT PK_products_Product_Id PRIMARY KEY (product_id);

-- Order Items → Products
ALTER TABLE order_item
ADD CONSTRAINT FK_order_items_Product_Id FOREIGN KEY (product_id) REFERENCES products(product_id);

-- Sellers
ALTER TABLE sellers
ADD CONSTRAINT PK_sellers_Seller_Id PRIMARY KEY (seller_id);

-- Order Items → Sellers
ALTER TABLE order_item
ADD CONSTRAINT FK_order_item_Seller_Id FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

-- Order Items → Orders
ALTER TABLE order_item
ADD CONSTRAINT FK_Order_Item_Order_Id FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Corrección de incompatibilidad de tipo de dato en Order Reviews  y FK con Orders
ALTER TABLE order_reviews
ALTER COLUMN order_id NVARCHAR(100) NOT NULL;
GO
ALTER TABLE order_reviews
ADD CONSTRAINT FK_order_reviews_Order_Id FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Product Category Translation
ALTER TABLE product_category_name_translation
ADD CONSTRAINT PK_product_category_name_translation_Product_Category_Name PRIMARY KEY (product_category_name);

ALTER TABLE products
ADD CONSTRAINT FK_products_Product_Category_Name FOREIGN KEY (product_category_name) REFERENCES product_category_name_translation(product_category_name);

--======================================================
-- 1.4. Normalización de Geolocalización
--======================================================
CREATE TABLE Geolocation_ZipCode(
    geolocation_zip_code_prefix NVARCHAR(100) PRIMARY KEY
);

INSERT INTO Geolocation_ZipCode(geolocation_zip_code_prefix)
SELECT DISTINCT geolocation_zip_code_prefix
FROM geolocation;

-- FK Customer → Geolocation
ALTER TABLE customer
ADD CONSTRAINT FK_Customer_ZipCode FOREIGN KEY (customer_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);

-- FK Sellers → Geolocation
ALTER TABLE sellers
ADD CONSTRAINT FK_Sellers_ZipCode FOREIGN KEY (seller_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);

-- FK Geolocation → Geolocation_ZipCode
ALTER TABLE geolocation
ADD CONSTRAINT FK_Geolocation_Zipcode FOREIGN KEY (geolocation_zip_code_prefix) REFERENCES Geolocation_ZipCode(geolocation_zip_code_prefix);

--======================================================
-- 1.5. Índices
--======================================================

-- Customer
CREATE NONCLUSTERED INDEX IX_Customer_State ON customer(customer_state);
GO
CREATE NONCLUSTERED INDEX IX_Customer_City ON customer(customer_city);
GO

-- Orders
CREATE NONCLUSTERED INDEX IX_Orders_Purchase_Timestamp ON orders(order_purchase_timestamp);
GO
CREATE NONCLUSTERED INDEX IX_Orders_Order_Status ON orders(order_status);
GO

-- Order Items
CREATE NONCLUSTERED INDEX IX_Order_Item_Product_Id ON order_item(product_id);
GO
CREATE NONCLUSTERED INDEX IX_Order_Item_Seller_Id ON order_item(seller_id);
GO
CREATE NONCLUSTERED INDEX IX_Order_Item_Order_Id ON order_item(order_id);
GO

-- Order Payments
CREATE NONCLUSTERED INDEX IX_Order_Payments_Payment_Type ON order_payments(payment_type);
GO

-- Order Reviews
CREATE NONCLUSTERED INDEX IX_Order_Reviews_Review_Score ON order_reviews(review_score);
GO
CREATE NONCLUSTERED INDEX IX_Order_Reviews_Order_Id ON order_reviews(order_id);
GO
CREATE NONCLUSTERED INDEX IX_Order_Reviews_ReviewID ON order_reviews(review_id);
GO

-- Products
CREATE NONCLUSTERED INDEX IX_Products_Product_Category_Name ON products(product_category_name);
GO

-- Product Category Translation
CREATE NONCLUSTERED INDEX IX_Product_Category_Name_Translation_Product_Category_Name_English ON product_category_name_translation(product_category_name_english);
GO

-- Sellers
CREATE NONCLUSTERED INDEX IX_Sellers_Seller_State ON sellers(seller_state);
GO
CREATE NONCLUSTERED INDEX IX_Sellers_Seller_City ON sellers(seller_city);
GO

-- Índice compuesto en order_item para acelerar joins y conteos de ítems únicos
CREATE NONCLUSTERED INDEX IX_OrderItem_Product_OrderItem
ON order_item(product_id, order_id, order_item_id);

-- Índice compuesto en customer para mejorar agrupaciones y rankings por ciudad/estado
CREATE NONCLUSTERED INDEX IX_Customer_City_State
ON customer(customer_city, customer_state);

-- Índice compuesto en sellers para análisis geográfico de vendedores
CREATE NONCLUSTERED INDEX IX_Sellers_City_State
ON sellers(seller_city, seller_state);

-- Índice compuesto en orders para acelerar joins y filtros por cliente y estado
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Status
ON orders(customer_id, order_status);

-- Índice compuesto en order_payments para análisis por tipo y valor de pago
CREATE NONCLUSTERED INDEX IX_OrderPayments_Type_Value
ON order_payments(payment_type, payment_value);

-- Índice compuesto en order_reviews para relacionar score con orden
CREATE NONCLUSTERED INDEX IX_OrderReviews_Order_Score
ON order_reviews(order_id, review_score);

--======================================================
-- 1.6. Consultas para Validacion
--=====================================================

--Debe dar el total de cantidad de ordenes
SELECT COUNT(*) FROM orders;

--Debe mostrar el top 10 de los compradores
SELECT top 10 * FROM customer;

--Debe mostrar de manera unica los status de pedidos existentes
SELECT DISTINCT order_status FROM Orders;

--Si funciona debria debolver 0 filas
SELECT * FROM orders WHERE customer_id NOT IN(SELECT customer_id FROM customer);

--======================================================
-- Fin del Script
--======================================================