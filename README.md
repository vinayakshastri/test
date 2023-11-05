AWS Elastic Beanstalk Terraform Configuration
This Terraform configuration sets up the necessary infrastructure to deploy an application on AWS Elastic Beanstalk.

Overview
The main.tf file contains the configuration to:

AWS Provider: Specifies the AWS region (ap-southeast-2) to deploy resources.

S3 Bucket and Object:

Uploads a ZIP file (app.zip) containing the application code to an existing S3 bucket (tf-source-code) with the key app.
Elastic Beanstalk Application:

Creates an Elastic Beanstalk application named test-app with a description.
Defines an application version by referencing the ZIP file uploaded to S3.
IAM Roles:

Sets up an IAM role (eb-instance-role) and associates it with the Elastic Beanstalk environment.
Attaches the AWSElasticBeanstalkWebTier policy to the role.
VPC, Subnets, and Internet Gateway:

Creates a VPC with CIDR 10.0.0.0/16 and an associated internet gateway.
Creates 2 subnets in available availability zones with public IP association enabled.
Sets up a route table to route traffic from the subnets to the internet gateway.
Elastic Beanstalk Environment:

Creates an Elastic Beanstalk environment named test-app-env using the defined application and application version.
Configures settings such as EnvironmentType, IamInstanceProfile, VPCId, and Subnets.
Uses the solution stack 64bit Amazon Linux 2023 v4.1.0 running Docker.
Prerequisites
Ensure that app.zip, containing your application code, is located in the same directory as the Terraform configuration.
The S3 bucket tf-source-code should already exist.
AWS credentials must be configured to allow Terraform to create resources.