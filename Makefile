.PHONY: start stop prerequisites serve_content build

PROJECT_NAME:=theatomicity.com
STACK_NAME:=the-atomicity-com
HOSTED_ZONE_ID:=Z1V5NVBGOC3M9Z
HOST_PORT:=8000
IMAGE_NAME:=the-atomicity-com

prerequisites:
	aws cloudformation deploy \
			--stack-name $(STACK_NAME)-pre-requisites \
			--capabilities CAPABILITY_NAMED_IAM \
			--template-file infra/pre-requisites/iam.yml
deploy:
	aws cloudformation deploy \
			--stack-name $(STACK_NAME) \
			--template-file infra/cloudformation/infra.yml \
			--parameter-overrides \
				HostedZoneID=$(HOSTED_ZONE_ID) \
				Domain=$(PROJECT_NAME) && \
	docker build -t $(PROJECT_NAME) .
	docker run --rm -ti -v ~/.aws:/root/.aws $(PROJECT_NAME) s3 sync /tmp s3://$(PROJECT_NAME)

undeploy:
	docker run --rm -ti -v ~/.aws:/root/.aws $(PROJECT_NAME) s3 rm s3://$(PROJECT_NAME) --recursive && \
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

run_content:
	docker build -t $(IMAGE_NAME)-build \
		-f Dockerfile.build \
		--progress=plain --no-cache \
		. && \
	echo $(IMAGE_NAME)-build running on localhost:$(HOST_PORT) && \
	docker run -p $(HOST_PORT):80 $(IMAGE_NAME)-build
