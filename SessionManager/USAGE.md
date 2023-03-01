# AWS System Session Manager - Usage

## Note!

At a minimum, users needing Session Manager access will need the [AmazonSSMFullAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/AmazonSSMFullAccess$jsonEditor) AND [AmazonEC2ReadOnlyAccess](https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess$serviceLevelSummary) policies attached to their IAM user.

There are two options available to use the AWS System Session Manager to connect to an instance.

## AWS CLI

If you wish to connect to an EC2 instance using a native SSH client, you **must** first install and configure the AWS CLI utility **and** the AWS System Session Manager plugin.

[AWS Documentation - AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
[AWS Documentation - Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows)

If you haven't yet configured the AWS CLI, you can run the following command:

`aws configure`

Have your AWS programmatic access keys available. [Generate access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)

## AWS Web Console

You can connect to a registered instance directly through the AWS Web Console.

1. Browse to EC2.
2. Select the instance you wish to connect to.
3. Click `Connect` at the top-right.
4. Select `Session Manager` tab.
5. Click Connect. 

## Helper Script

A helper script has been written that facilitates the easy setup of tunnels over AWS Session Manager.

**Note that SSH clients are likely to present you with a warning about host key verification. It is safe to disregard this warning (in THIS circumstance only... if you see that warning 'in the wild,' be wary!).**

PuTTY presents a warning on connect, while the OpenSSH CLI client will need `-o StrictHostKeyChecking=no` in its arguments.

### Windows

For Windows, use `port-forward.ps1`. Execute it by opening PowerShell in a terminal, changing to this directory, then entering:

`.\port-forward.ps1`

**Windows may present you with a warning about trusting scripts from the Internet.** It is safe to override the warning in this case (press **R** on your keyboard)

The script allows you to select an AWS credentials profile. It then provides a list of available EC2 instances, allowing you to select one.

Once a selection is made, the script will attempt to forward port 22 on the remote EC2 instance to your localhost at port 2222.

The tunnel will remain open until the terminal is closed.

### OSX/Linux

For OSX/Linux, use `port-forward.sh`. Execute it by opening a terminal, changing to this directory, then running:

`./port-forward.sh`

The script allows you to select an EC2 instance from a list. 

Once a selection is made, the script will attempt to forward port 22 on the remote EC2 instance to your localhost at port 2222.

The tunnel will remain open until the terminal is closed.