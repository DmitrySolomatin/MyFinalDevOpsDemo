# outputs.tf

output "lb_hostname" {
  value = aws_lb.main.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = aws_subnet.private.*.id
}
