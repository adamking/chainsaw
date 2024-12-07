# Default provider configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.chain_name
      ManagedBy   = "terraform"
      Repository  = "chainsaw"
      CreatedAt   = timestamp()
    }
  }
}

# Secondary region provider for disaster recovery
provider "aws" {
  alias   = "dr"
  region  = var.dr_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.chain_name
      ManagedBy   = "terraform"
      Repository  = "chainsaw"
      CreatedAt   = timestamp()
    }
  }
}

provider "random" {
  # No specific configuration needed
}

provider "cloudinit" {
  # No specific configuration needed
}
