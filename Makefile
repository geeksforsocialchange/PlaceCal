TIME := $(shell command -v time 2>/dev/null || echo "")

#REQUIREMENTS BEFORE RUNNING MAKE ALL: ruby, yarn, docker, graphviz, imagemagick, nvm, postgres
.PHONY: test setup

all: test

setup_with_docker: install_dependencies docker setup_env setup_db seed_GFSC_prod_copy_db up

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
	docker create --name placecal-db --network placecal-network --network-alias postgres -p 5432:5432 --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5 -e 'POSTGRES_DB=placecal_dev' -e 'POSTGRES_USER=postgres' -e 'PGUSER=postgres' -e 'POSTGRES_PASSWORD=foobar' -e 'POSTGRES_PORT=5432' postgres:16
	docker start placecal-db

setup_env:
	cp .env.example .env
	echo POSTGRES_HOST=localhost >> .env
	echo POSTGRES_USER=postgres >> .env
	echo PGPASSWORD=foobar >> .env
	echo PGHOST=localhost >> .env
	echo PGUSER=postgres >> .env

setup_db:
	bundle exec rails db:prepare
	bundle exec rails db:seed

seed_GFSC_prod_copy_db:
	rails db:dump_production_and_restore_other restore_on_local=1

test:
	$(TIME) sh -c "bundle exec rspec && bundle exec cucumber --tags 'not @wip' && rubocop && prettier -c app/"

tags:
	find app/ lib/ spec/ -iname '*.rb' | xargs etags
