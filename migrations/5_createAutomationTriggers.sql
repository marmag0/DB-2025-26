-- migration script to create functions and triggers for automation

-- * -- * -- * -- * --

-- migrate:up

-- TIMESTAMP TRIGGERS
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


-- STOCK MANAGEMENT TRIGGERS
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


-- PRICE SETTING TRIGGERS
-- trigger to set unit_price in order_items on insert
CREATE OR REPLACE FUNCTION public.set_order_item_price()
RETURNS TRIGGER AS $$
BEGIN
    SELECT price INTO NEW.unit_price
    FROM public.products
    WHERE product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_price_before_insert
BEFORE INSERT ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.set_order_item_price();

-- trigger to update products_cost in orders after inserting or updating order_items
CREATE OR REPLACE FUNCTION public.update_order_products_cost()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.orders
        SET products_cost = (
            SELECT COALESCE(SUM(quantity * unit_price), 0)
            FROM public.order_items
            WHERE order_id = NEW.order_id
        )
        WHERE order_id = NEW.order_id;
    END IF;

IF (TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.order_id <> OLD.order_id)) THEN
        UPDATE public.orders
        SET products_cost = (
            SELECT COALESCE(SUM(quantity * unit_price), 0)
            FROM public.order_items
            WHERE order_id = OLD.order_id
        )
        WHERE order_id = OLD.order_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_products_cost
AFTER INSERT OR UPDATE OR DELETE ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.update_order_products_cost();

-- trigger to update shipping_cost in orders after inserting or updating shipments
CREATE OR REPLACE FUNCTION public.update_order_shipping_cost()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.orders
        SET shipping_cost = (
            SELECT COALESCE(SUM(cost), 0)
            FROM public.shipments
            WHERE order_id = NEW.order_id
        )
        WHERE order_id = NEW.order_id;
    END IF;

    IF (TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.order_id <> OLD.order_id)) THEN
        UPDATE public.orders
        SET shipping_cost = (
            SELECT COALESCE(SUM(cost), 0)
            FROM public.shipments
            WHERE order_id = OLD.order_id
        )
        WHERE order_id = OLD.order_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_shipping_cost
AFTER INSERT OR UPDATE OR DELETE ON public.shipments
FOR EACH ROW
EXECUTE FUNCTION public.update_order_shipping_cost();

-- STATUS MANAGEMENT TRIGGERS
-- trigger to update order status based on payments
CREATE OR REPLACE FUNCTION public.update_order_status_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE public.orders
        SET status = 'paid'
        WHERE order_id = NEW.order_id AND status = 'pending';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_status_on_payment
AFTER UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.update_order_status_on_payment();

-- trigger to update order status based on shipments
CREATE OR REPLACE FUNCTION public.update_order_status_on_shipment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'shipped' THEN
        UPDATE public.orders
        SET status = 'shipped'
        WHERE order_id = NEW.order_id AND status != 'delivered';
    ELSIF NEW.status = 'delivered' THEN
        UPDATE public.orders
        SET status = 'delivered'
        WHERE order_id = NEW.order_id;
    ELSIF NEW.status = 'cancelled' THEN
        UPDATE public.orders
        SET status = 'canceled'
        WHERE order_id = NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_status_on_shipment
AFTER UPDATE ON public.shipments
FOR EACH ROW
EXECUTE FUNCTION public.update_order_status_on_shipment();

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

DROP TRIGGER IF EXISTS trg_set_price_before_insert ON public.order_items;
DROP FUNCTION IF EXISTS public.set_order_item_price();

DROP TRIGGER IF EXISTS trg_update_order_products_cost ON public.order_items;
DROP FUNCTION IF EXISTS public.update_order_products_cost();

DROP TRIGGER IF EXISTS trg_update_order_status_on_shipment ON public.shipments;
DROP FUNCTION IF EXISTS public.update_order_status_on_shipment();

DROP TRIGGER IF EXISTS trg_update_order_status_on_payment ON public.payments;
DROP FUNCTION IF EXISTS public.update_order_status_on_payment();