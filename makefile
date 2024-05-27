#REQUIREMENTS BEFORE RUNNING MAKE ALL: ruby, yarn, docker, graphviz, imagemagick, nvm, postgres
.PHONY: test setup

all: test

setup_with_docker: install_dependencies docker setup_env setup_db seed_GFSC_prod_copy_db create_user up

docker: setup_docker_network setup_docker_container setup_env

up:
	docker start placecal-db || true
	bin/dev

down:
	docker stop placecal-db

# does not remove postgres image, just placecal container & network
clean:
	docker stop placecal-db || true
	docker container rm placecal-db || true
	docker network rm placecal-network

install_dependencies:
	yarn
	bundle install

setup_docker_network:
	docker network create placecal-network

setup_docker_container:
	docker create --name placecal-db --network placecal-network --network-alias postgres -p 5432:5432 --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5 -e 'POSTGRES_DB=placecal_dev' -e 'POSTGRES_USER=postgres' -e 'PGUSER=postgres' -e 'POSTGRES_PASSWORD=foobar' -e 'POSTGRES_PORT=5432' postgres:14.1
	docker start placecal-db 

setup_env:
	cp .env.example .env
	echo POSTGRES_HOST=localhost >> .env
	echo POSTGRES_USER=postgres >> .env
	echo PGPASSWORD=foobar >> .env
	echo PGHOST=localhost >> .env
	echo PGUSER=postgres >> .env

setup_db:
	bundle exec rails db:create db:schema:load
	bundle exec rails import:all_events

seed_GFSC_prod_copy_db:
	rails db:dump_production_and_restore_other restore_on_local=1

create_user:
	bundle exec rails runner "User.create!(email: 'info@placecal.org', password: 'password', password_confirmation: 'password', role: :root)"

test:
	time sh -c "rails test --pride && rails test:system && rubocop && prettier -c app/"

tags:
	find app/ lib/ test/ -iname '*.rb' | xargs etags


# Fontello config section
# This is to create the icon font used in various places in the app.
# Use `make fontopen` to load up a browser, then `make fontsave` to add the new icons to the app
# https://github.com/fontello/fontello/wiki/How-to-save-and-load-projects#geek-way---use-makefile

FONT_DIR      ?= ./app/assets/fonts/fontello/
FONTELLO_HOST ?= https://fontello.com

fontopen:
	@if test ! `which curl` ; then \
		echo 'Install curl first.' >&2 ; \
		exit 128 ; \
		fi
	curl --silent --show-error --fail --output .fontello \
		--form "config=@${FONT_DIR}/config.json" \
		${FONTELLO_HOST}
	# FIXME: `open` is for mac because I can't get `x-www-browser` working!
	open ${FONTELLO_HOST}/`cat .fontello`

fontsave:
	@if test ! `which unzip` ; then \
		echo 'Install unzip first.' >&2 ; \
		exit 128 ; \
		fi
	@if test ! -e .fontello ; then \
		echo 'Run `make fontopen` first.' >&2 ; \
		exit 128 ; \
		fi
	rm -rf .fontello.src .fontello.zip
	curl --silent --show-error --fail --output .fontello.zip \
		${FONTELLO_HOST}/`cat .fontello`/get
	unzip .fontello.zip -d .fontello.src
	rm -rf ${FONT_DIR}
	mv `find ./.fontello.src -maxdepth 1 -name 'fontello-*'` ${FONT_DIR}
	rm -rf .fontello.src .fontello.zip
