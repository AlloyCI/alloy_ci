TAG ?= bleeding

run:
	./run.sh

build:
	docker pull elixir:latest
	docker pull elixir:slim
	docker build ./ -t alloy_ci:$(TAG)

publish:
	docker tag alloy_ci:$(TAG) alloyci/alloy_ci:$(TAG)
	docker push alloyci/alloy_ci:$(TAG)

release: TAG := $(shell echo "$(CI_COMMIT_REF_SLUG)" | sed 's/v//')
release:
	make build
	docker login --username $(DOCKER_HUB_USER) --password $(DOCKER_HUB_PASSWORD)
	make publish

shipit:
	make build
	make publish
