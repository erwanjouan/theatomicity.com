PROJECT_NAME:=beta-the-atomicity-com
start:
	aws cloudformation deploy \
			--stack-name $(PROJECT_NAME) \
			--template-file cloudformation/infra.yml \
			--parameter-overrides \
				Domain=$(PROJECT_NAME)

sync:
	docker build -t $(PROJECT_NAME) .
