-- Seed file to populate the e-commerce database with example data

BEGIN;

-- 1. cleaning existing data to avoid duplicates
TRUNCATE public.reviews, public.shipments, public.payments, public.order_items, 
         public.orders, public.discounts, public.products, public.categories, 
         public.addresses, public.customers, public.shipment_carriers, public.payment_methods 
         RESTART IDENTITY CASCADE;

DO $$
DECLARE
    -- Variables to hold generated IDs

    -- Customers
    v_cust_jan_id UUID;
    v_cust_anna_id UUID;
    
    -- Addresses
    v_addr_jan_id UUID;
    v_addr_anna_id UUID;
    
    -- Categories
    v_cat_elec_id UUID;
    v_cat_books_id UUID;
    v_cat_clothes_id UUID;
    v_cat_home_id UUID;

    -- Products
    v_prod_laptop_id UUID;
    v_prod_mouse_id UUID;
    v_prod_book_id UUID;
    v_prod_headphones_id UUID;
    v_prod_jeans_id UUID;
    v_prod_mug_id UUID;
    
    -- Shipment Carriers
    v_carrier_dhl_id UUID;
    v_carrier_inpost_id UUID;

    -- Payment Methods
    v_pay_method_card_id UUID;

    -- Orders
    v_order_jan_id UUID;
    v_order_anna_id UUID;
BEGIN

    -- =============================================
    -- 1. Dictionaries: Categories, Shipment Carriers, Payment Methods
    -- =============================================
    INSERT INTO public.categories (name, description) VALUES ('Elektronika', 'Komputery i akcesoria') RETURNING category_id INTO v_cat_elec_id;
    INSERT INTO public.categories (name, description) VALUES ('Książki', 'Literatura techniczna') RETURNING category_id INTO v_cat_books_id;
    INSERT INTO public.categories (name, description) VALUES ('Odzież', 'Ubrania i dodatki') RETURNING category_id INTO v_cat_clothes_id;
    INSERT INTO public.categories (name, description) VALUES ('Dom i Ogród', 'Artykuły do domu i ogrodu') RETURNING category_id INTO v_cat_home_id;

    INSERT INTO public.shipment_carriers (name) VALUES ('DHL') RETURNING shipping_carrier_id INTO v_carrier_dhl_id;
    INSERT INTO public.shipment_carriers (name) VALUES ('InPost') RETURNING shipping_carrier_id INTO v_carrier_inpost_id;

    INSERT INTO public.payment_methods (name, carrier) VALUES ('Karta Kredytowa', 'Stripe') RETURNING payment_method_id INTO v_pay_method_card_id;

    -- =============================================
    -- 2. Products
    -- =============================================

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku) 
    VALUES ('Laptop Gamingowy', v_cat_elec_id, 5000.00, 10, 'LAP-001') 
    RETURNING product_id INTO v_prod_laptop_id;

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku) 
    VALUES ('Myszka RGB', v_cat_elec_id, 100.00, 50, 'MOU-001') 
    RETURNING product_id INTO v_prod_mouse_id;

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku) 
    VALUES ('Czysty Kod', v_cat_books_id, 50.00, 100, 'BOOK-001') 
    RETURNING product_id INTO v_prod_book_id;

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku)
    VALUES ('Słuchawki Bezprzewodowe', v_cat_elec_id, 300.00, 30, 'HEAD-001')
    RETURNING product_id INTO v_prod_headphones_id;

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku)
    VALUES ('Jeansy Męskie', v_cat_clothes_id, 150.00, 40, 'JEAN-001')
    RETURNING product_id INTO v_prod_jeans_id;

    INSERT INTO public.products (name, category_id, price, stock_quantity, sku)
    VALUES ('Kubek Ceramiczny', v_cat_home_id, 30.00, 80, 'MUG-001')
    RETURNING product_id INTO v_prod_mug_id;

    -- =============================================
    -- 3. Customers and Addresses
    -- =============================================
    -- Jan
    INSERT INTO public.customers (username, password_hash, first_name, last_name, email)
    VALUES ('jan_kowalski', 'hash123', 'Jan', 'Kowalski', 'jan@test.pl')
    RETURNING customer_id INTO v_cust_jan_id;

    INSERT INTO public.addresses (customer_id, city, street, postal_code, country)
    VALUES (v_cust_jan_id, 'Warszawa', 'Złota 44', '00-001', 'Polska')
    RETURNING address_id INTO v_addr_jan_id;

    -- Anna
    INSERT INTO public.customers (username, password_hash, first_name, last_name, email)
    VALUES ('anna_nowak', 'hash456', 'Anna', 'Nowak', 'anna@test.pl')
    RETURNING customer_id INTO v_cust_anna_id;
    
    INSERT INTO public.addresses (customer_id, city, street, postal_code, country)
    VALUES (v_cust_anna_id, 'Kraków', 'Rynek 1', '30-001', 'Polska')
    RETURNING address_id INTO v_addr_anna_id;

    -- =============================================
    -- SCENARIUSZ A: Jan bought a laptop (pending)
    -- =============================================
    
    -- 1. Create empty order
    INSERT INTO public.orders (customer_id, address_id)
    VALUES (v_cust_jan_id, v_addr_jan_id)
    RETURNING order_id INTO v_order_jan_id;

    -- 2. Adding laptop to order (Trigger: will set unit_price=5000, products_cost=5000, zdejmie ze stanu)
    INSERT INTO public.order_items (order_id, product_id, quantity)
    VALUES (v_order_jan_id, v_prod_laptop_id, 1);

    -- 3. Adding shipment (Trigger: will set shipping_cost=20)
    INSERT INTO public.shipments (order_id, shipping_carrier_id, tracking_number, shipment_date, cost, status)
    VALUES (v_order_jan_id, v_carrier_dhl_id, 'DHL-WAITING', NOW(), 20.00, 'pending');

    -- Verification: Total = 5000 (products) + 20 (shipping) = 5020.00 PLN

    -- =============================================
    -- SCENARIUSZ B: Anna bought a book and a mouse (paid & shipped)
    -- =============================================

    -- 1. Create empty order
    INSERT INTO public.orders (customer_id, address_id)
    VALUES (v_cust_anna_id, v_addr_anna_id)
    RETURNING order_id INTO v_order_anna_id;

    -- 2. We add (50 PLN) and a mouse (100 PLN) -> Products total: 150 PLN
    INSERT INTO public.order_items (order_id, product_id, quantity) VALUES (v_order_anna_id, v_prod_book_id, 1);
    INSERT INTO public.order_items (order_id, product_id, quantity) VALUES (v_order_anna_id, v_prod_mouse_id, 1);

    -- 3. Adding shipment (15 PLN)
    INSERT INTO public.shipments (order_id, shipping_carrier_id, tracking_number, shipment_date, cost, status)
    VALUES (v_order_anna_id, v_carrier_inpost_id, 'INPOST-123', NOW(), 15.00, 'pending');

    -- Verification: Total = 150 (products) + 15 (shipping) = 165.00 PLN

    -- 4. Payment (Must be exactly 165.00, otherwise the validation trigger will reject it!)
    INSERT INTO public.payments (order_id, amount, payment_method_id, status)
    VALUES (v_order_anna_id, 165.00, v_pay_method_card_id, 'completed');

    -- 5. Shipment status update
    -- Update shipment to 'shipped'
    UPDATE public.shipments 
    SET status = 'shipped' 
    WHERE order_id = v_order_anna_id;
    -- Trigger: Will change order status from 'paid' to 'shipped'

    -- =============================================
    -- Review
    -- =============================================
    INSERT INTO public.reviews (customer_id, product_id, rating, comment, review_date)
    VALUES (v_cust_anna_id, v_prod_book_id, 5, 'Książka zmieniła moje życie!', NOW());

END $$;

COMMIT;