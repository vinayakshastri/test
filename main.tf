# main.tf
provider "aws" {
  region = "ap-southeast-2"
}

# Create an S3 bucket for storing the application code
resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-testapp-bucket"
}

# Zip and upload the application code to the S3 bucket
resource "aws_s3_bucket_object" "app_object" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key    = "my-app.zip"
  source = "${path.module}/app.zip"  # Local path to your application ZIP file
}

# Create an application version
resource "aws_elastic_beanstalk_application_version" "my_app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.this.name

  # Point to the S3 location of the application code
  source_bundle {
    bucket = aws_s3_bucket.app_bucket.bucket
    key    = aws_s3_bucket_object.app_object.key
  }
}

resource "aws_elastic_beanstalk_application" "this" {
  name        = "test-app"
  description = "A sample Elastic Beanstalk application"
}

resource "aws_iam_role" "eb_instance_role" {
  name = "eb-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Create a VPC
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eb-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# Create Subnets
resource "aws_subnet" "this" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  map_public_ip_on_launch = true  # Instances launched into this subnet should have a public IP
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "eb-subnet-${count.index + 1}"
  }
}

# Create a Route Table
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# Associate the Route Table with the Subnets
resource "aws_route_table_association" "this" {
  count          = 2
  subnet_id      = element(aws_subnet.this.*.id, count.index)
  route_table_id = aws_route_table.this.id
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.eb_instance_role.name
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "eb-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

resource "aws_elastic_beanstalk_environment" "this" {
  name        = "test-app-env"
  application = aws_elastic_beanstalk_application.this.name
  version_label       = aws_elastic_beanstalk_application_version.my_app_version.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.1.0 running Docker"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.this.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.this.*.id)
  }
}
