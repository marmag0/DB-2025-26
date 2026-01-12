-- migration script to create all datatables

-- * -- * -- * -- * --

-- migrate:up

-- add timescaledb extension for time-series data management
CREATE EXTENSION IF NOT EXISTS timescaledb SCHEMA public;

-- creating customers table
CREATE TABLE public."Customers"(
    "customer_id" UUID PRIMARY KEY,
    "username" VARCHAR(40) NOT NULL UNIQUE,
    "password_hash" VARCHAR(255) NOT NULL,
    "first_name" VARCHAR(40) NOT NULL,
    "last_name" VARCHAR(40) NOT NULL,
    "email" VARCHAR(100) NOT NULL UNIQUE,
    "registration_date" TIMESTAMPTZ DEFAULT NOW()
);

-- creating addresses table
CREATE TABLE public."Addresses"(
    "address_id" UUID PRIMARY KEY,
    "customer_id" UUID NOT NULL 
        REFERENCES public."Customers"("customer_id") 
        ON DELETE CASCADE, -- if user is deleted we don't need to retain their addresses
	"city" VARCHAR(100) NOT NULL,
    "street" VARCHAR(100) NOT NULL,
    "state_province" VARCHAR(60),
    "postal_code" VARCHAR(20) NOT NULL,
    "country" VARCHAR(60) NOT NULL,
    "phone_number" VARCHAR(20),
    "comments" TEXT
);

-- creating products table
CREATE TABLE public."Categories"(
    "category_id" UUID PRIMARY KEY,
    "name" VARCHAR(60) NOT NULL UNIQUE,
    "description" TEXT
);

-- creating products table
CREATE TABLE public."Products"(
    "product_id" UUID PRIMARY KEY,
    "name" VARCHAR(80) NOT NULL,
	"category_id" UUID NOT NULL 
        REFERENCES public."Categories"("category_id") 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    "description" TEXT,
    "price" DECIMAL(10,2) NOT NULL,
    "stock_quantity" INT NOT NULL,
    "sku" VARCHAR(40) NOT NULL UNIQUE,
    "on_sale" BOOLEAN DEFAULT TRUE,
    "image_url" VARCHAR(255),
    "weight" DECIMAL(5,3),
	"is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
	
-- creating discounts table
CREATE TABLE public."Discounts"(
    "discount_id" UUID PRIMARY KEY,
	"code" VARCHAR(50) UNIQUE,
    "type" VARCHAR(20) NOT NULL,
    "applies_to_product" UUID DEFAULT NULL
        REFERENCES public."Products"("product_id") 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    "applies_to_category" UUID DEFAULT NULL
        REFERENCES public."Categories"("category_id") 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    "need_code" BOOLEAN DEFAULT TRUE,
    "percentage_value" INT NOT NULL,
    "start_date" TIMESTAMPTZ NOT NULL,
    "end_date" TIMESTAMPTZ NOT NULL,
    "minimum_order_amount" DECIMAL(10,2) NOT NULL DEFAULT 0.0,
	"usage_limit" INT
);

-- creating orders table
CREATE TABLE public."Orders"(
    "order_id" UUID PRIMARY KEY,
    "address_id" UUID NOT NULL 
        REFERENCES public."Addresses"("address_id") 
        ON DELETE SET NULL,
    "customer_id" UUID NOT NULL 
        REFERENCES public."Customers"("customer_id") 
        ON DELETE SET NULL,
    "order_date" TIMESTAMPTZ NOT NULL,
    "products_cost" DECIMAL(10,2) NOT NULL,
    "shipping_cost" DECIMAL(10,2) NOT NULL,
    "status" TEXT NOT NULL
);

-- creating ordered items table
CREATE TABLE public."OrderItems"(
    "order_item_id" UUID PRIMARY KEY,
    "order_id" UUID NOT NULL
        REFERENCES public."Orders"("order_id") 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    "product_id" UUID NOT NULL
        REFERENCES public."Products"("product_id") 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    "quantity" INT NOT NULL,
	"unit_price" DECIMAL(10,2) NOT NULL
);

-- creating payment methods table
CREATE TABLE public."PaymentMethods"(
    "payment_method_id" UUID PRIMARY KEY,
    "name" VARCHAR(60) NOT NULL UNIQUE,
    "carrier" VARCHAR(60) NOT NULL,
    "in_use" BOOLEAN DEFAULT TRUE
);

-- creating payments table
CREATE TABLE public."Payments"(
    "payment_id" UUID,
    "order_id" UUID NOT NULL
        REFERENCES public."Orders"("order_id") 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    "amount" DECIMAL(10,2) NOT NULL,
    "payment_date" TIMESTAMPTZ NOT NULL,
    "payment_method_id" UUID NOT NULL,
    "status" TEXT NOT NULL,

    PRIMARY KEY ("payment_id", "payment_date")
);

-- creating hypertable for payments to optimize time-series queries
SELECT create_hypertable('public."Payments"', 'payment_date');

-- creating shipment carriers table
CREATE TABLE public."ShipmentCarriers"(
    "shipping_carrier_id" UUID PRIMARY KEY,
    "name" VARCHAR(60) NOT NULL UNIQUE,
    "in_use" BOOLEAN DEFAULT TRUE
);

-- creating shipments table
CREATE TABLE public."Shipments"(
    "shipment_id" UUID NOT NULL,
    "order_id" UUID NOT NULL
        REFERENCES public."Orders"("order_id") 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    "shipping_carrier_id" UUID NOT NULL
        REFERENCES public."ShipmentCarriers"("shipping_carrier_id") 
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    "tracking_number" TEXT NOT NULL,
    "shipment_date" TIMESTAMPTZ NOT NULL,
    "delivery_date" TIMESTAMPTZ,
    "status" TEXT NOT NULL,

    PRIMARY KEY ("shipment_id", "shipment_date")
);

-- creating hypertable for shipments to optimize time-series queries
SELECT create_hypertable('public."Shipments"', 'shipment_date');

-- creating reviews table
CREATE TABLE public."Reviews"(
    "review_id" UUID PRIMARY KEY,
    "customer_id" UUID
        REFERENCES public."Customers"("customer_id") 
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    "product_id" UUID NOT NULL
        REFERENCES public."Products"("product_id") 
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    "rating" INT NOT NULL,
    "comment" TEXT,
    "review_date" TIMESTAMPTZ NOT NULL
);

-- * -- * -- * -- * --

-- migrate:down

DROP TABLE IF EXISTS public."Reviews";
DROP TABLE IF EXISTS public."Shipments";
DROP TABLE IF EXISTS public."ShipmentCarriers";
DROP TABLE IF EXISTS public."Payments";
DROP TABLE IF EXISTS public."PaymentMethods";
DROP TABLE IF EXISTS public."OrderItems";
DROP TABLE IF EXISTS public."Orders";
DROP TABLE IF EXISTS public."Discounts";
DROP TABLE IF EXISTS public."Products";
DROP TABLE IF EXISTS public."Categories";
DROP TABLE IF EXISTS public."Addresses";
DROP TABLE IF EXISTS public."Customers";