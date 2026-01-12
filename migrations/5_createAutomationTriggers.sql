-- migration script to create functions and triggers for automation

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

-- -- -- -- -- -- -- --

-- trigger to change quantity in stock after inserting order items
CREATE OR REPLACE FUNCTION public.decrease_stock_on_order_item_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrease_stock_after_insert
AFTER INSERT ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.decrease_stock_on_order_item_insert();

-- -- -- -- -- -- -- --

-- trigger to restore stock when an order item is deleted
CREATE OR REPLACE FUNCTION public.restore_stock_on_order_item_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.products
    SET stock_quantity = stock_quantity + OLD.quantity
    WHERE product_id = OLD.product_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_restore_stock_after_delete
AFTER DELETE ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.restore_stock_on_order_item_delete();

-- -- -- -- -- -- -- --

-- trigger to delete order items when an order is canceled
CREATE OR REPLACE FUNCTION public.handle_order_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'canceled' AND OLD.status != 'canceled' THEN
        DELETE FROM public.order_items
        WHERE order_id = NEW.order_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_delete_items_on_cancel
AFTER UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_cancellation();

-- * -- * -- * -- * --

-- migrate:down

DROP TRIGGER IF EXISTS trg_decrease_stock_after_insert ON public.order_items;
DROP FUNCTION IF EXISTS public.decrease_stock_on_order_item_insert();

DROP TRIGGER IF EXISTS trg_delete_items_on_cancel ON public.orders;
DROP FUNCTION IF EXISTS public.handle_order_cancellation();

DROP TRIGGER IF EXISTS trg_restore_stock_after_delete ON public.order_items;
DROP FUNCTION IF EXISTS public.restore_stock_on_order_item_delete();

DROP TRIGGER IF EXISTS trg_update_updated_at ON public.products;
DROP FUNCTION IF EXISTS public.update_updated_at();