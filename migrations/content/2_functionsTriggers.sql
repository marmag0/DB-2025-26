-- migrate:up transaction:false

-- 1. Function to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Products
CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public."Products"
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 2. Function to prevent deleting customer if they have active orders
CREATE OR REPLACE FUNCTION public.check_active_orders_before_customer_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public."Orders" 
        WHERE customer_id = OLD.customer_id 
        AND status NOT IN ('delivered', 'cancelled')
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer with active orders.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Customers
CREATE TRIGGER prevent_customer_delete_with_active_orders
BEFORE DELETE ON public."Customers"
FOR EACH ROW
EXECUTE FUNCTION public.check_active_orders_before_customer_delete();


-- 3. Function to prevent deleting address if it is used in active orders
CREATE OR REPLACE FUNCTION public.check_active_orders_before_address_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public."Orders" 
        WHERE address_id = OLD.address_id 
        AND status NOT IN ('delivered', 'cancelled')
    ) THEN
        RAISE EXCEPTION 'Cannot delete address associated with active orders.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Addresses
CREATE TRIGGER prevent_address_delete_with_active_orders
BEFORE DELETE ON public."Addresses"
FOR EACH ROW
EXECUTE FUNCTION public.check_active_orders_before_address_delete();


-- migrate:down transaction:false

-- Drop Triggers
DROP TRIGGER IF EXISTS prevent_address_delete_with_active_orders ON public."Addresses";
DROP TRIGGER IF EXISTS prevent_customer_delete_with_active_orders ON public."Customers";
DROP TRIGGER IF EXISTS update_products_updated_at ON public."Products";

-- Drop Functions
DROP FUNCTION IF EXISTS public.check_active_orders_before_address_delete();
DROP FUNCTION IF EXISTS public.check_active_orders_before_customer_delete();
DROP FUNCTION IF EXISTS public.update_updated_at_column();
