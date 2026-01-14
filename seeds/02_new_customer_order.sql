-- Adding a new customer, address, and placing an order

-- 1. Create Customer
WITH new_customer AS (
    INSERT INTO public."Customers" (customer_id, username, password_hash, first_name, last_name, email)
    VALUES (gen_random_uuid(), 'asmith', crypt('securePass123', gen_salt('bf')), 'Alice', 'Smith', 'alice.smith@example.com')
    RETURNING customer_id
),
-- 2. Create Address
new_address AS (
    INSERT INTO public."Addresses" (address_id, customer_id, city, street, state_province, postal_code, country, phone_number)
    SELECT gen_random_uuid(), customer_id, 'Warsaw', 'Aleje Jerozolimskie 100', 'Mazowieckie', '00-001', 'Poland', '+48987654321'
    FROM new_customer
    RETURNING address_id
),
-- 3. Lookup Product (Smartphone from initial seed)
product_lookup AS (
    SELECT product_id, price FROM public."Products" WHERE sku = 'SP-PRO-MAX-001' LIMIT 1
),
-- 4. Create Order
new_order AS (
    INSERT INTO public."Orders" (order_id, address_id, customer_id, order_date, products_cost, shipping_cost, status)
    SELECT gen_random_uuid(), (SELECT address_id FROM new_address), (SELECT customer_id FROM new_customer), NOW(), (SELECT price FROM product_lookup), 10.00, 'shipped'
    FROM new_customer
    RETURNING order_id
),
-- 5. Create OrderItem
new_order_item AS (
    INSERT INTO public."OrderItems" (order_item_id, order_id, product_id, quantity, unit_price)
    SELECT gen_random_uuid(), (SELECT order_id FROM new_order), (SELECT product_id FROM product_lookup), 1, (SELECT price FROM product_lookup)
    RETURNING order_item_id
),
-- 6. Create Review
new_review AS (
    INSERT INTO public."Reviews" (review_id, customer_id, product_id, rating, comment, review_date)
    SELECT gen_random_uuid(), (SELECT customer_id FROM new_customer), (SELECT product_id FROM product_lookup), 4, 'Great phone, but expensive.', NOW()
    FROM new_customer
    RETURNING review_id
)
SELECT * FROM new_order;
