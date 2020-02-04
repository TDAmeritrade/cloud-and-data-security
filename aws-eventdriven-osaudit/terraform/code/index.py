import boto3
import os
import json
from botocore.exceptions import ClientError


def lambdaHandler(event, context):

    # Print Event
    print("Received event: " + json.dumps(event, sort_keys=True))

    # Lookup Event
    lookupEvent(event, context)


def lookupEvent(event, context):

    # Defining Variables
    aws_accountid = os.environ['aws_accountid']
    ipName = os.environ['syslogip']
    ipArn = 'arn:aws:iam::' + aws_accountid + ':instance-profile/' + ipName

    # Determining Event
    if event['detail']['eventName'] == 'RebootInstances':
        instanceSet = event['detail']['requestParameters']['instancesSet']['items']
        getInstanceIds(instanceSet, ipName, ipArn)

    elif event['detail']['eventName'] == 'StartInstances':
        instanceSet = event['detail']['requestParameters']['instancesSet']['items']
        getInstanceIds(instanceSet, ipName, ipArn)

    elif event['detail']['eventName'] == 'RunInstances':
        instanceSet = event['detail']['responseElements']['instancesSet']['items']
        getInstanceIds(instanceSet, ipName, ipArn)

    else:
        print('Event Not Found')


def getInstanceIds(instanceSet, ipName, ipArn):

    for item in instanceSet:
        instanceId = item['instanceId']
        checkForRoleAssignments(instanceId, ipName, ipArn)


def checkForRoleAssignments(instanceId, ipName, ipArn):

    # Establishing EC2 Client
    client = boto3.client('ec2')

    response = client.describe_instances(
        InstanceIds=[
            instanceId,
        ],
    )

    for reservation in response['Reservations']:
        instances = reservation
        for instance in instances['Instances']:
            if 'IamInstanceProfile' in instance.keys():
                instanceProfileArn = instance['IamInstanceProfile']['Arn']
                print("Key Found. Please remove {0} for a proper assignment to {1}".format(
                    instanceProfileArn, instanceId))
            else:
                print("Gathering {0} Instance State".format(instanceId))
                getInstanceState(instanceId, ipName, ipArn)


def getInstanceState(instanceId, ipName, ipArn):

    # Establishing EC2 Client
    client = boto3.client('ec2')

    response = client.describe_instances(
        InstanceIds=[
            instanceId,
        ],
    )

    for reservation in response['Reservations']:
        instances = reservation
        for instance in instances['Instances']:
            instanceState = instance['State']['Name']
            if instanceState == 'running':
                enableEc2Syslog(instanceId, ipName, ipArn)
            elif instanceState == 'stopped':
                enableEc2Syslog(instanceId, ipName, ipArn)
            else:
                getInstanceState(instanceId, ipName, ipArn)


def enableEc2Syslog(instanceId, ipName, ipArn):

    # Establishing EC2 Client
    client = boto3.client('ec2')

    print("Attaching {0} to {1}".format(ipArn, instanceId))
    response = client.associate_iam_instance_profile(
        IamInstanceProfile={
            'Arn': ipArn,
            'Name': ipName
        },
        InstanceId=instanceId
    )
    