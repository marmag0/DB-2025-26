-- migration script to create database roles

-- * -- * -- * -- * --

-- migrate:up

CREATE ROLE role_owner WITH
    LOGIN
    SUPERUSER
    CONNECTION LIMIT -1
    PASSWORD 'SuperStrongPassword';

CREATE ROLE role_developer WITH
    LOGIN
    NOSUPERUSER
    NOCREATEROLE
    NOREPLICATION
    NOINHERIT
    CONNECTION LIMIT -1
    PASSWORD 'StrongPassword';

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO role_developer;

-- * -- * -- * -- * --

-- migrate:down

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM role_developer;

DROP OWNED BY role_developer;
DROP OWNED BY role_owner;

DROP ROLE IF EXISTS role_developer;
DROP ROLE IF EXISTS role_owner;