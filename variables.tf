# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
    type = string 
    default = "ami-0c481170e71fe35c5"
}

variable "key_pair" {
    type = string 
    default = "DEVOPS01-2108"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "What to name the Vault server cluster and all of its associated resources"
  type        = string
  default     = "vault-dynamo-svr"
}

variable "cluster_size" {
  description = "The number of Vault server nodes to deploy. We strongly recommend using 3 or 5."
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "The type of EC2 Instance to run in the Vault ASG"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = "vpc-0c6c0a488ab519e12"
}

variable "dynamo_table_name" {
  description = "The name of the Dynamo Table to create and use as a storage backend. Only used if 'enable_dynamo_backend' is set to true."
  default     = "VAULT_BACKEND_STORAGE"
}

variable "user_data" {
    type    = string
    default = "<<-EOF \n #!/bin/bash \n /opt/vault/bin/run-vault --tls-cert-file /opt/vault/tls/vault.crt.pem --tls-key-file /opt/vault/tls/vault.key.pem \n EOF"
}

variable "nlb_name" {
    default = "VAULT-LOAD-BALANCER"
  
}
variable "subnet_ids" {
    description = "The subnets for load balancer"
    default     = ["subnet-01a79e54dd1a0064c", "subnet-0927958e96802d4df"]
  
}

variable "internal" {
  description   = "Set load balancer to be internal or external"
  default       = false

}