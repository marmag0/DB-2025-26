# Database Documentation

This document describes the database schema, roles, and automation logic for the E-Commerce PostgreSQL database.

## Authors: Mateusz Klikuszewski, Mikołaj Mazur

## Repository: [GitHub](https://github.com/marmag0/DB-2025-26)

## Overview

The database uses **PostgreSQL 15+** with the **TimescaleDB** extension for time-series data (payments, shipments). Schema migrations are managed via **dbmate**.

## Technologies & Implemented Features

### 1. dbmate (Schema Migration)
*   **Role**: Manages database schema changes (DDL) and version control.
*   **Implementation**:
    *   **Migrations**: All tables, views, and functions are defined in SQL files within the `migrations/` directory.
    *   **Consistency**: Ensures the database schema is identical across all environments (Dev, Test, Prod) by tracking applied migrations in the `schema_migrations` table.
    *   **Hybrid Approach**: We use `dbmate` for structural changes, while `pgTAP` (separate tool) validates that these changes work as expected.

### 2. TimescaleDB (Time-Series Optimization)
*   **Role**: Extension optimizing PostgreSQL for high-volume time-series data.
*   **Implementation**:
    *   **Hypertables**: The `payments` and `shipments` tables are converted to **hypertables**. This automatically partitions data by time (`payment_date`, `shipment_date`), significantly improving query performance for historical data analysis (e.g., "monthly revenue", "delivery times").

## Roles

| Role | Permissions | Description |
| :--- | :--- | :--- |
| `role_owner` | SUPERUSER | Full administrative access. |
| `role_developer` | NOSUPERUSER | Standard CRUD operations on all tables. |

## Schema

### Tables & Hypertables

#### `public.customers`
Stores customer account information.
*   **PK**: `customer_id` (UUID)
*   **Columns**: `username`, `password_hash`, `first_name`, `last_name`, `email` (Unique), `registration_date`.
*   **Constraints**: `valid_email` (Regex check).

#### `public.addresses`
Stores customer delivery addresses.
*   **PK**: `address_id` (UUID)
*   **FK**: `customer_id` -> `public.customers` (ON DELETE SET NULL)
*   **Columns**: `city`, `street`, `state_province`, `postal_code`, `country`, `phone_number`, `comments`.

#### `public.categories`
Product categories hierarchy.
*   **PK**: `category_id` (UUID)
*   **Columns**: `name` (Unique), `description`.

#### `public.products`
Inventory items.
*   **PK**: `product_id` (UUID)
*   **FK**: `category_id` -> `public.categories`
*   **Columns**: `name`, `description`, `price`, `stock_quantity`, `sku` (Unique), `is_active`, timestamps.
*   **Constraints**:
    *   `non_negative_price`: Price >= 0
    *   `non_negative_stock`: Stock >= 0
    *   `valid_sku_format`: Alphanumeric + dashes only

#### `public.orders`
Customer orders.
*   **PK**: `order_id` (UUID)
*   **FK**: `customer_id`, `address_id`
*   **Columns**: `products_cost`, `shipping_cost`, `status`.
*   **Constraints**: `valid_order_status` ('pending', 'paid', 'shipped', 'delivered', 'canceled').

#### `public.order_items`
Line items within an order.
*   **PK**: `order_item_id` (UUID)
*   **FK**: `order_id`, `product_id`
*   **Columns**: `quantity`, `unit_price`.
*   **Constraints**: `positive_quantity` (Quantity > 0).

#### `public.payments` (Hypertable)
Partitioned by `payment_date`.
*   **PK**: (`payment_id`, `payment_date`)
*   **FK**: `order_id`
*   **Columns**: `amount`, `payment_method_id`, `status`.
*   **Constraints**: `valid_payment_status` ('pending', 'completed', 'failed', 'refunded').

#### `public.shipments` (Hypertable)
Partitioned by `shipment_date`.
*   **PK**: (`shipment_id`, `shipment_date`)
*   **FK**: `order_id`, `shipping_carrier_id`
*   **Columns**: `tracking_number`, `cost`, `status`, `delivery_date`.
*   **Constraints**: `valid_shipment_status` ('pending', 'shipped', 'in_transit', 'delivered', 'cancelled', 'returning', 'returned').

#### `public.reviews`
Product reviews.
*   **PK**: `review_id` (UUID)
*   **FK**: `customer_id`, `product_id`
*   **Columns**: `rating`, `comment`, `review_date`.
*   **Constraints**: `rating` must be 1-5.

---

## Views

| View Name | Description |
| :--- | :--- |
| **`v_order_details`** | Combines `orders`, `customers`, and `addresses`. Displays status, full customer name, delivery address, and calculates `total_amount` (products + shipping). |
| **`v_product_stats`** | Aggregates sales data per product. Shows `times_ordered`, `units_sold`, and `total_revenue`. |
| **`v_customer_summary`** | Customer activity report. Shows `total_orders`, `total_spent`, and `last_order_date`. |

---

## Automation (Triggers & Functions)

### Data Integrity
*   **`trg_check_stock_before_insert`** (Before Insert on `order_items`): Prevents ordering more items than available in stock.
*   **`prevent_customer_delete_with_active_orders`**: Blocks customer deletion if they have pending/shipped orders.
*   **`prevent_address_delete_with_active_orders`**: Blocks address deletion if linked to active orders.

### Business Logic
*   **Stock Management**:
    *   `trg_decrease_stock_after_insert`: Decrements stock when an item is added to an order.
    *   `trg_restore_stock_after_delete`: Restores stock if an item is removed.
    *   `trg_delete_items_on_cancel`: Automatically deletes order items (restoring stock) if an order is canceled.
*   **Cost Calculation**:
    *   `trg_set_price_before_insert`: Snapshots the current product price into `order_items`.
    *   `trg_update_order_products_cost`: Recalculates order `products_cost` on item changes.
    *   `trg_update_order_shipping_cost`: Recalculates order `shipping_cost` on shipment changes.
*   **Status Updates**:
    *   `trg_update_order_status_on_payment`: Sets order to `paid` when payment is completed.
    *   `trg_update_order_status_on_shipment`: Sets order to `shipped`, `delivered`, or `canceled` based on shipment status.
*   **Timestamps**:
    *   `trg_update_updated_at`: Automatically updates `updated_at` column on modification.
