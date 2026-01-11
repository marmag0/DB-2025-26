-- migration script to create database roles

-- * -- * -- * -- * --

-- migrate:up

CREATE ROLE "Role.Owner" WITH
	LOGIN
	SUPERUSER
	CONNECTION LIMIT -1
	PASSWORD 'SuperStrongPassword';

CREATE ROLE "Role.Developer" WITH
    LOGIN
    NOSUPERUSER
    NOCREATEROLE
    NOREPLICATION
    NOINHERIT
    CONNECTION LIMIT -1
    PASSWORD 'strongPassword';

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "Role.Developer";

-- * -- * -- * -- * --

-- migrate:down

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM "Role.Developer";

DROP ROLE IF EXISTS "Role.Developer";
DROP ROLE IF EXISTS "Role.Owner";