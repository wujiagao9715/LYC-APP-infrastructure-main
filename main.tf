terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
  }

  backend "s3" {
    bucket = "wujg-app-bucket-0616" //需要提前创建
    key    = "pipeline-terraform-statusfile/terraform.tfstate"
    region = "ap-southeast-2"
  }

}

# provider "aws" {
#   # region = "ap-southeast-2"
#   # access_key = "access_key"
#   # secret_key = "secret_key"
# }

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id
  ingress {
    description = "http access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2 security group"
  }
}

resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}

resource "aws_instance" "linux_instance" {
  ami                  = "ami-00543daa0ad4d3ea4"
  instance_type        = "t2.micro"
  key_name             = "WUJG-APP" //需要提前创建 创建EC2实例->创建密钥对

 # 指定安全组
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  iam_instance_profile = "EC2CodeDeploy"
  tags = {
    Name = "WUJG-APP"
  }
  user_data = <<-EOF
                #!/bin/bash
                
                #更新系统
                yum update -y

                #安装Nginx
                yum install nginx -y

                #启动Nginx
                systemctl start nginx

                #设置Nginx为开机自启
                systemctl enable nginx

                #安装codedepLoy-agent
                sudo yum -y update
                sudo yum -y install ruby
                sudo yum -y install wget
                cd /home/ec2-user
                wget https://aws-codedeploy-ap-southeast-2.s3.ap-southeast-2.amazonaws.com/latest/install
                sudo chmod +x ./install
                sudo ./install auto
                systemctl status codedeploy-agent
                #使用CodeDepLoy服务需要在EC2中安装agent,具体代码解释，请参考
                #https://docs.aws.amazon.com/zh_cn/codedeploy/latest/userguide/codedeploy-agent-operations-install-linux.html
                EOF
}

#输出EC2实例的公网IPV4地址
output "ec2_public_ipv4_url" {
  value = join("", ["http://", aws_instance.linux_instance.public_ip, ":80"])
}
