import boto3
import os
import json
from botocore.exceptions import ClientError

def lambda_handler(event, context): 
    
    # Print Event
    print("Received event: " + json.dumps(event, sort_keys=True))

    # Calling enable_flowlogs function
    enable_flowlogs(event, context)

def enable_flowlogs(event, context):

    # Defining Variables
    vpcId = event['detail']['responseElements']['vpc']['vpcId']
    aws_accountid = os.environ['aws_accountid']
    aws_region = os.environ['AWS_REGION']
    logrole = os.environ['stack_logrole']
    logdest_arn = 'arn:aws:logs:' + aws_region + ':' + aws_accountid + ':log-group:/aws/vpc/' + aws_accountid + '/' + aws_region + '/flowlogs'
    logrole_arn = 'arn:aws:iam::' + aws_accountid + ':role/' + logrole

    # Establishing EC2 Client
    client = boto3.client('ec2')

    # Enabling VPC Flow Logs
    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html#EC2.Client.create_flow_logs
    try:
        response = client.create_flow_logs(
            DeliverLogsPermissionArn=logrole_arn,
            ResourceType='VPC',
            TrafficType='ALL',
            LogDestinationType='cloud-watch-logs',
            LogDestination=logdest_arn,
            ResourceIds=[vpcId]
        )
    
        # Validating Response
        if response['ResponseMetadata']['HTTPStatusCode'] != 200:
            print("Flow logs weren't enabled on " + vpcId)
        else:
            print("Flow logs were enabled on " + vpcId)

    # Handling exceptions
    except ClientError as e:
        if e.response['Error']['Code'] == "InvalidVpcId.NotFound":
            print("{} could not be found".format(vpcId))
        else:
            raise
