import boto3
from datetime import datetime
import json
import os
import random
import uuid

TOPIC_ARN = os.environ['TOPIC_ARN']
endpoint_url = "http://localhost.localstack.cloud:4566"
sns = boto3.client('sns', endpoint_url=endpoint_url)

def lambda_handler(event, context):
    jobId = str(random.randrange(0, 1000))

    send_job_created_event(jobId)
    send_job_updated_event(jobId)
    send_job_deleted_event(jobId)

    return


def send_job_created_event(jobId):
    messageId = str(uuid.uuid4())

    response = sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=f'Job {jobId} created',
        MessageDeduplicationId=messageId,
        MessageGroupId=f'JOB-{jobId}',
        Message=json.dumps({
            "id": messageId,
            "jobId": jobId,
            "eventCreated": str(datetime.now()),
            "eventType": "JobCreated",
            "eventSource": "anti-corruption-service",
            "eventDetails": {
                "jobCategory": "Architecture and Engineering",
                "employer": "a2z.com",
                "jobDescription": "Lorem ipsum dolor sit amet, consectetur ...",
                "jobRequirements": "Ut enim ad minim veniam, quis nostrud exercitation ullamco ...",
                "anualSalary": "$ 55,000"
            }
        }),
        MessageAttributes = {
            "eventType": {
                "DataType": "String",
                "StringValue": "JobCreated"
            }
        }
    )
    print('sent message and received response: {}'.format(response))
    return


def send_job_updated_event(jobId):
    messageId = str(uuid.uuid4())

    response = sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=f'Job {jobId} updated',
        MessageDeduplicationId=messageId,
        MessageGroupId=f'JOB-{jobId}',
        Message=json.dumps({
            "id": messageId,
            "jobId": jobId,
            "eventCreated": str(datetime.now()),
            "eventType": "JobSalaryUpdated",
            "eventSource": "anti-corruption-service",
            "eventDetails": {
                "anualSalary": "$ 57,000"
            }
        }),
        MessageAttributes = {
            "eventType": {
                "DataType": "String",
                "StringValue": "JobSalaryUpdated"
            }
        }
    )
    print('sent message and received response: {}'.format(response))
    return


def send_job_deleted_event(jobId):
    messageId = str(uuid.uuid4())

    response = sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=f'Job {jobId} deleted',
        MessageDeduplicationId=messageId,
        MessageGroupId=f'JOB-{jobId}',
        Message=json.dumps({
            "id": messageId,
            "jobId": jobId,
            "eventCreated": str(datetime.now()),
            "eventType": "JobDeleted",
            "eventSource": "anti-corruption-service",
            "eventDetails": {
                "reason": "filled"
            }
        }),
        MessageAttributes = {
            "eventType": {
                "DataType": "String",
                "StringValue": "JobDeleted"
            }
        }
    )
    print('sent message and received response: {}'.format(response))
    return