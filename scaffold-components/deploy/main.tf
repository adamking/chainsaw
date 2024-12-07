provider "aws" {
  region = "us-west-2" # Make this configurable as needed
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_route53_zone" "default" {
  name            = "${var.env}.${var.dns_zone_parent}"
}

resource "aws_ec2_serial_console_access" "default" {
  enabled = true
}

resource "null_resource" "build_linux_executable" {
  count = var.num_validator_instances > 0 || var.num_seed_instances > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "cd .. && DOCKER_SCAN_SUGGEST=false docker build -f deploy/Dockerfile  --platform=linux/amd64 -o deploy/upload ."
  }

  triggers = {
    code_changed = join(",", [for f in setunion(fileset("..", "**/*.go"), fileset("..", "go.*"), fileset("..", "deploy/Dockerfile")) : filesha256("../${f}")])
  }
}

module "validator" {
  depends_on = [null_resource.build_linux_executable]

  source                    = "./modules/validator"
  env                       = var.env
  project                   = var.project
  ssh_private_key_path      = var.ssh_private_key_path
  tls_certificate_email     = var.tls_certificate_email
  vpc_id                    = aws_vpc.vpc.id
  igw_id                    = aws_internet_gateway.igw.id
  subnet_cidr               = var.validator_subnet_cidr
  ami                       = data.aws_ami.ubuntu.id
  dns_zone_id               = aws_route53_zone.default.zone_id
  dns_zone_name             = aws_route53_zone.default.name
  num_instances             = var.num_validator_instances
  validator_keys_passphrase = var.validator_keys_passphrase
  console_password          = var.console_password
  token_name                = var.token_name
}


module "seed" {
  source                 = "./modules/seed"
  env                    = var.env
  project                = var.project
  ssh_private_key_path   = var.ssh_private_key_path
  tls_certificate_email  = var.tls_certificate_email
  vpc_id                 = aws_vpc.vpc.id
  igw_id                 = aws_internet_gateway.igw.id
  subnet_cidr            = var.seed_subnet_cidr
  validator_ips          = module.validator.ips
  genesis_file_available = module.validator.genesis_file_available
  ami                    = data.aws_ami.ubuntu.id
  dns_zone_id            = aws_route53_zone.default.zone_id
  dns_zone_name          = aws_route53_zone.default.name
  num_instances          = var.num_seed_instances
  console_password       = var.console_password
  token_name             = var.token_name
}

module "explorer" {
  source                = "./modules/explorer"
  env                   = var.env
  project               = var.project
  ssh_private_key_path  = var.ssh_private_key_path
  tls_certificate_email = var.tls_certificate_email
  vpc_id                = aws_vpc.vpc.id
  igw_id                = aws_internet_gateway.igw.id
  subnet_cidr           = var.explorer_subnet_cidr
  ami                   = data.aws_ami.ubuntu.id
  create_explorer       = var.create_explorer
  dns_zone_id           = aws_route53_zone.default.zone_id
  dns_zone_name         = aws_route53_zone.default.name
  console_password      = var.console_password
}

