############## FUNCTIONS
### MEAT AND POTATOES IN NEXT SECTION

function ConvertTo-HashtableFromPsCustomObject {
    param (
        [Parameter(
                Position = 0,
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
        )] [object] $psCustomObject
    );
    Write-Verbose "[Start]:: ConvertTo-HashtableFromPsCustomObject"

    $output = @{};
    $psCustomObject | Get-Member -MemberType *Property | % {
        $output.($_.name) = $psCustomObject.($_.name);
    }

    Write-Verbose "[Exit]:: ConvertTo-HashtableFromPsCustomObject"

    return  $output;
}

function HandleError {
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )] [string] $string,
        [string[]]$Exit = 1
    )

    Write-Host "ERROR: $string" -ForegroundColor red
    $wshell.Popup("$string",0,"Error",0x0)

    if ($Exit) {
        Exit 0
    }
}

Function Pause ($message)
{
    Write-Host
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

############## MEAT AND POTATOES (yum...)

$wshell = New-Object -ComObject Wscript.Shell

Clear-Host
Write-Host "FirewallPunch script - Managed by Brandon Gould"
Write-Host "-----------------------------------------------"
Write-Host
Write-Host "This script automates the work of modifying rules in the TemporaryAdminAccess EC2 security group."
Write-Host "When run, this script determines the persons' public IPv4 address, and then attempts to add it to the security group."
Write-Host "If the rule already exists, the script will replace it."
Write-Host "The description for the line item in the security group will match the users' IAM Username."
Write-Host
Write-Host

##################### LOGIN TO AWS #####################

# Check if the AWS CLI is installed
if (!(Get-Command "aws" -ErrorAction SilentlyContinue)) {
    HandleError "AWS CLI is missing. Please install from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
}

# Check if aws cli is configured
if (!(Test-Path -Path "$env:USERPROFILE\.aws\credentials")) {
    HandleError "AWS CLI credentials file not detected. Did you run `aws configure` in a terminal?"
}

if (-not $env:AWS_PROFILE) {
    # Prompt the user to select an AWS CLI profile
    $prompted = 1

    Write-Host "(prompt) AWS Profile: " -NoNewline -ForegroundColor blue

    $profileList = (aws configure list-profiles --output text).split("`n")
    $selectedProfile = $profileList | Out-GridView -Title "Select an AWS CLI profile" -PassThru

    $env:AWS_PROFILE = $selectedProfile

    Write-Host "$env:AWS_PROFILE"
}
else {
    Write-Host "(env) AWS_PROFILE: " -NoNewline -ForegroundColor blue
    Write-Host $env:AWS_PROFILE
}

if (-not $env:AWS_REGION) {
    # Prompt the user to select an AWS region
    $prompted = 1

    Write-Host "(prompt) AWS Region: " -NoNewline -ForegroundColor blue

    $regionList = (aws ec2 describe-regions --query 'Regions[*].RegionName' --output text).split("`t")
    $selectedRegion = $regionList | Out-GridView -Title "Select an AWS region" -PassThru

    $env:AWS_REGION = $selectedRegion

    Write-Host "$env:AWS_REGION"
}
else {
    Write-Host "(env) AWS_REGION: " -NoNewline -ForegroundColor blue
    Write-Host $env:AWS_REGION
}

$sts = aws sts get-caller-identity | ConvertFrom-Json | ConvertTo-HashtableFromPsCustomObject
$sts['User'] = (Select-String "(.*):user\/(.*)" -inputobject $sts.Arn).matches.groups[2].value

if ($lastExitCode) {
    HandleError "Encountered an error while logging in. Check your AWS profile credentials and configuration (located in %UserProfile%\.aws)"
    Exit 1
}
else {
    Write-Host "(sts) AWS Account: " -NoNewline -ForegroundColor blue
    Write-Host $sts.Account
    Write-Host "(sts) AWS IAM UserID: " -NoNewline -ForegroundColor blue
    Write-Host $sts.UserId
    Write-Host "(sts) AWS IAM User ARN: " -NoNewline -ForegroundColor blue
    Write-Host $sts.Arn
    Write-Host "(sts) AWS IAM User Name: " -NoNewline -ForegroundColor blue
    Write-Host $sts.User
}

##################### DETERMINE PUBLIC IPv4 ADDRESS #####################

Write-Host "(autodetect) IPv4 address: " -NoNewline -ForegroundColor blue

$IPAddress = ((Invoke-WebRequest -URI "http://whatismyip.akamai.com" -UserAgent "curl/7.54").Content).TrimEnd("`r?`n")

Write-Host $IPAddress

##################### SECURITY GROUP STUFF #####################

# Security group exists?

Write-Host "(sg) Security group name: " -NoNewline -ForegroundColor blue

$sg = aws ec2 describe-security-groups --group-names "TemporaryAdminAccess" --query "SecurityGroups[0]" | ConvertFrom-Json

if ($lastExitCode) {
    HandleError "An error occurred while checking if the TemporaryAdminAccess security group exists. This script will not automatically create the security group. Did you select the correct region?"
}

Write-Host $sg.GroupName

Write-Host "(sg) Security Group ID: " -NoNewline -ForegroundColor Blue
Write-Host $sg.GroupId

$groupId = $sg.GroupId

# Existing rule?

Write-Host "(sg) Ingress rules: " -ForegroundColor blue

$rules = (aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$groupId" --query "SecurityGroupRules[*]") | ConvertFrom-Json
$myRule = $IPAddress+"/32"
$update = @{}
$object = @{}
$found = 0  # Increment value if rule with a description matching our IAM User Name is found
            # If value remains 0, create new rule!

$Counter = 1
$rules | ForEach-Object {
    Write-Host "(sg) [$Counter] Desc:$($_.Description) IPv4:$($_.CidrIpv4) " -ForegroundColor DarkGreen -NoNewline

    # Appropriate rule exists; no change needed!
    if ($($_.Description) -eq $sts.User -And $($_.CidrIpv4) -eq $myRule) {
        Write-Host "D:NoChange" -ForegroundColor DarkGreen
        $found++
    }
    # Rule exists, however, has wrong IP, so we update it here
    elseif ($($_.Description) -eq $sts.User -And $($_.CidrIpv4) -ne $myRule) {
        if ($found -ge 1) {
            Write-Host "D:Ignore" -ForegroundColor DarkGreen
            $found++
        }
        else
        {
            Write-Host  "D:UpdateIP" -ForegroundColor DarkGreen
            $object = $($_) | ConvertTo-HashtableFromPsCustomObject
            $object['CidrIpv4'] = $myRule
            $template = @{}

            $template['SecurityGroupRuleId'] = $object['SecurityGroupRuleId']
            $template['SecurityGroupRule'] = @{}
            $template.SecurityGroupRule.Add('IpProtocol', $object['IpProtocol'])
            $template.SecurityGroupRule.Add('FromPort', $object['FromPort'])
            $template.SecurityGroupRule.Add('ToPort', $object['ToPort'])
            $template.SecurityGroupRule.Add('CidrIpv4', $myRule)
            $template.SecurityGroupRule.Add('Description', $object['Description'])
            $template.SecurityGroupRule.Add('CidrIpv6', '')
            $template.SecurityGroupRule.Add('PrefixListId', '')
            $template.SecurityGroupRule.Add('ReferencedGroupId', '')

            $update += $template
            $found++

        }
    }
    $Counter++
}
Write-Host
$json = (ConvertTo-Json -Depth 5 -InputObject $update -Compress).Replace('"','\"')

# Rules matching incorrect IP updates are buffered, so we run the buffered updates!
if ($found -gt 1) { #
    Write-Host
    Write-Host "Multiple rules found! Aborted." -BackgroundColor Red -ForegroundColor Black

}
elseif ($update.Count) {
    Write-Host "(sg) Updating rules: " -NoNewline -ForegroundColor Yellow
    $stat = aws ec2 modify-security-group-rules --group-id $sg.GroupId --security-group-rules $json | ConvertFrom-Json
    if ($stat.Return -eq "true") {
        Write-Host "Success!" -BackgroundColor Green
    }
    else {
        Write-Host "Failed!" -BackgroundColor Red
        HandleError "An error occured while trying to update security group rules! No changes have been pushed."
    }
} # No rule with a description matching our IAM User are found, so we must create one!
elseif ($found -eq 0) {
    Write-Host "(sg) Adding rule: " -NoNewline -ForegroundColor Yellow

    $perms = @(
        @{
            FromPort = 5432
            ToPort = 5432
            IpProtocol = "tcp"
            IpRanges = @(
                @{
                    CidrIp = $myRule
                    Description = $sts.User
                }
            )
        }
    )
    $perms = ($perms | ConvertTo-Json).Replace('"','\"')

    $stat = aws ec2 authorize-security-group-ingress --group-id $sg.GroupId --ip-permissions $perms | ConvertFrom-Json

    if ($stat.Return -eq "true") {
        Write-Host "Success!" -BackgroundColor Green
    }
    else {
        Write-Host "Failed!" -BackgroundColor Red
        HandleError "An error occured while trying to update security group rules! No changes have been pushed."
    }

} # We found multiple rules assigned to this user! Shouldn't happen but we mention the fix here just in case
 # We already found a rule that will permit access
else {
    Write-Host
    Write-Host "No update needed!" -BackgroundColor Green
}

##################### DISPLAY HELPFUL HINTS #####################

if ($prompted) {
    Write-Host
    Write-Host "Handy Hint"
    Write-Host "----------"
    Write-Host "You can suppress prompting of profile & region by setting AWS_PROFILE and AWS_REGION environment variables."
    Write-Host "This can be done in the control panel."
    Write-Host
}

if ($found -gt 1) {
    Write-Host
    Write-Host "Intervention needed"
    Write-Host "-------------------"
    Write-Host "Multiple Security group rules assigned to this user are detected."
    Write-Host "To prevent from throwing a weird AWS error, this script will ignore rule changes after finding or applying the first rule change."
    Write-Host "Correcting this is simple - manually delete all rules belonging to this user."
    Write-Host
}

Pause "Press any key to continue..."