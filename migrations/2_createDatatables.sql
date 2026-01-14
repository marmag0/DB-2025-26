-- migration script to create all datatables

-- * -- * -- * -- * --

-- migrate:up

-- add timescaledb extension for time-series data management
CREATE EXTENSION IF NOT EXISTS timescaledb SCHEMA public;

-- creating customers table
CREATE TABLE public.customers(
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(40) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(40) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    registration_date TIMESTAMPTZ DEFAULT NOW()
);

-- creating addresses table
CREATE TABLE public.addresses(
    address_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL
        REFERENCES public.customers(customer_id) 
        ON UPDATE CASCADE
        ON DELETE SET NULL, -- if user is deleted we want to retain their addresses for analysis and etc.
    city VARCHAR(100) NOT NULL,
    street VARCHAR(100) NOT NULL,
    state_province VARCHAR(60),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(60) NOT NULL,
    phone_number VARCHAR(20),
    comments TEXT
);

-- creating products categories table
CREATE TABLE public.categories(
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(60) NOT NULL UNIQUE,
    description TEXT
);

-- creating products table
CREATE TABLE public.products(
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80) NOT NULL,
    category_id UUID NOT NULL 
        REFERENCES public.categories(category_id) 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL,
    sku TEXT NOT NULL UNIQUE,
    image_url VARCHAR(255),
    weight DECIMAL(5,3),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- creating discounts table
CREATE TABLE public.discounts(
    discount_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE,
    type VARCHAR(20) NOT NULL,
    applies_to_product UUID DEFAULT NULL
        REFERENCES public.products(product_id) 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    applies_to_category UUID DEFAULT NULL
        REFERENCES public.categories(category_id) 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    need_code BOOLEAN DEFAULT TRUE,
    percentage_value INT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    minimum_order_amount DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    usage_limit INT
);

-- creating orders table
CREATE TABLE public.orders(
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address_id UUID NOT NULL 
        REFERENCES public.addresses(address_id) 
        ON DELETE SET NULL,
    customer_id UUID NOT NULL 
        REFERENCES public.customers(customer_id) 
        ON DELETE SET NULL,
    order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    products_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    shipping_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'pending' -- 'pending', 'paid', 'shipped', 'delivered', 'canceled'
);
 
-- creating ordered items table
CREATE TABLE public.order_items(
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL
        REFERENCES public.orders(order_id) 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    product_id UUID NOT NULL
        REFERENCES public.products(product_id) 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- creating payment methods table
CREATE TABLE public.payment_methods(
    payment_method_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(60) NOT NULL UNIQUE,
    carrier VARCHAR(60) NOT NULL,
    in_use BOOLEAN NOT NULL DEFAULT TRUE
);

-- creating payments table
-- logic:
-- clicking payment link creates a payment with 'pending' status
-- once payment is confirmed by external gateway, status is updated to 'completed'
-- if payment fails, status is updated to 'failed'
-- if customer requests refund and process is completed, status is updated to 'refunded'
CREATE TABLE public.payments(
    payment_id UUID DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL
        REFERENCES public.orders(order_id) 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMPTZ NOT NULL,
    payment_method_id UUID NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'completed', 'failed', 'refunded'

    PRIMARY KEY (payment_id, payment_date)
);

-- creating hypertable for payments to optimize time-series queries
SELECT create_hypertable('public.payments', 'payment_date');

-- creating shipment carriers table
CREATE TABLE public.shipment_carriers(
    shipping_carrier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(60) NOT NULL UNIQUE,
    in_use BOOLEAN DEFAULT TRUE
);

-- creating shipments table
-- logic:
-- when and orider is created, shipment record is created with 'pending' status
-- when an order is shipped, a shipment record is created with 'shipped' status
-- when shipment is in transit, status is updated to 'in_transit'
-- when shipment is delivered, status is updated to 'delivered'
-- if shipment is cancelled, status is updated to 'cancelled'
-- if shipment is returned by customer or delivery fails, status is updated to 'returning'
-- if shipment is returned, status is updated to 'returning' and then to 'returned'
CREATE TABLE public.shipments(
    shipment_id UUID NOT NULL DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL
        REFERENCES public.orders(order_id) 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    shipping_carrier_id UUID NOT NULL
        REFERENCES public.shipment_carriers(shipping_carrier_id) 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    tracking_number TEXT NOT NULL,
    shipment_date TIMESTAMPTZ,
    delivery_date TIMESTAMPTZ,
    cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL, -- 'pending', 'shipped', 'in_transit', 'delivered', 'cancelled', 'returning', 'returned'

    PRIMARY KEY (shipment_id, shipment_date)
);

-- creating hypertable for shipments to optimize time-series queries
SELECT create_hypertable('public.shipments', 'shipment_date');

-- creating reviews table
CREATE TABLE public.reviews(
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID
        REFERENCES public.customers(customer_id) 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    product_id UUID NOT NULL
        REFERENCES public.products(product_id) 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    rating INT NOT NULL,
    comment TEXT,
    review_date TIMESTAMPTZ NOT NULL
);

-- * -- * -- * -- * --

-- migrate:down

DROP TABLE IF EXISTS public.reviews;
DROP TABLE IF EXISTS public.shipments;
DROP TABLE IF EXISTS public.shipment_carriers;
DROP TABLE IF EXISTS public.payments;
DROP TABLE IF EXISTS public.payment_methods;
DROP TABLE IF EXISTS public.order_items;
DROP TABLE IF EXISTS public.orders;
DROP TABLE IF EXISTS public.discounts;
DROP TABLE IF EXISTS public.products;
DROP TABLE IF EXISTS public.categories;
DROP TABLE IF EXISTS public.addresses;
DROP TABLE IF EXISTS public.customers;