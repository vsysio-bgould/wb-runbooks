$wshell = New-Object -ComObject Wscript.Shell
Write-Host
# Check if the AWS CLI is installed
if (!(Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI is missing - please install from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    $wshell.Popup("AWS CLI is missing. Please install from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html",0,"Missing Feature",0x0)
    Exit
}

# Check if the AWS CLI Session Manager plugin is installed
if (!(Get-Command "session-manager-plugin" -ErrorAction SilentlyContinue)) {
    Write-Host "SSM plugin for AWS CLI needs to be installed - please install from https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
    $wshell.Popup("SSM plugin for AWS CLI needs to be installed - please install from https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html",0,"Missing Feature",0x0)
    Exit
}

# Check if aws cli is configured
if (!(Test-Path -Path "$env:USERPROFILE\.aws\credentials")) {
    Write-Host "Credentials file not detected. Did you run 'aws configure'`?"
    $wshell.Popup("Credentials file not detected. Did you run `aws configure` in a terminal?",0,"Credentials File Absent",0x0)
    Exit
}

if (-not $env:AWS_PROFILE) {
    # Prompt the user to select an AWS CLI profile
    $prompted = 1
    $profileList = (aws configure list-profiles --output text).split("`n")
    $selectedProfile = $profileList | Out-GridView -Title "Select an AWS CLI profile" -PassThru

    $env:AWS_PROFILE = $selectedProfile

    Write-Host "AWS_PROFILE: $env:AWS_PROFILE"
}
else {
    Write-Host "AWS_PROFILE: $env:AWS_PROFILE"
}

if (-not $env:AWS_REGION) {
    # Prompt the user to select an AWS region
    $prompted = 1
    $regionList = (aws ec2 describe-regions --query 'Regions[*].RegionName' --output text).split("`t")
    $selectedRegion = $regionList | Out-GridView -Title "Select an AWS region" -PassThru

    $env:AWS_REGION = $selectedRegion

    Write-Host "AWS_REGION: $env:AWS_REGION"
}
else {
    Write-Host "AWS_REGION: $env:AWS_REGION"
}

if ($prompted) {
    Write-Host
    Write-Host "Handy Hint"
    Write-Host "----------"
    Write-Host "You can suppress prompting of profile & region by setting AWS_PROFILE and AWS_REGION environment variables."
    Write-Host "This can be done in the control panel."
}

Write-Host
Write-Host "Logging into AWS ..."
$selfARN = aws sts get-caller-identity --query 'Arn' --output text

if ($lastExitCode) {
    $wshell.Popup("Encountered an error while logging in. Check your AWS profile credentials and configuration (located in %UserProfile%\.aws)",0,"Authentication Failure",0x0)
    Write-Error "Encountered an error while logging in. Check your AWS profile credentials and configuration (located in %UserProfile%\.aws)"
    Exit 1
}
else {
    Write-Host "Hello, you're logged in as $selfARN"
    Write-Host
}

# Prompt the user to select an EC2 instance by its Name tag
$instanceList = (aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0]]' --output text).split("`n")
$selectedInstance = $instanceList | Out-GridView -Title "Select an EC2 instance" -PassThru

$instanceID = aws ec2 describe-instances --filter "Name=tag:Name,Values=$selectedInstance" --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" --output text

Write-Host "Instance ID: $instanceID"
Write-Host
Write-Host "Script will attempt to open a Session Manager tunnel with the remote instance. This will forward port 22 on the remote instance to port 2222 on your local environment."
Write-Host "Once the connection is established, connect to port 2222 on your localhost using any SSH or SFTP client."
Write-Host "Note that for SSH connections, you will likely need to disable strict host checking. Putty will pop up with a warning, while the OpenSSH client will need '-o StrictHostKeyChecking=no' in its arguments."
Write-Host
Write-Host "Terminate connection using Ctrl-C or by closing this window."
Write-Host

# Forward port 22 on the selected EC2 instance to port 2222 on the local host
aws ssm start-session --target $instanceID --document-name AWS-StartPortForwardingSession --parameters "localPortNumber=2222,portNumber=22"
