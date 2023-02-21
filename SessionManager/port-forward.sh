#!/usr/bin/bash

RED="\e[31m"

command -v aws >/dev/null 2>&1 || { echo >&2 "I require AWS CLI but it's not installed.  Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed.  Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }

IDENTITY=$(aws sts get-caller-identity 2> /dev/null)

if [ ! $? -eq 0 ]; then
  echo "Error while checking AWS identity. Check output of 'aws sts get-caller-identity'. Is your profile set?"
  exit 1
fi

ARN=$(echo $IDENTITY | jq .Arn -r)
echo "Your ARN: $ARN"
ACCOUNT=$(echo $IDENTITY | jq .Account -r)
echo "AWS Account: $ACCOUNT"

echo

echo "Instances with a populated Name tag"
echo "--------------------------"
echo 

aws ec2 describe-instances | jq '.Reservations[].Instances[].Tags[] | select(.Key | contains("Name")) | .Value' --raw-output

echo

echo "If the instance you want does not appear, check to ensure it has a populated Name tag."

echo

read -p "Paste instance name here: " instance

INSTANCE_ID=$(aws ec2 describe-instances \
               --filter "Name=tag:Name,Values=${instance}" \
               --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" \
               --output text)

if [ -z $INSTANCE_ID ]
then
	echo "No instance with that Name found. Exiting."
	exit
fi

echo "Instance ID: ${INSTANCE_ID}"

echo "HINT 1: If session establishment is successful, use your SSH client to connect to local port 2222 on your workstation."
echo "HINT 2: WSL2? Ports bound to localhost in the WSL2 VM *should* be connectible using localhost on your host workstation."

echo "Attempting port forward of remote port 22 to local port 2222..."

aws ssm start-session --target $INSTANCE_ID \
                       --document-name AWS-StartPortForwardingSession \
                       --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}'
