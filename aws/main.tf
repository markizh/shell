# 引用变量
# 创建aws云基础设施 https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = var.region
}

# 创建aws ec2实例
resource "aws_instance" "api" {
  # lookup通过查询定义的变量获取值
  ami = lookup(var.ami, var.region)
  instance_type = var.instance_type
  key_name = aws_key_pair.ssh.key_name
  // EC2实例创建后运行定义脚本
  #user_data = "docker.sh"
  tags = {
    Name  = "api"
  }
}

# 添加ssh公钥
resource "aws_key_pair" "ssh" {
    key_name = "ap-southeast-1-key1"
    // file读取文件以字符串方式返回文件内容
    public_key = file(var.public_key)
}

# 通过data数据源获取信息
data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# 开放安全组规则
resource "aws_security_group_rule" "ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["103.48.141.80/32"]
    # 引用数据源中的变量值
    security_group_id = data.aws_security_group.default.id
}