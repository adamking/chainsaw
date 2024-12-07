terraform {
  # Require Terraform 1.5.0 or higher for improved provider configuration
  required_version = ">= 1.5.0"
  
  # Configure remote backend with enhanced security
  backend "s3" {
    # These values should be provided via backend config file
    key            = "terraform.tfstate"
    encrypt        = true
    # Enable DynamoDB state locking
    dynamodb_table = "terraform-state-lock"
    # Enable server-side encryption
    kms_key_id     = "alias/terraform-bucket-key"
  }

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version              = "~> 5.0"
      configuration_aliases = [aws.dr]  # Allow DR region configuration
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}
