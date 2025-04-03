ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif
SHELL := /bin/bash
.DEFAULT_GOAL := help

DOCKER_USERNAME ?= biglanche
APPLICATION_NAME ?= prodxcloud-django-web
GIT_HASH ?= $(shell git log --format="%h" -n 1)

help:
	@echo "Use one of the following targets:"
	@tail -n +8 Makefile |\
	egrep "^[a-z]+[\ :]" |\
	tr -d : |\
	tr " " "/" |\
	sed "s/^/ - /g"
	@echo "Read the Makefile for further details"

venv virtualenv:
	@echo "Creating a new virtualenv..."
	@rm -rf venv || true
	@python3.11 -m venv venv
	@echo "Done, now you need to activate it. Run:"
	@echo "source venv/bin/activate"

activate:
	@echo "Activating this python3.11 virtual environment:"
	@bash --rcfile "./venv/bin/activate"

requirements pip:
	@if [ -z "${VIRTUAL_ENV}" ]; then \
		echo "Not inside a virtualenv."; \
		exit 1; \
	fi
	@echo "Upgrading pip..."
	@python3.11 -m pip install --upgrade pip
	@echo "Installing required packages..."
	@pip install -r "requirements.txt"
	@echo "All dependencies installed. You're ready to go!"

requirementsdev:
	@if [ -z "${VIRTUAL_ENV}" ]; then \
		echo "Not inside a virtualenv."; \
		exit 1; \
	fi
	@echo "Upgrading pip..."
	@pip install -r "requirements_dev.txt"

cleanfull:
	@echo "Cleaning all temporary and cache files..."
	@rm -rf **/.pytest_cache .tox dist build **/__pycache__ *.egg-info .coverage* **/*.pyc env venv local .aws-sam
	@echo "Cleanup complete!"

clean:
	@echo "Removing temporary and cache files..."
	@rm -rf **/.pytest_cache .tox dist build **/__pycache__ *.egg-info .coverage* **/*.pyc
	@echo "Basic cleanup complete!"

start-engine:
	@python3.11 manage.py makemigrations
	@python3.11 manage.py migrate
	@python3.11 manage.py runserver 0.0.0.0:8585

build:
	@docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME} .

push:
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}

docker-run:
	@docker-compose down
	@docker-compose build --no-cache
	@docker-compose up

release:
	@docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH}
	@docker tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH} ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest

test:
	@echo "Running tests..."
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@source venv/bin/activate && pip install -r requirements.txt
	@source venv/bin/activate && pytest tests/
