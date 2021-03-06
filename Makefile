# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
# Git variables

GIT_REPOSITORY_NAME := $(shell basename `git rev-parse --show-toplevel`)
GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')
GITHUB_HEAD_REF ?= "master"
GITHUB_EVENT_NAME ?= "push"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Tasks
# -----------------------------------------------------------------------------
.PHONY: fmt
fmt:
	@gofmt -w -s -d configuration
	@gofmt -w -s -d main.go

.PHONY: build
build: fmt
	@go mod download && \
     go get ./... && \
     go install ./...

# -----------------------------------------------------------------------------
# The first "make" target runs as default.
# -----------------------------------------------------------------------------

.PHONY: default
default: help

# -----------------------------------------------------------------------------
# Docker-based build
# -----------------------------------------------------------------------------

.PHONY: docker-build
docker-build: docker-rmi-for-build
	docker build \
		--build-arg GITHUB_HEAD_REF=$(GITHUB_HEAD_REF) \
		--build-arg GITHUB_EVENT_NAME=$(GITHUB_EVENT_NAME) \
	    --tag $(GIT_REPOSITORY_NAME) \
		--tag $(GIT_REPOSITORY_NAME):$(GIT_VERSION) \
		build/docker

.PHONY: docker-build-development-cache
docker-build-development-cache: docker-rmi-for-build-development-cache
	docker build \
		--build-arg GITHUB_HEAD_REF=$(GITHUB_HEAD_REF) \
		--build-arg GITHUB_EVENT_NAME=$(GITHUB_EVENT_NAME) \
		--tag $(GIT_REPOSITORY_NAME):$(GIT_VERSION) \
		build/docker

# -----------------------------------------------------------------------------
# Clean up targets
# -----------------------------------------------------------------------------

.PHONY: docker-rmi-for-build
docker-rmi-for-build:
	-docker rmi --force \
		$(GIT_REPOSITORY_NAME):$(GIT_VERSION) \
		$(GIT_REPOSITORY_NAME)

.PHONY: docker-rmi-for-build-development-cache
docker-rmi-for-build-development-cache:
	-docker rmi --force $(GIT_REPOSITORY_NAME):$(GIT_VERSION)

.PHONY: clean
clean: docker-rmi-for-build docker-rmi-for-build-development-cache

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

.PHONY: help
help:
	@echo "List of make targets:"
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
