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

.PHONY: usage install run start stop ready logs

