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

There will be detailed dsc soon... I guess...
