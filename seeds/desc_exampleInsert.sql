-- Example Data Insert Script
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Categories
WITH new_category AS (
    INSERT INTO public."Categories" (category_id, name, description)
    VALUES (gen_random_uuid(), 'Electronics', 'Gadgets, computers, and phones')
    RETURNING category_id
),
-- 2. Customer
new_customer AS (
    INSERT INTO public."Customers" (customer_id, username, password_hash, first_name, last_name, email)
    VALUES (gen_random_uuid(), 'jkowal', crypt('zaq1@WSX', gen_salt('bf')), 'Jan', 'Kowalski', 'jan.kowalsku@gmail.com')
    RETURNING customer_id
),
-- 3. Adress
new_address AS (
    INSERT INTO public."Addresses" (address_id, customer_id, city, street, state_province, postal_code, country, phone_number)
    SELECT gen_random_uuid(), customer_id, 'Kraków', 'Witolda Budryka', 'małopolska', '30-072', 'Poland', '+48123456789'
    FROM new_customer
    RETURNING address_id
),
-- 4. Product
new_product AS (
    INSERT INTO public."Products" (product_id, name, category_id, description, price, stock_quantity, sku, on_sale, weight)
    SELECT gen_random_uuid(), 'Smartphone Pro Max', category_id, 'Latest model', 999.99, 50, 'SP-PRO-MAX-001', true, 0.450
    FROM new_category
    RETURNING product_id, price
),
-- 5. Discount
new_discount AS (
    INSERT INTO public."Discounts" (discount_id, code, type, applies_to_product, percentage_value, start_date, end_date, minimum_order_amount)
    SELECT gen_random_uuid(), 'PROMAX10', 'percentage', product_id, 10, NOW(), NOW() + INTERVAL '1 month', 500.00
    FROM new_product
    RETURNING discount_id
),
-- 6. Order
new_order AS (
    INSERT INTO public."Orders" (order_id, address_id, customer_id, order_date, products_cost, shipping_cost, status)
    SELECT gen_random_uuid(), (SELECT address_id FROM new_address), (SELECT customer_id FROM new_customer), NOW(), 999.99, 15.00, 'pending'
    FROM new_customer
    RETURNING order_id
),
-- 7. OrderItem
new_order_item AS (
    INSERT INTO public."OrderItems" (order_item_id, order_id, product_id, quantity, unit_price)
    SELECT gen_random_uuid(), (SELECT order_id FROM new_order), (SELECT product_id FROM new_product), 1, (SELECT price FROM new_product)
    RETURNING order_item_id
),
-- 8. PaymentMethod
new_payment_method AS (
    INSERT INTO public."PaymentMethods" (payment_method_id, name, carrier, in_use)
    VALUES (gen_random_uuid(), 'Credit Card', 'Stripe', true)
    RETURNING payment_method_id
),
-- 9. Payment
new_payment AS (
    INSERT INTO public."Payments" (payment_id, order_id, amount, payment_date, payment_method_id, status)
    SELECT gen_random_uuid(), (SELECT order_id FROM new_order), 1014.99, NOW(), (SELECT payment_method_id FROM new_payment_method), 'completed'
    RETURNING payment_id
),
-- 10. ShipmentCarrier
new_carrier AS (
    INSERT INTO public."ShipmentCarriers" (shipping_carrier_id, name, in_use)
    VALUES (gen_random_uuid(), 'InPost', true)
    RETURNING shipping_carrier_id
),
-- 11. Shipment
new_shipment AS (
    INSERT INTO public."Shipments" (shipment_id, order_id, shipping_carrier_id, tracking_number, shipment_date, status)
    SELECT gen_random_uuid(), (SELECT order_id FROM new_order), (SELECT shipping_carrier_id FROM new_carrier), 'InPost-1234567890', NOW(), 'pending'
    RETURNING shipment_id
)
-- 12. Review
INSERT INTO public."Reviews" (review_id, customer_id, product_id, rating, comment, review_date)
SELECT gen_random_uuid(), (SELECT customer_id FROM new_customer), (SELECT product_id FROM new_product), 5, 'Amazing phone!', NOW()
FROM new_customer CROSS JOIN new_product;

