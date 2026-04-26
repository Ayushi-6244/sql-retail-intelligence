-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: schema.sql
--  Description: Creates all tables for the retail database
-- ============================================================

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- CUSTOMERS TABLE
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    city          VARCHAR(50),
    state         VARCHAR(50),
    signup_date   DATE          NOT NULL,
    segment       VARCHAR(20)   DEFAULT 'New'   -- 'Premium', 'Regular', 'New'
);

-- PRODUCTS TABLE
CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    name         VARCHAR(100)   NOT NULL,
    category     VARCHAR(50)    NOT NULL,        -- 'Electronics','Clothing','Home','Beauty','Sports'
    price        DECIMAL(10,2)  NOT NULL,
    cost         DECIMAL(10,2)  NOT NULL         -- for profit margin analysis
);

-- ORDERS TABLE
CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_id    INT            NOT NULL,
    order_date     DATE           NOT NULL,
    total_amount   DECIMAL(10,2)  NOT NULL,
    status         VARCHAR(20)    DEFAULT 'Completed',  -- 'Completed','Returned','Pending'
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ORDER ITEMS TABLE
CREATE TABLE order_items (
    item_id      INT PRIMARY KEY,
    order_id     INT            NOT NULL,
    product_id   INT            NOT NULL,
    quantity     INT            NOT NULL,
    unit_price   DECIMAL(10,2)  NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- INDEXES for performance
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_items_order       ON order_items(order_id);
CREATE INDEX idx_items_product     ON order_items(product_id);
