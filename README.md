# Chainsaw 🪚

A powerful tool to generate and deploy Cosmos SDK-based blockchains to AWS testnets.

## Overview

Chainsaw automates the process of:
1. Generating a new Cosmos SDK blockchain using Ignite CLI
2. Setting up deployment infrastructure using Terraform
3. Deploying a complete testnet to AWS with validators, seed nodes, and a block explorer

## Prerequisites

### Required Software
- [Docker Desktop](https://docs.docker.com/get-docker/)
- [Homebrew](https://brew.sh/) (for macOS users)
- Command line tools:
  ```bash
  brew install jq terraform awscli ignite
  ```
- Go v1.21.4 (required by Ignite)
- AWS CLI configured with appropriate credentials:
  ```bash
  aws configure
  ```

### AWS Permissions
Your AWS credentials must have permissions to:
- Create and manage EC2 instances
- Manage Route 53 DNS records
- Create and configure security groups
- Manage network interfaces

Required IAM permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "route53:*",
                "elasticloadbalancing:*",
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*"
        }
    ]
}
```

### Infrastructure Requirements
- Validator nodes: t3.medium (2 vCPU, 4 GB RAM)
- Seed nodes: t3.small (2 vCPU, 2 GB RAM)
- Explorer node: t3.medium (2 vCPU, 4 GB RAM)
- Load balancers: Application Load Balancer (ALB)

### Estimated Costs (US East Region)
Monthly cost estimates for a typical setup (3 validators, 1 seed node):
- EC2 instances: ~$70-90/month
- Load balancers: ~$20/month
- Route 53: ~$0.50/month per hosted zone
- Data transfer: Varies based on usage (~$10-30/month)
Total estimated cost: $100-140/month

## Quick Start

### 1. Generate Your Chain

Add `chainsaw.sh` to your PATH and run:
```bash
chainsaw.sh <github-org> <chain-name>
cd <chain-name>
```

Example:
```bash
chainsaw.sh myorg awesome-chain
cd awesome-chain
```

### 2. Set Up DNS Zone

1. Choose a subdomain for your blockchain (e.g., `awesome-chain.yourdomain.com`)
2. Create the DNS zone:
   ```bash
   deploy/create-zone.sh testnet awesome-chain.yourdomain.com your@email.com
   ```
3. Add NS records to your domain's DNS settings (provided in the create-zone.sh output)
4. Verify DNS propagation (may take 1-4 hours):
   ```bash
   nslookup -type=ns awesome-chain.yourdomain.com
   ```

### 3. Deploy Testnet

Deploy your validators and seed nodes:
```bash
deploy/create-servers.sh testnet <num-validators> <num-seeds>
```

Example for 3 validators and 1 seed node:
```bash
deploy/create-servers.sh testnet 3 1
```

## Accessing Your Testnet

### Web Interfaces
- Block Explorer: `https://explorer.testnet.<your-domain>`
- API Endpoint: `https://seed-0-api.testnet.<your-domain>`

### Server Management
View server details:
```bash
terraform -chdir=deploy output
```

SSH into servers:
```bash
deploy/ssh.sh validator <number>  # e.g., deploy/ssh.sh validator 0
deploy/ssh.sh seed <number>      # e.g., deploy/ssh.sh seed 0
deploy/ssh.sh explorer 0
```

## Cost Management

### Stopping Testnet (Preserve Configuration)
```bash
deploy/destroy-servers.sh
```

### Complete Cleanup (Including DNS)
```bash
deploy/destroy-all.sh
```

## Architecture

The deployment creates:
- Validator nodes: Process transactions and maintain consensus
- Seed nodes: Handle P2P networking and API requests
- Explorer node: Runs a block explorer web interface
- Load balancers: Distribute API traffic
- Security groups: Manage network access
- DNS records: Provide easy access to network services

### Infrastructure Best Practices

#### AWS Configuration
1. **VPC and Networking**:
   - Use private subnets for validators
   - Enable VPC Flow Logs for network monitoring
   - Configure AWS WAF on ALB for DDoS protection
   - Enable GuardDuty for threat detection

2. **Security**:
   - Use AWS KMS for key management
   - Enable EBS encryption by default
   - Use Systems Manager Session Manager instead of direct SSH
   - Enable AWS Config for compliance monitoring

3. **Monitoring**:
   - Set up CloudWatch Log Groups with retention policies
   - Configure CloudWatch Alarms for metrics
   - Enable AWS CloudTrail with log file validation
   - Use X-Ray for request tracing

#### Terraform State Management
1. **Remote State**:
   ```hcl
   # backend.hcl
   bucket         = "your-terraform-state-bucket"
   region         = "us-east-1"
   dynamodb_table = "terraform-lock"
   encrypt        = true
   ```

2. **Workspace Usage**:
   ```bash
   # Create and use environments
   terraform workspace new staging
   terraform workspace new production
   ```

### Chain Management

#### Validator Setup
1. **Key Management**:
   - Use AWS Secrets Manager for validator keys
   - Implement key rotation procedures
   - Configure HSM for production deployments

2. **Monitoring**:
   - Set up Prometheus and Grafana
   - Configure alerting for:
     - Block production delays
     - Validator disconnections
     - Consensus failures
     - Resource utilization

3. **Backup Procedures**:
   ```bash
   # Automated daily backups
   aws backup start-backup-job --backup-vault-name chain-backup \
     --resource-arn arn:aws:ec2:region:account-id:instance/instance-id
   ```

#### Chain Upgrades
1. **Preparation**:
   - Test upgrades on staging environment
   - Take snapshots of validator state
   - Notify stakeholders of upgrade schedule

2. **Execution**:
   ```bash
   # Upgrade procedure
   deploy/upgrade.sh <new-version> --height <block-height>
   ```

3. **Verification**:
   - Monitor upgrade progress
   - Verify chain continuity
   - Check validator participation

### Security Best Practices

1. **Access Control**:
   - Use AWS IAM roles with least privilege
   - Implement MFA for AWS console access
   - Regular rotation of access keys

2. **Network Security**:
   - Implement network segmentation
   - Use security groups with minimal access
   - Enable AWS Shield for DDoS protection

3. **Monitoring and Compliance**:
   - Regular security audits
   - Automated compliance checks
   - Incident response procedures

## Future Enhancements

- [ ] Mainnet deployment with enhanced security features
- [ ] Multi-cloud provider support (Linode, Digital Ocean)
- [ ] Automated backup and recovery
- [ ] Monitoring and alerting integration
- [ ] Governance parameter configuration
- [ ] Automated security patching

## Troubleshooting

### Common Issues

1. DNS propagation delays
   - Solution: Wait 1-4 hours and verify with `nslookup`
   
2. AWS permission errors
   - Solution: Verify AWS CLI configuration and IAM permissions

3. Terraform state issues
   - Solution: Check `terraform.tfstate` file and run `terraform init`

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is open source. See LICENSE file for details.
