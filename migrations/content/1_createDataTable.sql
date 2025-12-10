-- migrate:up transaction:false


-- adding TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb SCHEMA public;

-- creating customers table
CREATE TABLE public."Customers"(
    "customer_id" UUID PRIMARY KEY,
    "username" VARCHAR(40) NOT NULL UNIQUE,
    "password_hash" VARCHAR(255) NOT NULL,
    "first_name" VARCHAR(40) NOT NULL,
    "last_name" VARCHAR(40) NOT NULL,
    "email" VARCHAR(100) NOT NULL UNIQUE,
    "registration_date" TIMESTAMP DEFAULT NOW()
);

-- creating addresses table
CREATE TABLE public."Addresses"(
    "address_id" UUID PRIMARY KEY,
    "customer_id" UUID NOT NULL,
	"city" VARCHAR(100) NOT NULL,
    "street" VARCHAR(100) NOT NULL,
    "state_province" VARCHAR(60),
    "postal_code" VARCHAR(20) NOT NULL,
    "country" VARCHAR(60) NOT NULL,
    "phone_number" VARCHAR(20),
    "comments" TEXT,
	
    -- correlation to user; 
    -- if the user doesn't exist, we don't want to retain its address
	CONSTRAINT "customer_id_fk" FOREIGN KEY ("customer_id")
		REFERENCES public."Customers" ("customer_id")
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- creating categories table for products
CREATE TABLE public."Categories"(
    "category_id" UUID PRIMARY KEY,
    "name" VARCHAR(60) NOT NULL UNIQUE,
    "description" TEXT
);

-- creating products table
CREATE TABLE public."Products"(
    "product_id" UUID PRIMARY KEY,
    "name" VARCHAR(80) NOT NULL,
	"category_id" UUID,
    "description" TEXT,
    "price" DECIMAL(10,2) NOT NULL,
    "stock_quantity" INT NOT NULL,
    "sku" VARCHAR(40) NOT NULL UNIQUE,
    "on_sale" BOOLEAN DEFAULT TRUE,
    "image_url" VARCHAR(255),
    "weight" DECIMAL(5,3),
	"is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMP,
	
    -- correlation to categories; 
    -- we don't allow deleting a category if a product is in it
    CONSTRAINT "products_category_id_fk" FOREIGN KEY ("category_id")
        REFERENCES public."Categories" ("category_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- creating discounts table
CREATE TABLE public."Discounts"(
    "discount_id" UUID PRIMARY KEY,
	"code" VARCHAR(50) UNIQUE,
    "type" VARCHAR(20) NOT NULL,
    "applies_to_product" UUID,
    "applies_to_category" UUID,
    "need_code" BOOLEAN DEFAULT TRUE,
    "percentage_value" INT NOT NULL,
    "start_date" TIMESTAMP NOT NULL,
    "end_date" TIMESTAMP NOT NULL,
    "minimum_order_amount" DECIMAL(10,2) NOT NULL DEFAULT 0.0,
	"usage_limit" INT,

    -- discount value in percentage should be between 0-100, and there should be a specification of what it applies to
	CONSTRAINT "discounts_percentage_check" CHECK ("percentage_value" >= 0 AND "percentage_value" <= 100),
    CONSTRAINT "discounts_target_check" CHECK ("applies_to_product" IS NOT NULL OR "applies_to_category" IS NOT NULL),
    
    -- correlation to products and categories; 
    -- if a product or category is deleted, the product or category in discount should be cleared too
    CONSTRAINT "discounts_applies_to_product_fk" FOREIGN KEY ("applies_to_product")
        REFERENCES public."Products" ("product_id")
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT "discounts_applies_to_category_fk" FOREIGN KEY ("applies_to_category")
        REFERENCES public."Categories" ("category_id")
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- creating orders table
CREATE TABLE public."Orders"(
    "order_id" UUID PRIMARY KEY,
    "address_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "order_date" TIMESTAMP NOT NULL,
    "products_cost" DECIMAL(10,2) NOT NULL,
    "shipping_cost" DECIMAL(10,2) NOT NULL,
    "status" VARCHAR(40) NOT NULL,

    -- order status should be one of predefined values
	CONSTRAINT "orders_status_check" CHECK ("status" IN ('pending', 'shipped', 'delivered', 'cancelled')),
    
    -- correlation to address and customer; 
    -- we don't allow deleting an address or customer if an order is in realization 
    -- (TRIGGER NEEDED)
    CONSTRAINT "orders_address_id_fk" FOREIGN KEY ("address_id")
        REFERENCES public."Addresses" ("address_id")
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT "orders_customer_id_fk" FOREIGN KEY ("customer_id")
        REFERENCES public."Customers" ("customer_id")
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- creating ordered items table
CREATE TABLE public."OrderItems"(
    "order_item_id" UUID PRIMARY KEY,
    "order_id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "quantity" INT NOT NULL,
	"unit_price" DECIMAL(10,2) NOT NULL, 

    -- every ordered item must have positive quantity
	CONSTRAINT "quantity_value_check" CHECK ("quantity" > 0),
    
    -- corelation to order and product; 
    -- if an order is deleted, we also delete its products
    -- we don't allow deleting a product that was ordered
    CONSTRAINT "ordereditems_order_id_fk" FOREIGN KEY ("order_id")
        REFERENCES public."Orders" ("order_id")
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT "ordereditems_product_id_fk" FOREIGN KEY ("product_id")
        REFERENCES public."Products" ("product_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT
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
    "order_id" UUID NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "payment_date" TIMESTAMP NOT NULL,
    "payment_method_id" UUID NOT NULL,
    "status" VARCHAR(40) NOT NULL,
    PRIMARY KEY ("payment_id", "payment_date"),

    -- payment status should be one of predefined values
	CONSTRAINT "payments_status_check" CHECK ("status" IN ('pending', 'completed', 'failed', 'refunded')),
	
    -- correlation to orders and payment methods; 
    -- an order should not be deleted if it has associated payments;
    -- payment methods cannot be deleted if they are used in any payment 
    CONSTRAINT "payments_order_id_fk" FOREIGN KEY ("order_id")
        REFERENCES public."Orders" ("order_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT "payments_payment_method_id_fk" FOREIGN KEY ("payment_method_id")
        REFERENCES public."PaymentMethods" ("payment_method_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

SELECT create_hypertable('public."Payments"', 'payment_date');

-- creating shipment carriers table
CREATE TABLE public."ShipmentCarriers"(
    "shipping_carrier_id" UUID PRIMARY KEY,
    "name" VARCHAR(60) NOT NULL UNIQUE,
    "in_use" BOOLEAN DEFAULT TRUE
);

-- creating shipments table
CREATE TABLE public."Shipments"(
    "shipment_id" UUID,
    "order_id" UUID NOT NULL,
    "shipping_carrier_id" UUID NOT NULL,
    "tracking_number" VARCHAR(50) NOT NULL,
    "shipment_date" TIMESTAMP NOT NULL,
    "delivery_date" TIMESTAMP,
    "status" VARCHAR(40) NOT NULL,
    PRIMARY KEY ("shipment_id", "shipment_date"),
    
    -- shipment status should be one of predefined values
    CONSTRAINT "shipments_status_check" CHECK ("status" IN ('pending', 'shipped', 'in_transit', 'delivered', 'cancelled')),
    
    -- correlation to orders and shipment carriers;
    -- an order or carrier cannot be deleted if there are associated shipments
    CONSTRAINT "shipments_order_id_fk" FOREIGN KEY ("order_id")
        REFERENCES public."Orders" ("order_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT "shipments_carrier_id_fk" FOREIGN KEY ("shipping_carrier_id")
        REFERENCES public."ShipmentCarriers" ("shipping_carrier_id")
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

SELECT create_hypertable('public."Shipments"', 'shipment_date');

-- creating reviews table
CREATE TABLE public."Reviews"(
    "review_id" UUID,
    "customer_id" UUID,
    "product_id" UUID NOT NULL,
    "rating" INT NOT NULL,
    "comment" TEXT,
    "review_date" TIMESTAMP NOT NULL,
    PRIMARY KEY ("review_id", "review_date"),
    
    -- rating value should be between 1-5
    CONSTRAINT "reviews_rating_check" CHECK ("rating" >= 1 AND "rating" <= 5),
    
    -- correlation to customers and products;
    -- reviewer is set to null if a customer is deleted; 
    -- review is deleted when a product is deleted
    CONSTRAINT "reviews_customer_id_fk" FOREIGN KEY ("customer_id")
        REFERENCES public."Customers" ("customer_id")
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT "reviews_product_id_fk" FOREIGN KEY ("product_id")
        REFERENCES public."Products" ("product_id")
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

SELECT create_hypertable('public."Reviews"', 'review_date');


-- migrate:down transaction:false

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
