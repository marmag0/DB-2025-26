-- migrate:up transaction:false

CREATE EXTENSION IF NOT EXISTS timescaledb SCHEMA public;

CREATE TABLE public."Customers"
(
    -- i'll do sth here
);

CREATE TABLE public."Products"
(
    -- i'll do sth here
);

CREATE TABLE public."Categories"
(
    -- i'll do sth here
);

-- migrate:down transaction:false