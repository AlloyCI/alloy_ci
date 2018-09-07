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

shipit:
	make build
	make publish	
