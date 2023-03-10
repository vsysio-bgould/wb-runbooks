# FirewallPunch script

This script manages a security group called **TemporaryAdminAccess**. Running this script will open port 5432 (Postgres) on this security group, making it possible for personnel to connect to the AWS RDS database instance directly over the public Internet. 

## Prerequisite - AWS CLI

This script requires the installation of the AWS CLI utility. The script will prompt for its installation if this utility is not detected.

[AWS Documentation - AWS CLI installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Prerequisite - AWS CLI Configuration

This script requires the configuration of the AWS CLI utility. The script will automatically abort if the CLI is not configured.

1. Collect youe AWS Access Key ID and AWS Secret Access Key from a system administrator.  An access key looks like `AKIA3SVP2WGGSDSXV5G` while a secret access key looks like `iSUbLUOWDAFGadfghDFGFovv2qlE6vOZ5Uo` 
2. Run `aws configure` in either a Bash or PowerShell terminal.
3. Follow the prompts.

Under the hood, the AWS CLI **writes** these credentials to a file located at `%UserProfile%\.aws\credentials`. Ensure that this directory is protected!

### Contractor using multiple AWS accounts?

If you already have the CLI configured for another AWS account (ie. Different client), you can specify a profile by populating the `profile` parameter when running `aws configure`. 

For example, running the following sets up a separate profile named *wavve*:

`aws configure --profile=wavve`

The script will prompt you for which profile to use.