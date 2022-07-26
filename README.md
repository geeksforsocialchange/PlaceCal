# PlaceCal

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/).

## Requirements

To run PlaceCal locally you will need:

- A Mac or a Linux machine (we don't support Windows at present)
- Postgres relational database. We are currently using v14.
  - Server
    - either installed for your distribution or as a docker image (with the correct open port -- see below)
  - Client
    - you will still need the local developer libraries for postgres
    - these are distribution specific so you need to find out what they are called to install them
      -  `libpq-dev` (debian)
      -  `postgresql-libs` (arch)
      -  `dev-db/postgresql` (gentoo)
- Ruby 2.7.x. We reccomend using a version manager for this such as `rvm` or `rbenv`. Current version we are using is in `.ruby-version`.
  - [rvm](https://rvm.io/)
  - [rbenv](https://github.com/rbenv/rbenv)
    - [ruby-build](https://github.com/rbenv/ruby-build)
    - [rbenv-gemset](https://github.com/jf/rbenv-gemset) (optional)
- Node.js. Current version we are using is in `.nvmrc`. We suggest using [nvm](https://github.com/nvm-sh/nvm) to manage this.
  - [yarn](https://yarnpkg.com/getting-started/install)
- ImageMagick for image manipulation
- Chrome/Chromium for system tests

## Quickstart

With that said, here's what you need to get rolling.

### Set up postgresql server (Via docker)

**Note: Skip this step if you're using a system-installed docker**

Creating a postgres docker image is simple:

``` sh
docker network create placecal-network
docker create --name placecal-db --network placecal-network --network-alias postgres -p 5432:5432 --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5 -e 'POSTGRES_DB=placecal_db' -e 'POSTGRES_USER=postgres' -e 'POSTGRES_PASSWORD=foobar' -e 'POSTGRES_PORT=5432' postgres:14.1
docker start placecal-db
```

You should now set the following values in your `.env`:

``` sh
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
PGPASSWORD=foobar
```

If you've changed the port, or something else, please remember to represent that change in `.env`

### Set up the local placecal repository, set up the database, and run it

```
git clone https://github.com/geeksforsocialchange/PlaceCal.git
bundle && yarn
bundle exec rails db:setup db:migrate seed:migrate
bundle exec rails import:all_events
./bin/dev
```

* Start the server with `./bin/dev` instead of `bundle exec rails server` due to migration to jsbundling
* Make sure you use `lvh.me:3000` instead of `localhost` or you **will** have authentication problems.
* Admin interface is `admin.lvh.me:3000` (You will need to make a new admin user -- see below)
* Access code docs through your local filesystem, and update with `bundle exec rails yard`

To set up your own server, take a look at `INSTALL.md`.

### Creating an admin user

To create an admin user, open the console (`bin/rails c`) and run the following:

```
User.create!(email: 'info@placecal.org', password: 'password', password_confirmation: 'password', role: :root)
```

(Note: You should replace 'info@placecal.org' and 'password' with more appropriate values)

## Testing

All PlaceCal tests are written in minitest. Before running tests make sure you dev environment has all the migrations run and then run `rails db:test:prepare` which will load the schema into the test database.

Running unit tests is as simple as `rails test` for all tests, `rails test test/models/user.rb` to run every test in one test file and `rails test test/models/user.rb:123` to run only ONE test.

System tests are where the application is started and connected to a 'headless' browser that is then used to verify functionality. This is employed as it allows us to verify our javascript is behaving.
When running the unit tests these systems tests are NOT run as they can take a lot of time and use a large amount of RAM.
To run system tests invoke `rails test:system`. It has the same options as the unit tests above.

When pushing to a branch on github all tests are run (unit and system). This is configured [here](.github/workflows/test.yml). You are not allowed to merge a branch (onto main or production) without a passing test suite.

## Contributing

We welcome new contributors but strongly recommend you have a chat with us in [Geeks for Social Change's Discord server](http://discord.gfsc.studio) and say hi before you do. We will be happy to onboard you properly before you get stuck in.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M43THUM)
