-- tests for status change triggers on orders based on payments and shipments

BEGIN;
SELECT plan(3);

-- data preparation

INSERT INTO public.payment_methods (name, carrier) 
VALUES ('Test Method', 'Test Provider');

INSERT INTO public.shipment_carriers (name) 
VALUES ('Test Carrier');

INSERT INTO public.customers (username, password_hash, first_name, last_name, email)
VALUES ('tester', 'hash', 'Aleksander', 'Nowak', 'tester@gmail.com');

INSERT INTO public.addresses (customer_id, city, street, postal_code, country)
VALUES (
    (SELECT customer_id FROM public.customers WHERE username = 'tester'),
    'Kraków',
    'Al. Mickiewicza 38',
    '32-020',
    'PL'
);

INSERT INTO public.orders (address_id, customer_id, products_cost, shipping_cost, status)
VALUES (
    (SELECT address_id FROM public.addresses WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = 'tester')),
    (SELECT customer_id FROM public.customers WHERE username = 'tester'),
    100,
    20,
    'pending'
);

-- test 1: payment completion updates order status to 'paid'
INSERT INTO public.payments (order_id, amount, payment_method_id, payment_date, status)
VALUES (
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = 'tester')),
    120,
    (SELECT payment_method_id FROM public.payment_methods WHERE name = 'Test Method'),
    NOW(),
    'completed'
);

SELECT results_eq(
    'SELECT status FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = ''tester'')',
    ARRAY['paid'],
    'Order status should update to ''paid'' after payment completion'
);

-- test 2: shipment status 'shipped' updates order status to 'shipped'
INSERT INTO public.shipments (order_id, shipping_carrier_id, tracking_number, shipment_date, cost, status)
VALUES (
    (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = 'tester')),
    (SELECT shipping_carrier_id FROM public.shipment_carriers WHERE name = 'Test Carrier'),
    'TRACK123456',
    NOW(),
    20.00,
    'shipped'
);

SELECT results_eq(
    'SELECT status FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = ''tester'')',
    ARRAY['shipped'],
    'Order status should update to ''shipped'' after shipment is marked as shipped'
);

-- test 3: shipment status 'delivered' updates order status to 'delivered'

UPDATE public.shipments
SET status = 'delivered'
WHERE order_id = (SELECT order_id FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = 'tester'));

SELECT results_eq(
    'SELECT status FROM public.orders WHERE customer_id = (SELECT customer_id FROM public.customers WHERE username = ''tester'')',
    ARRAY['delivered'],
    'Order status should update to ''delivered'' after shipment is marked as delivered'
);

-- cleanup

SELECT * FROM finish();
ROLLBACK;