# main.tf
provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_elastic_beanstalk_application" "this" {
  name        = "sample-app"
  description = "A sample Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_environment" "this" {
  name        = "sample-app-env"
  application = aws_elastic_beanstalk_application.this.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.1.0 running Docker"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
}
