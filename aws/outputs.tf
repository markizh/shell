# 输出变量
output "DNS" {
  value = aws_instance.api.public_dns
}

output "IP" {
  value = aws_instance.api.public_ip
  # 返回信息比较敏感，可以设置sensitive = true
  sensitive = true
}

output "VPC" {
  value = aws_instance.api.vpc_security_group_ids
}

# 查看输出变量值，执行terraform apply 或者执行 terraform output