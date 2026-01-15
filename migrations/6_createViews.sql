-- migration script to create views for easier data access

-- * -- * -- * -- * --

-- migrate:up

CREATE OR REPLACE VIEW public.v_order_details AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    a.street || ', ' || a.postal_code || ' ' || a.city || ', ' || a.country AS shipping_address,
    o.products_cost,
    o.shipping_cost,
    (o.products_cost + o.shipping_cost) AS total_amount
FROM public.orders o
JOIN public.customers c ON o.customer_id = c.customer_id
LEFT JOIN public.addresses a ON o.address_id = a.address_id;

CREATE OR REPLACE VIEW public.v_product_stats AS
SELECT
    p.product_id,
    p.name AS product_name,
    p.sku,
    c.name AS category,
    COUNT(oi.order_item_id) AS times_ordered,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM public.products p
JOIN public.categories c ON p.category_id = c.category_id
LEFT JOIN public.order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name, p.sku, c.name;

CREATE OR REPLACE VIEW public.v_customer_summary AS
SELECT
    c.customer_id,
    c.username,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.products_cost + o.shipping_cost), 0) AS total_spent,
    MAX(o.order_date) AS last_order_date
FROM public.customers c
LEFT JOIN public.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.username, c.first_name, c.last_name, c.email;

-- * -- * -- * -- * --

-- migrate:down

DROP VIEW IF EXISTS public.v_customer_summary;
DROP VIEW IF EXISTS public.v_product_stats;
DROP VIEW IF EXISTS public.v_order_details;