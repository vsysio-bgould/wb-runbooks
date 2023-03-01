# AWS System Session Manager

## AWS CLI Session Manager Plugin

If you wish to connect to an EC2 instance using a native SSH client, you must install and configure the AWS CLI utility **and** the AWS System Session Manager plugin on your workstation.

[AWS Documentation - AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)  
[AWS Documentation - Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows)

## Installation Instructions - EC2 Instance

### Ubuntu 18.04 and newer

1. Assign the `ec2role-ssm-barebones` IAM role to the EC2 instance. [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
2. Wait up to 1 hour for the instance to self-register.
3. [Review the Session Manager Console] to verify the instance appears in the list.

Amazon Machine Images ("AMIs") released by Canonical for Ubuntu 18.04 anmd higher already have the SSM agent preinstalled.

### Older than Ubuintu 18.04

1. Assign the `ec2role-ssm-barebones` IAM role to the EC2 instance.[AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
2. Open port 22 by assigning a security group permitting access from your station.
3. Connect to the instance over SSH.
4. Download the SSM agent: `wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb`
5. Install the SSM agent: `sudo dpkg -i amazon-ssm-agent.deb`
6. Verify the agent is running. Check output for Active: `sudo systemctl status amazon-ssm-agent`
7. Wait up to 1 hour for the instance to self-register.
8. [Review the Session Manager Console](https://us-east-2.console.aws.amazon.com/systems-manager/session-manager/start-session?region=us-east-2) to verify the instance appears in the list.
