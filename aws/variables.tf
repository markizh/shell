# 声明变量
variable "region" {
  type = string
  default = "ap-southeast-1"
  description = "AWS region"
}

variable "ami" {
  type = map
  default = {
    # amazon linux 2
    ap-southeast-1 = "ami-0bd6906508e74f692"
  }
  description = "AMI ID"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "EC2 instance type"
}

variable "public_key" {
  type = string
  default = "/root/.ssh/ap-southeast-1-key1.pub"
  description = "SSH public key"
}

#variable "security_group" {
#  type = string
#  description = "security group ID"
#}

/* 当定义的变量没有设置默认值事，执行terraform plan 或者 terraform apply会提示输入值
  terraform变量值输入方法：
  1. -var参数传递变量值
  terraform plan -var security_group=sg-f22d4181

  2. 创建.tfvars结尾文件，将 "security_group=sg-f22d4181" 添加到文件后，直接执行terrafom plan

  3. -var-file 指定存放变量的文件
  terraform plan -var-file vars.txt

  4. 通过环境变量进行指定
  export TF_VAR_security_group=sg-f22d4181
*/