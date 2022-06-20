#provider "aws" {
#  region = " ap-southeast-1"
#  access_key = ""
#  secret_key = ""
#}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name="prod_vpc"
  }
}

resource "aws_subnet" "subnet-1a" {
  cidr_block = "10.0.0.0/20"
  vpc_id     = aws_vpc.main.id
  tags = {
    Name="prod_subnet_1a"
  }
}
