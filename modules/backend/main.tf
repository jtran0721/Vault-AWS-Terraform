# -------------------------------------------------------------------------------------------------------------------------
# This module is used to deploy backend storage for VAULT with DynamoDB.
# -------------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "ap-southeast-2"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# -------------------------------------------------------------------------------------------------------------------------
# DEPLOY A DYNAMODB TABLE
# -------------------------------------------------------------------------------------------------------------------------

resource "aws_dynamodb_table" "vault_db" {
    name            = var.table_name
    billing_mode    = "PAY_PER_REQUEST"         // This will set CAPACITY MODE to ON-DEMAND, if use PROVISIONED you need to specify READ and WRITE CAPACITY
    hash_key        = "Path"
    range_key        = "Key"
    stream_enabled  = false
    
    attribute {
        name = "Path"
        type = "S"
    }
    attribute {
        name = "Key"
        type = "S"
    }
    // The reason we only have 2 attribute here because we define with has_key and range_key. 
    // The other attributes (VALUE) would be created automatically while data write into DynamoDB, you don't need to define them in Terraform at creation time.

    # ttl {
    #     attribute_name = "TimeToExist"
    #     enabled        = false
    # }

    point_in_time_recovery {
        enabled = true
    }
 
    tags = {
        "costcode"          ="456"
        "rea-system-id"     = "SPACE_INFRA_Vault"
        "lob"               = "Technology"
        "Environment"       = "DEV"
        propagate_at_launch = true
    }
}