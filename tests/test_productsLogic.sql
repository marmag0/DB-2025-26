-- tests for triggers and logic related to products, stock management, and orders

BEGIN;
SELECT plan(2);

-- data preparation

INSERT INTO public.categories (name) 
VALUES ('TestCat');

INSERT INTO public.products (name, category_id, price, stock_quantity, sku) 
VALUES (
    'TestProduct', 
    (SELECT category_id FROM public.categories WHERE name = 'TestCat'),
    50.00, 
    100, 
    'TEST-SKU'
);

INSERT INTO public.customers (username, password_hash, first_name, last_name, email)
VALUES ('tester', 'hash', 'Jan', 'Test', 'jan@test.pl');

INSERT INTO public.addresses (customer_id, city, street, postal_code, country)
VALUES (
    (SELECT customer_id FROM public.customers WHERE username = 'tester'),
    'Wro', 
    'Rynek', 
    '00-000', 
    'PL'
);

INSERT INTO public.orders (address_id, customer_id, products_cost, shipping_cost, status)
VALUES (
    (SELECT address_id FROM public.addresses WHERE city = 'Wro' LIMIT 1),
    (SELECT customer_id FROM public.customers WHERE username = 'tester'),
    0, 
    0, 
    'pending'
);

-- test 1: check if orders make quantity deduction correctly

INSERT INTO public.order_items (order_id, product_id, quantity, unit_price)
VALUES (
    (SELECT order_id FROM public.orders WHERE status = 'pending' LIMIT 1),
    (SELECT product_id FROM public.products WHERE sku = 'TEST-SKU'),
    5,
    50.00
);

SELECT results_eq(
    'SELECT stock_quantity FROM public.products WHERE sku = ''TEST-SKU''',
    ARRAY[95],
    'Trigger should decrease stock by 5 (100 -> 95)'
);

-- test 2: check chain of triggers on canceling an order

UPDATE public.orders
SET status = 'canceled'
WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = 'tester');

SELECT results_eq(
    'SELECT stock_quantity FROM public.products WHERE sku = ''TEST-SKU''',
    ARRAY[100],
    'Canceling order should remove items and restore stock (95 -> 100)'
);

-- cleanup

SELECT * FROM finish();
ROLLBACK;