
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app_alb.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "vpc_id" {
  value = aws_vpc.app_vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app_asg.name
}
