TAG ?= $(shell echo "$(CI_COMMIT_REF_SLUG)" | sed 's/v//')

run:
	./bin/run

unit:
	./bin/test

build:
	docker pull elixir:latest
	docker pull elixir:slim
	docker build ./ -t alloy_ci:$(TAG)

publish:
	docker tag alloy_ci:$(TAG) alloyci/alloy_ci:$(TAG)
	docker push alloyci/alloy_ci:$(TAG)

release:
	make build
	./bin/prepare_credentials
	cat /tmp/credentials | docker login --username $(DOCKER_HUB_USER) --password-stdin
	make publish
	make latest

latest:
	docker tag alloy_ci:$(TAG) alloyci/alloy_ci:latest
	docker push alloyci/alloy_ci:latest

shipit:
	make build
	make publish
