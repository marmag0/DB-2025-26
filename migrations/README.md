# Migrations

### Directory Structure

- [init](https://github.com/marmag0/DB-2025-26/tree/main/migrations/init) – migration scripts that can be executed only once on the database. They prepare the environment for testing and migrations. Should be executed manually, not via [Dbmate](https://github.com/amacneil/dbmate).  
- [content](https://github.com/marmag0/DB-2025-26/tree/main/migrations/content) – migration scripts that are performed on an existing database. These can be migrated `up` and `down` using Dbmate or manually.


### Naming Convention

To allow Dbmate to function correctly, all `.sql` migration scripts inside the [content](https://github.com/marmag0/DB-2025-26/tree/main/migrations/content) directory should be named using the following format:

```
n_action.sql
```

- `n` – the migration order number, starting from 1 (migration scripts are executed in ascending order)  
- `_` – a fixed character separating the order number from the description  
- `action` – a short description of the migration action, written in camelCase  
- `.sql` – the SQL file extension (obviously...)


### Dbmate - How To

- **project structure requirements**
  - file naming convention in [/migrations/content](https://github.com/marmag0/DB-2025-26/tree/main/migrations/content) should follow the rules described in this README
  - each migration script **must** contain `-- migrate:up` and `-- migrate:down` blocks
  - all files must be UTF-8 encoded

**example:**
**Filename:** `1_createTableUsers.sql`

```SQL
-- migrate:up
create table "users" (
  id serial,
  name varchar(255),
  email varchar(255) not null
);

-- migrate:down
drop table users;
```

- **Dbmate in use**
  - install Dbmate according to its [repository instructions](https://github.com/amacneil/dbmate?tab=readme-ov-file#installation).
  - prepare a connection string (can also be stored as an environment variable):
    - `"postgres://{user}@{host}:{port}/{database}?sslmode=disable&password={password}"` (1st version)
    - `postgres://user:password@host:port/database?sslmode=disable` (2nd version)
  - run a migration (or another Dbmate command):
    - `dbmate -d {migration_directory_path} -u {connection_string} {command}`
   
**example:**
```
dbmate -d . -u "postgres://postgres@localhost:5432/Panel.EmotoAgh.Test?sslmode=disable&password=root" up
```

- **most common commands**
  - `up` - runs all pending migrations and brings the database schema to the newest version
  - `down` - rolls back the **most recent** migration (useful for undoing the last change)
  - `status` - displays the list of all migrations and shows which ones have been applied
  - `verify` - checks the integrity of migrations to ensure they are consistent and valid
