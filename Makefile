DOCKER_DIR            = .docker
DOCKER_COMPOSE        = docker-compose

EXEC_PHP_CONTAINER    = ${DOCKER_DIR}/bin/docker-php
ECHO                  = ${DOCKER_DIR}/bin/display-job-title

NPM                   = $(EXEC_PHP_CONTAINER) npm
SYMFONY               = $(EXEC_PHP_CONTAINER) bin/console

FILES = .
FILES_PHP = src tests

##
## Container
## ----
##
php:
	$(EXEC_PHP_CONTAINER) $(filter-out $@,$(MAKECMDGOALS))

##
## Environment
## -----------
##

project-install: docker-build dev-start composer-install npm assets-dev db-reset ## Install the project and start the dev environment

project-remove: docker-kill ## Stop the dev environment and remove generated files
	$(ECHO) "Removing files"
	rm -rf vendor var node_modules

project-reinstall: project-remove project-install ## Destroy the dev environment, run a fresh install of the project, then start the dev environment

dev-start: ## Start the dev environment
	$(ECHO) "Starting docker"
	$(DOCKER_COMPOSE) --env-file .env.local up -d --remove-orphans --no-recreate

dev-stop: ## Stop the dev environment
	$(ECHO) "Stopping docker"
	$(DOCKER_COMPOSE) down

##
## Data
## ----
##

db-reset: wait-for-db ## Reset Symfony database with default data
	$(ECHO) "Loading Symfony database"
	$(SYMFONY) doctrine:database:drop --force --if-exists
	$(SYMFONY) doctrine:database:create
	$(SYMFONY) doctrine:schema:create
#	$(ECHO) "Loading Symfony fixtures"
#	$(SYMFONY) doctrine:fixtures:load --no-interaction

##
## Assets
##-------

npm: ## Update npm packages
	$(ECHO) "Installing npm"
	$(NPM) install

assets-watch: ## Watch the assets and build their development version on file change
	$(ECHO) "Watching assets changes"
	$(NPM) run watch

assets-dev: ## Build the development version of the assets
	$(ECHO) "Building dev assets"
	$(NPM) run dev

assets-prod: ## Build the production version of the assets
	$(ECHO) "Building prod assets"
	$(NPM) run build

##
## Quality
## -------
##

cs-fixer: ## Apply php-cs-fixer
	$(ECHO) "Running php-cs-fixer"
	$(EXEC_PHP_CONTAINER) vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.dist.php -v --using-cache=no

phpstan: ## Run phpstan
	$(ECHO) "Running phpstan"
	$(EXEC_PHP_CONTAINER) vendor/bin/phpstan analyse $(FILES_PHP)

prettier: ## Run prettier
	$(ECHO) "Running Prettier"
	$(EXEC_PHP_CONTAINER) npx prettier --write $(FILES)

quality: cs-fixer phpstan prettier-check ## Shortcut for main quality commands

prettier-check: ## Check if files are formatted by Prettier
	$(ECHO) "Checking files with Prettier"
	$(EXEC_PHP_CONTAINER) npx prettier --check $(FILES)

phpunit: ## Run unit tests
	$(ECHO) "Running tests"
	$(EXEC_PHP_CONTAINER) bin/phpunit

phpunit-report: ## Run unit tests and generate code coverage report in HTML
	$(ECHO) "Running tests and generating code coverage report"
	$(EXEC_PHP_CONTAINER) bin/phpunit --coverage-html tests/report

browserslist: ## Update Browser Data
	$(ECHO) "Updating Browser Data"
	$(EXEC_PHP_CONTAINER) npx browserslist@latest --update-db

composer-unused: ## Run composer-unused to check for unused packages
	$(EXEC_PHP_CONTAINER) php composer-unused.phar

##
## Debug
## -----
##

apache-error-log: ## Display the last entries from Apache error log
	$(ECHO) "Displaying in real time last entries from Apache error log" "Use CTRL+C to close the process"
	$(EXEC_PHP_CONTAINER) tail -f /var/log/apache2/error.log

apache-access-log: ## Display the last entries from Apache access log
	$(ECHO) "Displaying last entries from Apache access log" "Use CTRL+C to close the process"
	$(EXEC_PHP_CONTAINER) tail -f /var/log/apache2/access.log

##
#
# Internal rules
# --------------
#

composer-install:
	$(ECHO) "Installing Symfony vendors"
	$(EXEC_PHP_CONTAINER) composer install

download-composer-unused:
	$(ECHO) "Downloading composer-unused"
	$(EXEC_PHP_CONTAINER) curl -JOL https://github.com/icanhazstring/composer-unused/releases/latest/download/composer-unused.phar

docker-build:
	$(ECHO) "Building docker"
	$(DOCKER_COMPOSE) build --pull

docker-kill:
	$(ECHO) "Killing docker"
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

wait-for-db:
	$(ECHO) "Waiting for db"
	$(DOCKER_DIR)/bin/wait-for-db

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
