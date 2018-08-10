region =  $(AWS_DEFAULT_REGION)
accountlong := $(shell aws sts get-caller-identity --query "Account" --output text)
account = $(strip $(accountlong))
name = fargate-demo
ecr_repo = fargate-demo
###

build:
	docker build -t fargate-demo .

tag:
	docker tag fargate-demo:latest $(account).dkr.ecr.$(region).amazonaws.com/$(name):latest

run:
	docker run --rm --name simple -p 80:80 $(name) -d

ps:
	docker ps -a

push:
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(name):latest

login:
	$(shell eval "$(aws ecr get-login --region $(region) --no-include-email)")

delete-ecr-force:
	aws ecr delete-repository --repository-name $(ecr_repo) --force

list-vars:
	@echo region: $(region)
	@echo account: $(account)
