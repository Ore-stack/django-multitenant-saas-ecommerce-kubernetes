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
	@tail -n +8 Makefile | \
	egrep "^[a-z]+[\ :]" | \
	tr -d : | \
	tr " " "/" | \
	sed "s/^/ - /g"
	@echo "Read the Makefile for further details"

# Create virtual environment and remove any old one
venv virtualenv:
	@echo "Creating a new virtualenv..."
	@rm -rf venv || true
	@python3.11 -m venv venv
	@echo "Done, now you need to activate it. Run:"
	@echo "source venv/bin/activate"

# Activate the virtual environment
activate:
	@echo "Activating the python3.11 Virtual venv Env:"
	@bash --rcfile "./venv/bin/activate"

# Install requirements from requirements.txt
requirements pip:
	@echo "Checking if in virtualenv..."
	@if [ -z "${VIRTUAL_ENV}" ]; then \
		echo "Not inside a virtualenv."; \
		exit 1; \
	fi
	@echo "Upgrading pip..."
	@python3.11 -m pip install --upgrade pip
	@echo "Installing required pip packages..."
	@pip install -r "requirements.txt"
	@echo "All pip libraries installed. You are ready to go! ;-)"
	
# Install dev dependencies from requirements_dev.txt
requirementsdev:
	@echo "Checking if in virtualenv..."
	@if [ -z "${VIRTUAL_ENV}" ]; then \
		echo "Not inside a virtualenv."; \
		exit 1; \
	fi
	@echo "Installing development dependencies..."
	@pip install -r "requirements_dev.txt"
	
# Clean all unwanted files
cleanfull:
	@echo "Cleaning old files..."
	@rm -rf **/.pytest_cache
	@rm -rf .tox
	@rm -rf dist
	@rm -rf build
	@rm -rf **/__pycache__
	@rm -rf *.egg-info
	@rm -rf .coverage*
	@rm -rf **/*.pyc
	@rm -rf env
	@rm -rf venv
	@rm -rf local
	@rm -rf .aws-sam
	@echo "All done!"

# Clean selected files
clean:
	@echo "Cleaning old files..."
	@rm -rf **/.pytest_cache
	@rm -rf .tox
	@rm -rf dist
	@rm -rf build
	@rm -rf **/__pycache__
	@rm -rf *.egg-info
	@rm -rf .coverage*
	@rm -rf **/*.pyc
	@echo "All done!"

# Make database migrations, migrate and start server
start-engine:
	@python3.11 manage.py makemigrations
	@python3.11 manage.py migrate
	@python3.11 manage.py runserver 0.0.0.0:8585

# Build docker image
build:
	@docker build --tag $(shell echo ${DOCKER_USERNAME}/${APPLICATION_NAME} | tr '[:upper:]' '[:lower:]') .

# Push docker image to registry
push:
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}

# Run docker-compose setup
docker-run:
	@docker-compose down 
	@docker-compose build --no-cache
	@docker-compose up

# Release docker image with git hash
release:
	@docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH}
	@docker tag  ${DOCKER_USERNAME}/${APPLICATION_NAME}:${GIT_HASH} ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest
	@docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest

# Running tests
test:
	@echo "Setting up virtual environment if not already present..."
	@if [ ! -d "venv" ]; then python3.11 -m venv venv; fi
	@echo "Activating virtual environment and installing requirements..."
	@bash -c "source venv/bin/activate && pip install -r requirements.txt"
	@echo "Running tests..."
	@bash -c "source venv/bin/activate && pytest tests/"
