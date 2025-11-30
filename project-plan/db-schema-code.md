This file contains the complete visualization instruction (in code like form) for the ER diagram on [dbdiagram.io](https://dbdiagram.io).
Note that this is a suggestion; not every table will have exactly the same value types or attributes. 

```
Table Public.Customers {
  customer_id uuid [primary key]
  username varchar(40) [not null, unique]
  password_hash varchar(255) [not null]
  first_name varchar(40) [not null]
  last_name varchar(40) [not null]
  email varchar(100) [not null, unique]
  registration_date timestamp [default: `now()`]
}

Table Public.Addresses {
  address_id uuid [primary key]
  customer_id uuid [not null, ref: > Public.Customers.customer_id]
  street varchar(100) [not null]
  state_province varchar(60)
  postal_code varchar(20) [not null]
  country varchar(60) [not null]
  phone_number varchar(20)
  comments text
}

Table Public.Categories {
  category_id uuid [primary key]
  name varchar(60) [not null, unique]
  description text
}

Table Public.Products {
  product_id uuid [primary key]
  name varchar(80) [not null]
  description text
  price decimal(10,2) [not null]
  stock_quantity int [not null]
  sku varchar(40) [not null, unique]
  image_url varchar(255)
  weight decimal(5,3) 
  created_at timestamp [default: `now()`]
  updated_at timestamp
  category_id uuid [ref: > Public.Categories.category_id]
}

Table Public.Discounts {
  discount_id uuid [primary key]
  type varchar(20) [not null]
  applies_to_product uuid [ref: > Public.Products.product_id]
  applies_to_category uuid [ref: > Public.Categories.category_id] 
  need_code bool [default: true]
  percentage_value int [not null]
  start_date timestamp [not null]
  end_date timestamp [not null]
  minimum_order_amount decimal(10,2) [not null]
}

Table Public.Orders {
  order_id uuid [primary key]
  address_id uuid [not null, ref: > Public.Addresses.address_id]
  customer_id uuid [not null, ref: > Public.Customers.customer_id]
  order_date timestamp [not null]
  products_cost decimal(10,2) [not null]
  shipping_cost decimal(10,2) [not null]
  status varchar(40) [not null]
}

Table Public.OrderItems {
  order_item_id uuid [primary key]
  order_id uuid [not null, ref: > Public.Orders.order_id]
  product_id uuid [not null, ref: > Public.Products.product_id]
  quantity int [not null]
}

Table Public.PaymentMethods {
  payment_method_id uuid [primary key]
  name varchar(60) [not null, unique]
}

Table Public.Payments {
  payment_id uuid [primary key]
  order_id uuid [not null, ref: > Public.Orders.order_id]
  amount decimal(10,2) [not null]
  payment_date timestamp [not null]
  payment_method_id uuid [not null, ref: > Public.PaymentMethods.payment_method_id]
  status varchar(40) [not null]
}

Table Public.ShipmentCarriers {
  shipping_carrier_id uuid [primary key]
  name varchar(60) [not null, unique]
}

Table Public.Shipments {
  shipment_id uuid [primary key]
  order_id uuid [not null, ref: > Public.Orders.order_id]
  shipping_carrier_id uuid [not null, ref: > Public.ShipmentCarriers.shipping_carrier_id] 
  tracking_number varchar(50) [not null]
  shipment_date timestamp
  delivery_date timestamp
  status varchar(40) [not null]
}

Table Public.Reviews {
  review_id uuid [primary key]
  customer_id uuid [not null, ref: > Public.Customers.customer_id]
  product_id uuid [not null, ref: > Public.Products.product_id]
  rating int [not null]
  comment text
  review_date timestamp [not null]
}
```
