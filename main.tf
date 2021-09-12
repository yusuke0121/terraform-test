# vpc作成
resource "aws_vpc" "tfvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tfvpc"  
  }  
}

# IGW
resource "aws_internet_gateway" "tfigw" {
  vpc_id = aws_vpc.tfvpc.id

  tags = {
    Name = "tfigw"
  }
}

resource "aws_subnet" "tfsubnet" {
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = aws_vpc.tfvpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "tfsubnet"
  }
}

resource "aws_route_table" "tfroutetable" {
  vpc_id = aws_vpc.tfvpc.id

  tags = {
    Name = "tfroutetable"
  }
}

resource "aws_route" "tfroute" {
  route_table_id         = aws_route_table.tfroutetable.id
  gateway_id             = aws_internet_gateway.tfigw.id
  destination_cidr_block = "0.0.0.0/0"  
}

resource "aws_route_table_association" "tfassociation" {
  subnet_id      = aws_subnet.tfsubnet.id
  route_table_id = aws_route_table.tfroutetable.id
}

resource "aws_security_group" "tfsg" {
   vpc_id = aws_vpc.tfvpc.id
   
   tags = {
     Name = "tfsg"
   }
}

resource "aws_security_group_rule" "tfrule22" {
  security_group_id = aws_security_group.tfsg.id 
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tfrule80" {
  security_group_id = aws_security_group.tfsg.id     
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"] 
}

resource "aws_key_pair" "example1" {
  key_name = "example1"
  public_key = file("~/example1.pub")
}

resource "aws_instance" "tfinstance" {
  ami                         = "ami-00d101850e971728d"
  vpc_security_group_ids      = [aws_security_group.tfsg.id]
  subnet_id                   = aws_subnet.tfsubnet.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.example1.id

  tags = {
    Name = "tfinstance"
  }
}
