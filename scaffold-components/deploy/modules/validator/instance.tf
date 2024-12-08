resource "aws_instance" "validator" {
  count                       = var.num_instances
  ami                         = var.ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.validator.id
  key_name                    = "newchain-key.${var.env}"
  vpc_security_group_ids      = [aws_security_group.validator.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-${count.index}"
  }
}

resource "aws_eip" "validator" {
  count    = var.num_instances
  instance = aws_instance.validator[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-eip-${count.index}"
  }
}

resource "aws_route53_record" "validator_api_a_record" {
  depends_on = [aws_eip.validator]
  count      = var.num_instances

  zone_id = var.dns_zone_id
  name    = "validator-${count.index}-api"
  type    = "A"
  ttl     = 600
  records = [aws_eip.validator[count.index].public_ip]
}

resource "aws_route53_record" "validator_rpc_a_record" {
  depends_on = [aws_eip.validator]
  count      = var.num_instances

  zone_id = var.dns_zone_id
  name    = "validator-${count.index}-rpc"
  type    = "A"
  ttl     = 600
  records = [aws_eip.validator[count.index].public_ip]
}

resource "null_resource" "configure_client" {
  depends_on = [aws_security_group.validator, aws_route53_record.validator_api_a_record, aws_route53_record.validator_rpc_a_record]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "rm -rf upload",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "upload"
    destination = "."
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "modules/validator/upload/"
    destination = "upload"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo configuring validator node...",
      "chmod +x ~/upload/*.sh ~/upload/newchaind",
      "sudo systemctl stop newchain.service || :",
      "~/upload/configure-generic-client.sh '${var.console_password}'",
      "~/upload/install-generic-cert.sh ${var.tls_certificate_email} validator-${count.index}-rpc.${var.dns_zone_name}",
      "~/upload/install-nginx-cert.sh ${var.tls_certificate_email} validator-${count.index}-api.${var.dns_zone_name} 1317",
      "~/upload/configure-validator.sh ${var.env} ${count.index} '${join(",", [for node in aws_eip.validator : node.public_ip])}' '${var.token_name}' '${var.validator_keys_passphrase}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    instance_created_or_deleted = join(",", [for r in aws_instance.validator : r.id])
    uploaded_files_changed      = join(",", [for f in setunion(fileset(".", "upload/node_key_*.json"), fileset(".", "upload/newchaind"), fileset(".", "upload/*.sh"), fileset(".", "modules/validator/upload/*.sh")) : filesha256(f)])
  }
}

resource "null_resource" "generate-and-install-genesis-file" {
  count = var.num_instances > 0 ? 1 : 0
  provisioner "local-exec" {
    command = "./modules/validator/upload/generate-and-install-genesis-file.sh ${var.env} '${join(",", [for node in aws_eip.validator : node.public_ip])}' ${var.ssh_private_key_path} ${var.token_name} ${var.validator_keys_passphrase}"
  }

  triggers = {
    client_configured = join(",", [for r in null_resource.configure_client : r.id])
    script_changed = filesha256("./modules/validator/upload/generate-and-install-genesis-file.sh")
  }
}

resource "null_resource" "start_validator" {
  count = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting validator node ${count.index} via systemctl...",
      "sudo systemctl restart newchain.service",
      "sleep 1",
      "sudo systemctl status -l newchain.service --no-pager",
      "sudo systemctl enable newchain.service",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    genesis_file_generated = join(",", [for r in null_resource.generate-and-install-genesis-file : r.id])
  }
}

