# Deprovisioning Checklist

This runbook describes a deprovisioning checklist to use when removing administrative operations users from the system.

# Checklist

| Location                                                                                                                                       | Purpose                                              | Comment(s)                                         |
|------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------|----------------------------------------------------|
| [Django Admin - Production](https://backend.wavve.ca/wavvemanager/)                                                                            |                                                      | Fallback - user also recorded in `auth_user` table |
| [Django Admin - Staging]()                                                                                                                     |                                                      | Fallback - user also recorded in `auth_user` table |
| [AWS IAM Console](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-2#/users)                                                 | SSM, SSH, `TemporaryAdminAccess` security group      |                                                    |
| SSH Keys                                                                                                                                       |                                                      |                                                    |
| Database users                                                                                                                                 |                                                      |                                                    |
| [TemporaryAdminAccess security group](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#SecurityGroup:groupId=sg-04bd3b8033ec73664) | Controls stateful firewall ports for database access | Description field contains IAM user name           |
| GitHub user                                                                                                                                    |                                                      |                                                    |
| Google Directory                                                                                                                               |                                                      |                                                    |
