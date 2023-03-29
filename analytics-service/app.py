import boto3
from datetime import date
import json
import os
import uuid

BUCKET_NAME = os.environ['BUCKET_NAME']
endpoint_url = "http://localhost.localstack.cloud:4566"
s3 = boto3.client('s3', endpoint_url=endpoint_url)

def lambda_handler(event, context):
    print('EVENT: {}'.format(json.dumps(event)))

    today = date.today()
    year = today.year
    month = today.month
    day = today.day
    objectId = str(uuid.uuid4())
    body = {'Records': []}

    for record in event['Records']:
        body['Records'].append(json.loads(record['body']))

    response = s3.put_object(
        Bucket=BUCKET_NAME,
        Key=f'{year}/{month}/{day}/{objectId}',
        Body=json.dumps(body)
    )
    print('put object and received response: {}'.format(response))

    return
