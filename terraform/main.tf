provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["day2-vpc"]
  }
}

data "aws_subnet" "existing_public" {
  filter {
    name   = "tag:Name"
    values = ["day2-public-subnet"]
  }
}

resource "aws_subnet" "eks_secondary" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block               = "10.0.2.0/24"
  availability_zone        = "us-east-1b"
  map_public_ip_on_launch  = true

  tags = {
    Name = "devops-journey-eks-subnet-b"
  }
}
data "aws_route_table" "existing_public_rt" {
  filter {
    name   = "tag:Name"
    values = ["day2-public-rt"]
  }
}

resource "aws_route_table_association" "eks_secondary_assoc" {
  subnet_id      = aws_subnet.eks_secondary.id
  route_table_id = data.aws_route_table.existing_public_rt.id
}
