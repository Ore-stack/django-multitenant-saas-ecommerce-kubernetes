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

# Virtual environment setup
venv:
	@echo "Creating a new virtualenv..."
	@rm -rf venv || true
	@python3.11 -m venv venv
	@echo "Done. Run 'make activate' to activate it."

# Activating virtual environment
activate:
	@echo "Activating the Python virtual environment..."
	@source venv/bin/activate && exec bash

# Installing requirements
requirements:
	@test -d "venv" || (echo "Virtual environment not found! Run 'make venv' first." && exit 1)
	@echo "Upgrading pip..."
	@venv/bin/python -m pip install --upgrade pip
	@echo "Installing required packages..."
	@venv/bin/pip install -r "requirements.txt"
	@echo "All dependencies installed. You're ready to go!"

requirementsdev:
	@test -d "venv" || (echo "Virtual environment not found! Run 'make venv' first." && exit 1)
	@echo "Installing development dependencies..."
	@venv/bin/pip install -r "requirements_dev.txt"

# Cleaning up temporary and cache files
cleanfull:
	@echo "Cleaning all temporary and cache files..."
	@find . -name '__pycache__' -o -name '*.pyc' -o -name '.pytest_cache' -o -name '*.egg-info' | xargs rm -rf
	@rm -rf .tox dist build .coverage* venv local .aws-sam
	@echo "Cleanup complete!"

clean:
	@echo "Removing temporary and cache files..."
	@find . -name '__pycache__' -o -name '*.pyc' -o -name '.pytest_cache' | xargs rm -rf
	@rm -rf .tox dist build .coverage*
	@echo "Basic cleanup complete!"

# Starting the engine (migrations and server)
start-engine:
	@venv/bin/python manage.py makemigrations
	@venv/bin/python manage.py migrate
	@venv/bin/python manage.py runserver 0.0.0.0:8585

# Build the docker image
build:
	@docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME} .

# Push the docker image
push:
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}

# Run the docker-compose setup
docker-run:
	@docker-compose down
	@docker-compose build --no-cache
	@docker-compose up

# Release the docker image with git hash
release:
	@docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH}
	@docker tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH} ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest

# Running tests
test:
	@echo "Setting up virtual environment if not already present..."
	@if [ ! -d "venv" ]; then make venv; fi
	@echo "Activating virtual environment and installing requirements..."
	@venv/bin/pip install -r requirements.txt
	@echo "Running tests..."
	@venv/bin/pytest tests/

# Running tests without setting up venv
run-tests:
	@test -d "venv" || (echo "Virtual environment not found! Run 'make venv' first." && exit 1)
	@echo "Running tests (assuming venv is already set up)..."
	@venv/bin/pytest tests/
