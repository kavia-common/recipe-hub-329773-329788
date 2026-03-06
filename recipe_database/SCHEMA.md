# Recipe Hub PostgreSQL Schema & Migrations

This container uses a lightweight, repeatable migration approach that is compatible with:

- `startup.sh` (provisions PostgreSQL + user/db + writes `db_connection.txt`)
- `db_connection.txt` (canonical connection command)

## Schema entities

- `users`: app users
- `recipes`: recipes authored by users
- `recipe_ingredients`: ordered ingredient rows for a recipe
- `recipe_steps`: ordered instruction rows for a recipe
- `tags`: categories/tags (unified)
- `recipe_tags`: many-to-many relation between recipes and tags
- `favorites`: user favorites recipes
- `schema_migrations`: tracks applied migrations

## How migrations work

Migrations are stored as SQL files under `schema/` and applied by `migrate.sh`.

- A migration is applied **once** and recorded in `schema_migrations`.
- Re-running `./migrate.sh up` is safe; it only applies missing migrations.
- Seed data is optional and idempotent.

## Usage

### Start DB and apply schema
From `recipe_database/`:

```bash
./startup.sh
```

`startup.sh` will:
1. start PostgreSQL
2. create db/user
3. write `db_connection.txt`
4. run `./migrate.sh up`

### Apply seed data (optional)
Set an environment variable before running startup:

```bash
export RECIPE_HUB_SEED=true
./startup.sh
```

Or run directly after startup:

```bash
./migrate.sh seed
```

### Verify connection
Use the command in:

- `db_connection.txt` (e.g. `psql postgresql://appuser:...@localhost:5000/myapp`)

## Notes / invariants

- Ingredient and step ordering is enforced by unique constraints on `(recipe_id, position)`.
- Favorites are unique per `(user_id, recipe_id)` via primary key.
- Tag uniqueness is enforced on both `name` (case-insensitive) and `slug`.
- `citext` extension is enabled for case-insensitive email/username comparisons.
