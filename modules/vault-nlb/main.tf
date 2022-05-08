# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT SERVER CLUSTER, AN ELB AND DYNAMODB BACKEND
# This is an example of how to use the vault-cluster and vault-elb modules to deploy a Vault cluster in AWS with an
# Elastic Load Balancer (ELB) in front of it. 
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "ap-southeast-2"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

// CREATE A NETWORK LOAD BALANCER for VAULT

resource "aws_lb" "vault_alb" {
    name = var.name 
    
    internal                            = var.internal                          // This would be internal or external ELB
    load_balancer_type                  = var.load_balancer_type
    idle_timeout                        = 60                     // Default 60 - Time in seconds that the connection is allowed to be idle
    
    subnets                             = var.subnets
    tags = {
        "Name" = "VAULT-LOADBALANCER-TST" }
}
# Create a load balancer target group

resource "aws_lb_target_group" "vault_tg" {
    name        = "vault-lb-tg"
    port        = 8080
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = var.vpc_id
    
    depends_on = [aws_lb.vault_alb]

  health_check {
    path = "/v1/sys/health?standbyok=true"
    port = 8080
    healthy_threshold = 6
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
  tags = {
    Environment = "test"
  }

  lifecycle {create_before_destroy = true}
}


resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn   = aws_lb.vault_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:ap-southeast-2:585781887322:certificate/2d78d1df-0d81-478a-ab98-18cdd6ee9f06"


  default_action {
    type              = "forward"
    target_group_arn  = "${aws_lb_target_group.vault_tg.arn}"
  }
}
resource "aws_autoscaling_attachment" "alb_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.vault_tg.arn}"
  autoscaling_group_name = var.asg_name
}
# ---------------------------------------------------------------------------------------------------------------------
# ATTACH THE ELB TO THE VAULT ASG
# ---------------------------------------------------------------------------------------------------------------------

# resource "aws_autoscaling_attachment" "vault_asg" {
#     autoscaling_group_name  = var.vault_asg_name
#     elb                     = aws_lb.vault_nlb.id
# }

// CREATE ROUTE 53 to ELB

resource "aws_route53_record" "elb_dns" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name    = aws_lb.vault_alb.dns_name
    zone_id = aws_lb.vault_alb.zone_id

    evaluate_target_health = false
  }
}