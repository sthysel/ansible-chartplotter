SHELL := /bin/bash
.SHELLFLAGS = -ec
LIMIT ?=NA
TAGS ?= "all"
ANSIBLE_ARGS = ""

ifeq (, $(shell which poetry))
	$(error "No poetry in $(PATH), do \$make env/bootstrap")
endif

-include .env

.ONESHELL:
.EXPORT_ALL_VARIABLES:

env/install-poetry: ## Install poetry
	curl -sSL https://install.python-poetry.org | python3 -

env/install-tooling: ## Prepare Python environment
	poetry install
	poetry run ansible-galaxy collections install -r requirements.yml

env/bootstrap: env/install-poetry env/install-tooling ## Bootstrap ansible environment into existence

qa/install-pre-commit-hooks:  ## Install pre-commit hooks
	poetry run pre-commit install

.PHONY: qa/all
qa/all:  ## Run pre-commit QA pipeline on all files
	poetry run pre-commit run --all-files

deploy: ## Deploy against inventory
	echo "Limiting deployment to ${LIMIT}"
	poetry run ansible-playbook \
		-u thys \
		-i inventories/ \
		--limit ${LIMIT} \
		--tags ${TAGS} \
		provision.yml

.DEFAULT_GOAL := help
.PHONY: help
help: ## Print Makefile help
	@grep --no-filename -E '^[a-zA-Z_\/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
