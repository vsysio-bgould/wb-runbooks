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
