-- migrate:up transaction:false

SET TIMEZONE='UTC';

CREATE DATABASE "Ecommerce.Prod" WITH
    OWNER = "Role.Owner"
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

CREATE DATABASE "Ecommerce.Dev" WITH
    OWNER = "Role.Owner"
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;


-- migrate:down transaction:false

DROP DATABASE IF EXISTS "Ecommerce.Dev";
DROP DATABASE IF EXISTS "Ecommerce.Prod";
RESET TIMEZONE;