-- migration script to create functions and triggers

-- * -- * -- * -- * --

-- migrate:up

-- trigger to update the updated_at column on row modification
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

-- trigger to check if stock is sufficient before inserting order items
CREATE OR REPLACE FUNCTION public.check_stock_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT stock_quantity FROM public.products WHERE product_id = NEW.product_id) < NEW.quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product_id: %', NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_stock_before_insert
BEFORE INSERT ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.check_stock_before_insert();

-- trigger to check if deleted customer has active orders
CREATE OR REPLACE FUNCTION public.check_active_orders_before_customer_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.orders 
        WHERE customer_id = OLD.customer_id 
        AND status NOT IN ('delivered', 'canceled')
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer with active orders.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_customer_delete_with_active_orders
BEFORE DELETE ON public.customers
FOR EACH ROW
EXECUTE FUNCTION public.check_active_orders_before_customer_delete();


-- trigger prevent deleting address if it is used in active orders
CREATE OR REPLACE FUNCTION public.check_active_orders_before_address_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.orders 
        WHERE address_id = OLD.address_id 
        AND status NOT IN ('delivered', 'canceled')
    ) THEN
        RAISE EXCEPTION 'Cannot delete address associated with active orders.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_address_delete_with_active_orders
BEFORE DELETE ON public.addresses
FOR EACH ROW
EXECUTE FUNCTION public.check_active_orders_before_address_delete();

-- * -- * -- * -- * --

-- migrate:down

DROP TRIGGER IF EXISTS prevent_address_delete_with_active_orders ON public.addresses;
DROP FUNCTION IF EXISTS public.check_active_orders_before_address_delete();

DROP TRIGGER IF EXISTS prevent_customer_delete_with_active_orders ON public.customers;
DROP FUNCTION IF EXISTS public.check_active_orders_before_customer_delete();

DROP TRIGGER IF EXISTS trg_check_stock_before_insert ON public.order_items;
DROP FUNCTION IF EXISTS public.check_stock_before_insert();

DROP TRIGGER IF EXISTS trg_update_updated_at ON public.products;
DROP FUNCTION IF EXISTS public.update_updated_at();