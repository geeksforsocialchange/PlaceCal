# Postgres guide

Here is a quick run down on how to set up postgres

Feel free to skip, laugh or feedback if you actually know already how to postgres.

I would recommend using the system postgres for your OS as it has proven to be relatively stable once set up. (not the docker route. it seems easier but you can get problems if you have a mismatched server / client / dev libraries then you'll have to sort those out on your own)

1. Install postgres and postgres development libraries for your platform
   Based on your OS

- linux
  - [fedora](https://docs.fedoraproject.org/en-US/quick-docs/postgresql/)
  - [ubuntu/debian](https://linuxize.com/post/how-to-install-postgresql-on-debian-10/)
- mac os
  - don't use the app!
  - probably [homebrew](https://wiki.postgresql.org/wiki/Homebrew), but that is a whole procedure on its own
- windows
  - no

This should add a new `postgres` user and group to your system and add your user to the postgres group. It should also initialize postgres and configure it to start automatically on boot. You may need to logout and login again so your user has the correct group list (type `id` in the terminal and check you can see a `postgres` group entry).

2. Change user to postgres and run psql

This should do the trick `sudo -u postgres psql` or you can `su` into root and then `su postgres` into the postgres user.

3. Create a placecal entities.

In psql session:

```
-- user account
CREATE
  ROLE placecal_dev_role
  WITH LOGIN ENCRYPTED PASSWORD
  'password';

-- dev DB
CREATE
  DATABASE placecal_dev_db
  OWNER placecal_dev_role;

-- test DB
CREATE
  DATABASE placecal_test_db
  OWNER placecal_dev_role;

-- local prod DB
CREATE
  DATABASE placecal_dev_prod_db
  OWNER placecal_dev_role;
```

Note: we make a `placecal_dev_prod_db` database so when we can get copies of the live production database running on our local machines so we can checkout production problems locally (i.e. the calendar importer problems).

4. Configure PlaceCal

Jump to your PlaceCal directory and open up your `.env` file or `cp .env.example .env` and modify the necassery lines like so:

```
POSTGRES_DB=placecal_dev_role
POSTGRES_HOST=localhost
POSTGRES_USER=placecal_dev_role
PGPASSWORD=password
```

You also need to modify `config/database.yml` to set up the test suite (it needs to run on its own DB as it purges the database).

This is the line you are looking for:

```
test:
  <<: *default
  database: placecal_test_db
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['PGPASSWORD'] %>
  host: <%= ENV['POSTGRES_HOST'] %>

```

5. Check your config

Run `rails db:info` and check that the configuration is coming back with correct values.

6. Run migrations

Run `rails db:migrate`.

This will give you all the tables with the correct fields.

7. Seeding a user

Run `rails db:seed`.

This will create a dev user with email `admin@lvh.me` and password `password`. This may open up a browser window with an 'email'. That is just so you get around the account verification process we use.
