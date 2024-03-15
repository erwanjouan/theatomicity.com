PROJECT_NAME:=theatomicity.com
STACK_NAME:=the-atomicity-com
HOSTED_ZONE_ID:=Z1V5NVBGOC3M9Z

start:
	aws cloudformation deploy \
			--stack-name $(STACK_NAME) \
			--template-file cloudformation/infra.yml \
			--parameter-overrides \
				HostedZoneID=$(HOSTED_ZONE_ID) \
				Domain=$(PROJECT_NAME) && \
	docker build -t $(PROJECT_NAME) .
	docker run --rm -ti -v ~/.aws:/root/.aws $(PROJECT_NAME) s3 sync /tmp s3://$(PROJECT_NAME)

run_local:
	export IMAGE_NAME=static_web_hosting && \
	export HOST_PORT=8080 && \
	docker build -t $${IMAGE_NAME} -f Dockerfile.local . && \
	echo $${IMAGE_NAME} running on localhost:$${HOST_PORT} && \
	docker run -p $${HOST_PORT}:80 $${IMAGE_NAME}

stop:
	docker run --rm -ti -v ~/.aws:/root/.aws $(PROJECT_NAME) s3 rm s3://$(PROJECT_NAME) --recursive && \
	aws cloudformation delete-stack --stack-name $(STACK_NAME)
