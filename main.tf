#----------------------------------------------------------------------------------------
# DEPLOY VAULT CLUSTER WITH AN ELB, AUTOSCALING GROUP AND DYNAMO BACKEND
#----------------------------------------------------------------------------------------
provider "aws" {
  region = "ap-southeast-2"

}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
// Save the terraform state in an S3 bucket
# terraform backend "s3" {

# }

// CREATE A DYNAMODB TABLE FOR VAULT STORAGE
module "dynamodb" {
  source         = "./modules/backend"
  table_name     = var.dynamo_table_name
}

// CREATE A VAULT CLUSTER

module "vault_cluster" {
    source = "./modules/vault-cluster"

    cluster_name    = var.cluster_name
    cluster_size    = var.cluster_size
    instance_type   = var.instance_type

    ami_id          = var.ami_id
    vpc_id          = var.vpc_id
    user_data       = var.user_data 

    allowed_inbound_cidr_blocks = ["0.0.0.0/0"]

}

// CREATE A NETWORK LOAD BALANCER

module "vault_lb" {
    source = "./modules/vault-nlb"

    name        = var.nlb_name
    internal    = var.internal 
    vpc_id      = var.vpc_id
    subnets     = var.subnet_ids

    # Associate the ELB with the instances created by the Vault Autoscaling group
    asg_name = module.vault_cluster.asg_name
}



