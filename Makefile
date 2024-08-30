export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

## Show this help
usage:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

## Install dependencies
install:
	@which localstack || pip install localstack
	@which awslocal || pip install awscli-local
	@which samlocal || pip install aws-sam-cli-local

# Deploy the infrastructure
build:
	samlocal build

## Deploy the infrastructure
deploy:
	samlocal deploy --resolve-s3 --no-confirm-changeset

## Start LocalStack in detached mode
start:
	localstack start -d

## Stop the Running LocalStack container
stop:
	@echo
	localstack stop

## Make sure the LocalStack container is up
ready:
	@echo Waiting on the LocalStack container...
	@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

## Save the logs in a separate file, since the LS container will only contain the logs of the last sample run.
logs:
	@localstack logs > logs.txt

## use awscli to interact with the localstack
awscli:
	aws configure set aws_access_key_id "dummy" --profile test-profile
	aws configure set aws_secret_access_key "dummy" --profile test-profile
	aws configure set region "us-east-1" --profile test-profile
	aws configure set output "table" --profile test-profile

## use awscli with SQS - create topic 
test-sqs-queue:
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs create-queue --queue-name test-queue
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs list-queues
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs get-queue-attributes --queue-url http://localhost:4566/000000000000/test-queue --attribute-names All
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs send-message --queue-url http://localhost:4566/000000000000/test-queue --message-body "Hello World"
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs receive-message --queue-url http://localhost:4566/000000000000/test-queue
	aws --endpoint-url=http://localhost:4566 --profile test-profile sqs delete-queue --queue-url http://localhost:4566/000000000000/test-queue

test-sns-topic:
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs create-queue --queue-name dummy-queue --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs create-queue --queue-name order-notification-queues --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns create-topic --name order-creation-events --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-topics --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs list-queues --output table

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:order-creation-events --protocol sqs --notification-endpoint arn:aws:sns:us-east-1:000000000000:order-notification-queues --output table

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns publish --topic-arn arn:aws:sns:us-east-1:000000000000:order-creation-events --message "Hello World" --output json

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url http://localhost:4566/000000000000/order-notification-queues --output json

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region eu-east-1 sqs send-message --queue-url http://localhost:4566/000000000000/order-notification-queues --message-body '{
		"event_id": "7456c8ee-949d-4100-a0c6-6ae8e581ae15",
		"event_time": "2024-08-29T23:42:47Z",
		"data": {
		"test": 83411999
		}
	}'

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:order-creation-events --output table

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns unsubscribe --subscription-arn arn:aws:sns:us-east-1:000000000000:order-creation-events:00000000-0000-0000-0000-000000000000 --output table

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url http://localhost:4566/000000000000/order-notification-queues --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns delete-topic --topic-arn arn:aws:sns:us-east-1:000000000000:order-creation-events --output table

aws_lambda.AntiCorruptionFunction:
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 lambda create-function --function-name AntiCorruptionFunction --runtime python3.8 --role arn:aws:iam::000000000000:role/lambda-role --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.zip --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 lambda list-functions --output table
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 lambda invoke --cli-binary-format raw-in-base64-out --function-name sam-app-AntiCorruptionFunction-b8a25edf --invocation-type Event --cli-binary-format raw-in-base64-out --payload '{ "name": "Bob" }' --output json response.json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 lambda list-tags --resource  arn:aws:lambda:us-east-1:000000000000:function:sam-app-AntiCorruptionFunction-b8a25edf --output table 
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 lambda delete-function --function-name anti-corruption-function --output table

aws_sns.JobEvents:
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-topics
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-topics
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-subscriptions
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns list-subscriptions-by-topic --topic-arn "arn:aws:sns:us-east-1:000000000000:JobEvents.fifo"

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns publish --topic-arn "arn:aws:sns:us-east-1:000000000000:JobEvents.fifo" --message file://message.txt
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sns publish --topic-arn "arn:aws:sns:us-east-1:000000000000:JobEvents.fifo" --message '{ "req":"123"}' --message-group-id "e962e136-f7ce-4c68" --message-deduplication-id "93b9-9616a6ce0a70"

aws_sqs.AnalyticsSubscriptionDLQ.fifo:
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs create-queue --queue-name AnalyticsSubscriptionDLQ.fifo --attributes FifoQueue=true,ContentBasedDeduplication=true
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs list-queues
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs get-queue-attributes --queue-url "http://localhost:4566/000000000000/AnalyticsSubscriptionDLQ.fifo" --attribute-names All
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs send-message --queue-url "http://localhost:4566/000000000000/AnalyticsSubscriptionDLQ.fifo" --message-body "Hello World"
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://localhost:4566/000000000000/AnalyticsSubscriptionDLQ.fifo"
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs delete-queue --queue-url "http://localhost:4566/000000000000/AnalyticsSubscriptionDLQ.fifo"
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs get-queue-attributes --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/AnalyticsSubscriptionDLQ.fifo" --attribute-names All
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/AnalyticsSubscriptionDLQ.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/AnalyticsJobEvents.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/AnalyticsJobEventsDLQ.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/InventoryJobEvents.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/InventoryJobEventsDLQ.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/InventorySubscriptionDLQ.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 sqs receive-message --queue-url "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/AnalyticsSubscriptionDLQ.fifo" --attribute-names All --message-attribute-names All --max-number-of-messages 10 --output json

aws_s3.JobEventsBucket:
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api create-bucket --bucket job-events-bucket
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api list-buckets
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api put-bucket-notification-configuration --bucket job-events-bucket --notification-configuration file://notification.json
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api get-bucket-notification-configuration --bucket job-events-bucket
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api delete-bucket-notification-configuration --bucket job-events-bucket
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api delete-bucket --bucket job-events-bucket
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api list-objects --bucket aws-sam-cli-managed-default-samclisourcebucket-1a23fc05
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api list-objects --bucket sam-app-analyticsbucket-426913d4 --max-items 10
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api get-object --bucket sam-app-analyticsbucket-426913d4 --key "2024/8/29/02802d66-8564-4501-8a03-9d78b30e0251" 02802d66-8564-4501-8a03-9d78b30e0251.file

	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 s3api get-bucket-notification-configuration --bucket sam-app-analyticsbucket-426913d4

aws_dynamodb.JobsInventoryTable:
#	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb create-table --table-name JobsInventoryTable --attribute-definitions AttributeName=job_id,AttributeType=S --key-schema AttributeName=job_id,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb list-tables
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb describe-table --table-name InventoryTable
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb put-item --table-name InventoryTable --item file://02802d66-8564-4501-8a03-9d78b30e0251.json --return-consumed-capacity TOTAL --return-item-collection-metrics SIZE
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb get-item --table-name InventoryTable --key file://02802d66-8564-4501-8a03-9d78b30e0251.json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb scan --table-name InventoryTable --outut json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb scan --table-name InventoryTable --filter-expression "employer = :a" --projection-expression "#E, #JC, #AS" --expression-attribute-names file://dynamodb-exp-attr-names.json --expression-attribute-values file://dynamodb-exp-attr-values.json  --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb scan --table-name InventoryTable --filter-expression "id = :id" --projection-expression "#ID, #E, #JC, #AS" --expression-attribute-names file://dynamodb-exp-attr-names.json --expression-attribute-values file://dynamodb-exp-attr-values.json  --output json
	aws --endpoint-url=http://localhost:4566 --profile test-profile --region us-east-1 dynamodb scan --table-name InventoryTable --filter-expression "id = :id" --projection-expression "#ID" --expression-attribute-names '{\"#ID\":\"id\"}' --expression-attribute-values '{":id": {"S": "9"}}' --output json


.PHONY: usage install run start stop ready logs

