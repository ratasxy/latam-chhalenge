import json


def lambda_handler(event, context):
    name = event['name']

    return {
        'statusCode': 200,
        'body': json.dumps('Hello ' + name)
    }