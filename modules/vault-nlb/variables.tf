# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "name" {
 description = "The name to use for the NLB and all other resources in this module."
}
variable "vault_asg_name" {
   description = "Name of the Vault Autoscaling Group"
   default     = ""
}

variable "internal" {
  description = "Set load balancer to be internal or external"

}

variable "load_balancer_type" {
  description = "Application or Network Load balancer"
  default     = "application"
}

variable "cross_zone_load_balancing" {
  description   = "Enable load balancing"
  default       = true
}

variable "idle_timeout" {
  description   = "Time in seconds that the connection is allowed to be idle"
  default       = "60"
}

variable "subnets" {
    description = "The subnets for load balancer"
    default     = ["subnet-01a79e54dd1a0064c", "subnet-0927958e96802d4df"]
  
}

variable "vpc_id" {
    description  = "Your VPC ID"
    default         = "vpc-0c6c0a488ab519e12"
  
}

variable "zone_id" {
    description = "The hosted zone vault should be in"
    default = "Z08027841ZVT9N3G9DFFK"
}

variable "domain_name" {
    description = "Vault Domain Name"
    default     = "vault.solzarc.co"
  
}

variable "asg_name" {
}