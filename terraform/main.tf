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

resource "aws_security_group" "web" {
  name        = "devops-journey-web-sg"
  description = "Allow SSH and app traffic"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-journey-web-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "devops-journey-key"
  public_key = file("~/.ssh/devops-journey-key.pub")
}

resource "aws_instance" "web" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.existing_public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name                = aws_key_pair.deployer.key_name

  tags = {
    Name = "devops-journey-web-server"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
