variable "instance_type" {}

#　vpc作成
resource "aws_vpc" "tfvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tfvpc"  
  }  
}

#　IGW
resource "aws_internet_gateway" "tfigw" {
  vpc_id = aws_vpc.tfvpc.id

  tags = {
    Name = "tfigw"
  }
}

#　サブネット作成
resource "aws_subnet" "tfsubnet" {
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = aws_vpc.tfvpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "tfsubnet"
  }
}

#　ルートテーブル
resource "aws_route_table" "tfroutetable" {
  vpc_id = aws_vpc.tfvpc.id

  tags = {
    Name = "tfroutetable"
  }
}

#　ルート
resource "aws_route" "tfroute" {
  route_table_id         = aws_route_table.tfroutetable.id
  gateway_id             = aws_internet_gateway.tfigw.id
  destination_cidr_block = "0.0.0.0/0"  
}

#　IGWへアタッチ
resource "aws_route_table_association" "tfassociation" {
  subnet_id      = aws_subnet.tfsubnet.id
  route_table_id = aws_route_table.tfroutetable.id
}

#　セキュリティグループ
resource "aws_security_group" "tfsg" {
   vpc_id = aws_vpc.tfvpc.id
   
   tags = {
     Name = "tfsg"
   }
}

#　インバウンド22
resource "aws_security_group_rule" "tfrule22" {
  security_group_id = aws_security_group.tfsg.id 
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

#　インバウンド80
resource "aws_security_group_rule" "tfrule80" {
  security_group_id = aws_security_group.tfsg.id     
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"] 
}

# アウトバウンド開放
resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.tfsg.id
  protocol          = "-1" 
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
# keypair
resource "aws_key_pair" "example1" {
  key_name = "example1"
  public_key = file("~/.ssh/example1.pub")
}

# EC2インスタンス
resource "aws_instance" "tfinstance" {
  ami                         = "ami-00d101850e971728d"
  vpc_security_group_ids      = [aws_security_group.tfsg.id]
  subnet_id                   = aws_subnet.tfsubnet.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.example1.id
  user_data                   = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
  EOF  

  tags = {
    Name = "tfinstance"
  }
}


output "public_dns" {
  value = aws_instance.tfinstance.public_dns
  
}
