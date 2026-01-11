-- Adding more products to the existing 'Electronics' category

WITH category_lookup AS (
    SELECT category_id FROM public."Categories" WHERE name = 'Electronics' LIMIT 1
),
new_products AS (
    INSERT INTO public."Products" (product_id, name, category_id, description, price, stock_quantity, sku, on_sale, weight)
    SELECT gen_random_uuid(), 'Wireless Headphones', (SELECT category_id FROM category_lookup), 'Noise cancelling over-ear headphones', 299.99, 100, 'WH-1000XM5', false, 0.250
    UNION ALL
    SELECT gen_random_uuid(), 'Smart Watch Series 7', (SELECT category_id FROM category_lookup), 'Latest generation smartwatch', 399.99, 75, 'SW-S7-001', true, 0.050
    RETURNING product_id, name
)
SELECT * FROM new_products;
