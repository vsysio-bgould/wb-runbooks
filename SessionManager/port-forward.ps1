Write-Host "Port Forwarding Script - This script forwards a port on a remote instance to your local environment."
Write-Host

# Test that AWS CLI is reachable

if ((Get-Command "aws.exe" -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "AWS CLI is missing - please install from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    Exit
}

# Test the SSM plugin is reachable

if ((Get-Command "session-manager-plugin" -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "SSM plugin for AWS CLI needs to be installed - please install from https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
    Exit
}

Write-Host "List of AWS CLI profiles"
Write-Host "------------------------"
aws configure list-profiles
Write-Host

$profile = Read-Host -Prompt "AWS Profile"

$identity = aws sts get-caller-identity --profile $profile | jq.exe .Arn --raw-output

Write-Host "Logged into AWS account as" $identity
Write-Host
Write-Host "Fetching list of EC2 instances ..."

$instances = aws ec2 describe-instances --profile $profile | jq.exe '.Reservations[].Instances[].Tags[] | select(.Key | contains(\"Name\")) | .Value' --raw-output

Write-Host
Write-Host "Available EC2 instances"
Write-Host "-----------------------"
Write-Host $instances -Separator "`n"

Write-Host
$selectInstance = Read-Host -Prompt "Enter name of EC2 instance from list"

$instanceID = aws ec2 describe-instances --filter "Name=tag:Name,Values=$selectInstance" --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" --output text --profile $profile

Write-Host "Instance ID: $instanceID"
Write-Host
Write-Host "Script will attempt to open a Session Manager tunnel with the remote instance. This will forward port 22 on the remote instance to port 2222 on your local environment."
Write-Host "Once the connection is established, connect to port 2222 on your localhost using any SSH or SFTP client."
Write-Host "Note that for SSH connections, you will likely need to disable strict host checking. Putty will pop up with a warning, while the OpenSSH client will need '-o StrictHostKeyChecking=no' in its arguments."
Write-Host
Write-Host "Terminate connection using Ctrl-C"
Write-Host

aws ssm start-session --target $instanceID --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"22\"],\"localPortNumber\":[\"2222\"]}' --profile $profile
