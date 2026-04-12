.PHONY: start stop prerequisites serve_content build

PROJECT_NAME:=theatomicity.com
STACK_NAME:=the-atomicity-com
HOSTED_ZONE_ID:=Z1V5NVBGOC3M9Z
HOST_PORT:=8000
IMAGE_NAME:=the-atomicity-com

TERRAFORM_IMAGE:=oowy/opentofu
BUILD_IMAGE:=python-mkdocs-theme

prerequisites:
	aws cloudformation deploy \
			--stack-name $(STACK_NAME)-pre-requisites \
			--capabilities CAPABILITY_NAMED_IAM \
			--template-file infra/aws/pre-requisites/iam.yml

run_content:
	docker build -t $(IMAGE_NAME)-build \
		-f Dockerfile.run.local \
		--progress=plain --no-cache \
		. && \
	echo $(IMAGE_NAME)-build running on localhost:$(HOST_PORT) && \
	docker run -p $(HOST_PORT):80 $(IMAGE_NAME)-build


build_image:
	docker build -f Dockerfile.build -t $(BUILD_IMAGE) .

build_content: build_image
	docker run --rm \
	-v $$(pwd)/mkdocs-landing:/app \
	--workdir /app \
	$(BUILD_IMAGE) python -m mkdocs build

scaleway_init:
	docker run --rm \
	-v $$(pwd)/infra/scaleway/terraform:/opt/tofu \
	-e TF_LOG=debug \
	--env-file=$$(pwd)/infra/scaleway/scw.env \
	$(TERRAFORM_IMAGE) ./_init.sh

scaleway_plan: build_content
	docker run --rm \
	-v $$(pwd)/infra/scaleway/terraform:/opt/tofu \
	-v $$(pwd)/mkdocs-landing/site:/opt/tofu/site \
	--env-file=$$(pwd)/infra/scaleway/scw.env \
	$(TERRAFORM_IMAGE) tofu plan


scaleway_apply: build_content
	docker run --rm \
	-v $$(pwd)/infra/scaleway/terraform:/opt/tofu \
	-v $$(pwd)/mkdocs-landing/site:/opt/tofu/site \
	--env-file=$$(pwd)/infra/scaleway/scw.env \
	$(TERRAFORM_IMAGE) tofu apply -auto-approve

scaleway_destroy:
	docker run --rm \
	-v $$(pwd)/infra/scaleway/terraform:/opt/tofu \
	-v $$(pwd)/mkdocs-landing/site:/opt/tofu/site \
	--env-file=$$(pwd)/infra/scaleway/scw.env \
	$(TERRAFORM_IMAGE) tofu apply -destroy -auto-approve