# PlaceCal

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/).

## Requirements

To run PlaceCal locally you will need:

- A Mac or a Linux machine (we don't support Windows at present)
- GNU Compiler Collection (gcc) (for compiling ruby and gems)
- Docker (optional) (for isolating and automating postgres management)
- Postgres relational database. We are currently using v14.
  - Server
    - either installed for your distribution or as a docker image (with the correct open port -- see below)
  - Client
    - you will still need the local developer libraries for postgres
    - these are distribution specific so you need to find out what they are called to install them
      - `libpq-dev` (debian)
      - `postgresql-libs` (arch)
      - `dev-db/postgresql` (gentoo)
- Ruby 2.7.x. We reccomend using a version manager for this such as `rvm` or `rbenv`. Current version we are using is in `.ruby-version`.
  - [rvm](https://rvm.io/)
  - [rbenv](https://github.com/rbenv/rbenv)
    - [ruby-build](https://github.com/rbenv/ruby-build)
    - [rbenv-gemset](https://github.com/jf/rbenv-gemset) (optional)
- Node.js 16.x. We recommend using a version manager for this such as `nvm` or `nodenv`. Current version we are using is in `.node-version`.
  - [nvm](https://github.com/nvm-sh/nvm)
  - [nodenv](https://github.com/nodenv/nodenv)
- Yarn 1.x
  - [yarn](https://classic.yarnpkg.com/en/docs/install)
- ImageMagick for image manipulation
- [Graphviz](https://voormedia.github.io/rails-erd/install.html) for documentation diagrams
- Chrome/Chromium for system tests along with a matching version of [Chromedriver](https://chromedriver.chromium.org/)

## Quickstart with docker for GFSC devs

First you need to append `lvh.me *.lvh.me` to your `/etc/hosts` file as a DNS alias for `127.0.0.1`.

Make sure all of the above dependencies are installed (and ask someone to add your public ssh key to the servers if you are staff).

Then make sure the docker daemon is running, and run

```sh
make setup_with_docker
```

Local site is now running at `lvh.me:3000`

Some other useful commands for developing can be found in the makefile.

### Run the setup script

```sh
bin/setup
```

Amongst other things, this will create an admin user for you:

- Username: `root@placecal.org`
- Password: `password`

### Run the thing

- Start the server with `bin/dev`
- Make sure you use `lvh.me:3000` instead of `localhost:3000` or you **will** have authentication problems
- The admin interface is at `admin.lvh.me:3000`
- Access code docs through your local filesystem and update them with `bin/rails yard`

## Testing

PlaceCal tests are written in minitest.

Before running the tests please make sure your development environment is up to date (you can run `bin/update` to quickly do that).

You can run the tests with:

```sh
make              # will run all unit and system tests then lint check all code
rails test        # will run all unit tests
rails test:system # will run system tests
```

Note that the system tests can take a while to run and are quite resource-intensive. To perform more advanced usage like executing only a specific test or test file, see the [Rails documentation on testing](https://guides.rubyonrails.org/testing.html).

## Documentation for Developers

The documentation for PlaceCal currently stored in notion and can be read [here](https://www.notion.so/gfsc/PlaceCal-developer-handbook-01649b69009340e3ae3035e9cf346f27). There is also a small amount of documentation sprinkled throughout the code itself and can be turned into HTML by running `rails doc:generate`. If you are working with the code and are completely lost you can also try the GFSC discord server where you can prod a human for answers. Good Luck!

### Generating new components

We use view_component to make components, and you can create a new one by running `rails g component <Name> <args>`
More info here: https://viewcomponent.org/guide/generators.html

## Formatting

We use [Prettier](https://prettier.io/) to format everything it's able to parse. It will run as a pre-commit hook and format your changes as you make commits so you shouldn't have to think about it much.

If you do want to run it manually, you can:

```sh
bin/yarn run format
```

It's also run for you by the test runner.

Note that we use tabs over spaces because [tabs are more accessible to people using braille displays](https://twitter.com/Rich_Harris/status/1541761871585464323).

## Linting

We use Rubocop to lint our Ruby code. Because of the time it can take to run, this is a manual step:

```sh
bin/bundle exec rubocop --autocorrect
```

It's also run for you by the test runner.

## Contributing

We welcome new contributors but strongly recommend you have a chat with us in [Geeks for Social Change's Discord server](http://discord.gfsc.studio) and say hi before you do. We will be happy to onboard you properly before you get stuck in.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M43THUM)
