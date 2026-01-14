-- migration script to create integrity constraints

-- * -- * -- * -- * --

-- migrate:up

-- constraints for public.customers
ALTER TABLE public.customers
-- email must follow standard email format
ADD CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');


-- constraints for public.products
ALTER TABLE public.products
-- price must be non-negative
ADD CONSTRAINT non_negative_price CHECK (price >= 0),
-- stock_quantity must be non-negative
ADD CONSTRAINT non_negative_stock CHECK (stock_quantity >= 0),
-- constraint to ensure SKU format (alphanumeric and dashes only)
ADD CONSTRAINT valid_sku_format CHECK (sku ~* '^[A-Za-z0-9-]+$');


-- constraints for public.discounts
ALTER TABLE public.discounts
-- discount percentage must be between 0 and 100
ADD CONSTRAINT valid_discount_percentage CHECK (percentage_value >= 0 AND percentage_value <= 100),
-- end_date must be after start_date
ADD CONSTRAINT valid_discount_dates CHECK (end_date > start_date);


-- constraints for public.orders
ALTER TABLE public.orders
-- status must be one of the predefined values
ADD CONSTRAINT valid_order_status CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'canceled'));


-- constraints for public.order_items
ALTER TABLE public.order_items
-- quantity must be positive
ADD CONSTRAINT positive_quantity CHECK (quantity > 0);


--- constraints for public.payments
ALTER TABLE public.payments
-- amount must be non-negative
ADD CONSTRAINT positive_payment_amount CHECK (amount >= 0),
-- status must be one of the predefined values
ADD CONSTRAINT valid_payment_status CHECK (status IN ('pending', 'completed', 'failed', 'refunded'));


-- constraints for public.shipments
ALTER TABLE public.shipments
-- status must be one of the predefined values
ADD CONSTRAINT valid_shipment_status CHECK (status IN ('pending', 'shipped', 'in_transit', 'delivered', 'cancelled', 'returning', 'returned'));


-- constraints for public.reviews
ALTER TABLE public.reviews
-- rating must be between 1 and 5
ADD CONSTRAINT valid_review_rating CHECK (rating >= 1 AND rating <= 5);

-- * -- * -- * -- * --

-- migrate:down

ALTER TABLE public.reviews DROP CONSTRAINT valid_review_rating;

ALTER TABLE public.shipments DROP CONSTRAINT valid_shipment_status;

ALTER TABLE public.payments DROP CONSTRAINT valid_payment_status;
ALTER TABLE public.payments DROP CONSTRAINT positive_payment_amount;

ALTER TABLE public.order_items DROP CONSTRAINT positive_quantity;

ALTER TABLE public.orders DROP CONSTRAINT valid_order_status;

ALTER TABLE public.discounts DROP CONSTRAINT valid_discount_dates;
ALTER TABLE public.discounts DROP CONSTRAINT valid_discount_percentage;

ALTER TABLE public.products DROP CONSTRAINT valid_sku_format;
ALTER TABLE public.products DROP CONSTRAINT non_negative_stock;
ALTER TABLE public.products DROP CONSTRAINT non_negative_price;

ALTER TABLE public.customers DROP CONSTRAINT valid_email;