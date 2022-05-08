output "alb_name" {
  value = aws_lb.vault_alb.id
}

output "target_group_arn" {
    value = aws_lb_target_group.vault_tg.arn
}