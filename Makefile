.PHONY: test help
.DEFAULT_GOAL := help
region = $(AWS_DEFAULT_REGION)
accountlong := $(shell aws sts get-caller-identity --query "Account" --output text)
account = $(strip $(accountlong))
ecs-task-role-arn = "arn:aws:iam::$(account):role/ecsdemoservice"
cluster = fargate-demo
subnet = $(shell aws cloudformation list-exports --query "Exports[?Name == 'ecsvpc-public-subnet-1'].Value" --output text)
securitygroup := $(shell aws cloudformation list-exports --query "Exports[?Name == 'WebserviceSG'].Value" --output text)
service = fargate-php-demo
task = $(strip fargate-php-demo)


help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###  Create Demo
deploy-all: deploy-vpc deploy-security-groups deploy-iam-ecs-service deploy-cluster deploy-ecr deploy-docker update-task create-service


deploy-vpc: ## (Create 1) VPC in Cloudformation deploy 
	clouds -r $(region) update   -c --events vpc

deploy-security-groups: ## (Create 2) Security Groups CF deploy
	clouds -r $(region) update   -c --events security-groups

deploy-iam-ecs-service: ## (Create 3) Deploy Roles for ECS Services
	clouds update -c --events iam-ecs-service

deploy-cluster: ## (Create 4) Deploy ECS Cluster
	clouds update -c --events ecs

deploy-ecr : ## (Create 5) Deploy ECR registry
	clouds update -c --events ecr

deploy-docker: ## (Create 6) Deploy Container to ECR
	for task in build tag login push ; do \
		$(MAKE) -C docker $$task ; \
	done

update-task:  ## (Create 7) Update task definition php demo
	aws ecs register-task-definition --cli-input-json file://ecs/tasks/taskdef-php.json --region $(region) \
	--execution-role-arn $(ecs-task-role-arn) \
	--task-role-arn $(ecs-task-role-arn)

create-service: ## (Create 8) Create Service
	aws ecs create-service --cluster $(cluster) --service-name $(service) --task-definition $(task) \
		--desired-count 1 --launch-type "FARGATE" \
		--network-configuration "awsvpcConfiguration={subnets=['$(subnet)'],securityGroups=['$(securitygroup)'], assignPublicIp='ENABLED'}"



########

delete-all: delete-service delete-tasks delete-ecr delete-cluster delete-security-groups delete-iam-ecs-service delete-vpc

delete-service: ## (Delete 1)
	aws ecs update-service --desired-count 0 --region $(region) --service $(service) --cluster $(cluster) && aws ecs delete-service --region $(region) --service $(service) --cluster $(cluster)

delete-tasks: ## (Delete 2) Deregister the *last* task definition
	make -C tasks delete-tasks

delete-ecr: ## (Delete 3) Delete Registry *including all images
	make -C docker "delete-ecr-force"
	clouds delete --events -f ecr 

delete-cluster: ## (Delete 4) Remove Cluser
	clouds delete --events -f ecs

delete-security-groups: ## (Delete 5) Delete SG CF
	clouds delete --events -f security-groups

delete-iam-ecs-service: ## (Delete 6) Delete SG CF
	clouds delete --events -f iam-ecs-service

delete-vpc: ## (Delete 7) Delete VPC -CF
	clouds delete --events -f vpc


########

list-stacks: ## List all Cloudformation Stacks
	clouds list

list-vars: ## List vars
	@echo region $(region)
	@echo securitygroup $(securitygroup)
