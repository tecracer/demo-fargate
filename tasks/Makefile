region =  $(AWS_DEFAULT_REGION)
taskdef := $(shell 	aws ecs describe-task-definition --task-definition "fargate-php-demo" --region $(region) --query "taskDefinition.taskDefinitionArn" --output text | cut -d'/' -f2)

delete-tasks: ## (Delete 2) Deregister the *last* task definition
	aws ecs deregister-task-definition --task-definition $(taskdef) --region $(region)

list-vars:
	@echo taskdef: $(taskdef)
	@echo region: $(region)
