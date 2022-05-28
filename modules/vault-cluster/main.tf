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


// DEPLOY A LAUNCH TEMPLATE for Auto Scaling Group

resource "aws_launch_template" "vault_lt" {
  name_prefix             = "${var.cluster_name}-LT"

  image_id                = var.ami_id
  instance_type           = var.instance_type
  key_name                = var.key_pair
  iam_instance_profile {
      arn = aws_iam_instance_profile.instance_profile.arn
  }
  #user_data = "${base64encode(data.template_file.test.rendered)}"

  vpc_security_group_ids = [aws_security_group.vault_lt_sg.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = var.delete_on_termination
      encrypted             = var.encrypted
    }
  }
  
  tag_specifications {
    resource_type = "instance"
      tags = {
      Name = var.cluster_name
    }
  }
}
// DEPLOY A AUTO SCALING GROUP
resource "aws_autoscaling_group" "vault_asg" {
    name    = "${var.cluster_name}-ASG"
    launch_template {
    id      = aws_launch_template.vault_lt.id
    version = "$Latest"
  }

    vpc_zone_identifier     = var.pri_subnets

    // Set Cluster size to a fixed-size
    min_size                = var.cluster_size
    max_size                = var.cluster_size
    desired_capacity        = var.cluster_size
    termination_policies    = [var.termination_policies]

    health_check_type           = var.health_check_type
    health_check_grace_period   = var.health_check_grace_period
    wait_for_capacity_timeout    = var.health_check_timeout

    #enabled_metrics = var.enabled_metrics

    tag {
        
       key               = "rea-system-id"
       value             = var.cluster_name
       propagate_at_launch = true 
    }

    lifecycle {
        create_before_destroy = true
    }
}

// CREATE A SECURITY GROUP FOR LAUNCH TEMPLATE

resource "aws_security_group" "vault_lt_sg" {
  name        = "${var.cluster_name}-SG"
  description = "Security to control network traffic to Vault Instances"
  vpc_id      = var.vpc_id

  lifecycle {create_before_destroy = true}
  tags = {
    "Name"          = "${var.cluster_name}-SG"
    "rea-system-id" = var.cluster_name
  }

}

// Define INBOUND RULE to the above Security Group
resource "aws_security_group_rule" "ssh_inbound"{
  security_group_id = aws_security_group.vault_lt_sg.id
  type              = "ingress"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_inbound" {
  security_group_id = aws_security_group.vault_lt_sg.id
  type              = "ingress"
  from_port         = var.vault_api
  to_port           = var.vault_api
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "vault_api" {
  security_group_id = aws_security_group.vault_lt_sg.id
  type              = "ingress"
  from_port         = var.vault_request
  to_port           = var.vault_request
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_healthcheck" {
  security_group_id = aws_security_group.vault_lt_sg.id
  type              = "ingress"
  from_port         = var.lb_healthcheck
  to_port           = var.lb_healthcheck
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}

// DEPLOY AN EC2 IAM ROLE and IAM POLICY

resource "aws_iam_role" "instance_role" {
  name                = "VAULT-SVR-IAM-ROLE"
  description         = "IAM role to attach to vault instances"
  assume_role_policy  = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name          = "VAULT-SVR-PROFILE"
  path          = var.instance_profile_path
  role          = aws_iam_role.instance_role.name

  lifecycle {create_before_destroy = true}
}
 
// CREATE A KMS KEY TO UNSEAL VAULT

resource "aws_kms_key" "unseal_key"{
  description       = "This is used for auto unseal vault"
  is_enabled     = true 

  tags = {
    "Name" = "VAULT-CLUSTER"
  }
}

resource "aws_kms_alias" "kms_key" {
  name          = "alias/VAULT_KEY"
  target_key_id = aws_kms_key.unseal_key.id
}
// CREATE AND ATTACH THE POLICY TO THE IAM ROLE

data  "aws_iam_policy_document" "role_policy" {
    statement {
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
      }
}

resource "aws_iam_role_policy" "vault_iam_policy"{
  name = "VAULT-IAM-POLICY"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "iam:GetRole"
            ],
            "Resource": "arn:aws:iam::*:role/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "arn:aws:iam::*:role/VaultAccessRole",
            "Effect": "Allow"
        },
        {
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:DescribeReservedCapacityOfferings",
                "dynamodb:DescribeTable",
                "dynamodb:DescribeTimeToLive",
                "dynamodb:GetItem",
                "dynamodb:GetRecords",
                "dynamodb:ListTables",
                "dynamodb:ListTagsOfResource",
                "dynamodb:PutItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:ap-southeast-2:${data.aws_caller_identity.current.account_id}:table/${var.dynamo_table_name}",
            "Effect": "Allow"
        },
        {
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": "arn:aws:kms:ap-southeast-2:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.unseal_key.id}",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticloadbalancing:DescribeTargetHealth"],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticloadbalancing:DescribeInstanceHealth"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "elasticloadbalancing:DescribeInstanceHealth",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "elasticloadbalancing:DescribeTargetHealth",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:SetInstanceHealth"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "kms:Decrypt",
            "Resource": [
                "arn:aws:kms:ap-southeast-2:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.unseal_key.id}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeTags"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]

  })
}