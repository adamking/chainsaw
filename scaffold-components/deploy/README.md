# Deploying a testnet

This guide walks you through deploying your newchain testnet to AWS infrastructure.

## Prerequisites

### Required Software
```bash
brew install jq terraform awscli
```

### AWS Configuration
1. Configure AWS CLI with appropriate credentials:
   ```bash
   aws configure
   ```
2. Ensure your AWS account has permissions for:
   - EC2 instance management
   - Route 53 DNS configuration
   - Security group creation
   - Load balancer setup
   - Key pair management

## Deployment Steps

### 1. DNS Configuration

From your project root directory:

```bash
deploy/create-zone.sh testnet newchain.yourdomain.com your@email.com
```

This command:
- Creates a Route 53 hosted zone
- Configures DNS settings
- Sets up SSL certificates
- Outputs nameserver information

#### Configuring Nameservers

1. Copy the nameservers from the command output
2. Add NS records to your domain registrar:
   - One record for each nameserver provided
   - Point them to `newchain.yourdomain.com`

#### Verify DNS Propagation

```bash
nslookup -type=ns newchain.yourdomain.com
```

Expected successful response:
```
Server:         10.136.126.106
Address:        10.136.126.106#53

Non-authoritative answer:
newchain.yourdomain.com    nameserver = ns-1306.awsdns-35.org.
newchain.yourdomain.com    nameserver = ns-143.awsdns-17.com.
newchain.yourdomain.com    nameserver = ns-800.awsdns-36.net.
newchain.yourdomain.com    nameserver = ns-1694.awsdns-19.co.uk.
```

Note: DNS propagation can take 15 minutes to 8 hours.

### 2. Deploy Chain Infrastructure

Deploy your validator and seed nodes:

```bash
deploy/create-servers.sh testnet 3 1  # 3 validators, 1 seed node
```

This command:
- Launches EC2 instances
- Configures security groups
- Sets up load balancers
- Initializes blockchain nodes
- Configures monitoring

### 3. Access Your Network

#### Web Interfaces

After 2-3 minutes, your services will be available:

- Block Explorer: `https://explorer.testnet.newchain.yourdomain.com`
- API Endpoint: `https://seed-0-api.testnet.newchain.yourdomain.com`
- RPC Endpoint: `https://seed-0-rpc.testnet.newchain.yourdomain.com`

#### Infrastructure Management

View AWS Resources:
```bash
open https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:
```

Display Node Information:
```bash
# View all node IPs
terraform -chdir=deploy output

# Get specific node IP
deploy/show-ip.sh seed 0
deploy/show-ip.sh validator 0

# Get API endpoints
deploy/show-api.sh validator 0
```

#### SSH Access

Connect to nodes:
```bash
# Interactive SSH session
deploy/ssh.sh validator 0
deploy/ssh.sh seed 0

# Run command directly
deploy/ssh.sh validator 0 "date"
```

## Maintenance

### Backup Keys
```bash
deploy/backup-keys.sh
```

### Monitor Nodes
- Check node status: `curl https://seed-0-api.testnet.newchain.yourdomain.com/status`
- Monitor logs: `deploy/ssh.sh validator 0 "journalctl -u newchain -f"`
- Check sync: `deploy/ssh.sh validator 0 "newchaind status"`

## Cost Management

### Stopping Testnet (Preserve Configuration)

To stop incurring charges while preserving configuration:
```bash
deploy/destroy-servers.sh testnet
```

This maintains:
- DNS configuration
- Terraform state
- Network setup

### Complete Cleanup

To remove all AWS resources including DNS zones:
```bash
deploy/destroy-all.sh testnet
```

Warning: This is irreversible and removes:
- All EC2 instances
- Load balancers
- DNS zones
- Security groups
- Network interfaces

## Troubleshooting

### Common Issues

1. DNS not propagating
   - Verify NS records are correct
   - Wait at least 15 minutes
   - Check with different DNS servers

2. Node connection issues
   - Verify security group rules
   - Check instance status
   - Validate network configuration

3. API endpoints unreachable
   - Ensure load balancers are healthy
   - Verify SSL certificate status
   - Check node service status

### Useful Commands

```bash
# Check node logs
deploy/ssh.sh validator 0 "journalctl -u newchain -f"

# Verify node status
deploy/ssh.sh validator 0 "newchaind status"

# Check API health
curl -k https://seed-0-api.testnet.newchain.yourdomain.com/node_info
```

## Security Considerations

- Regularly rotate SSH keys
- Monitor AWS CloudWatch logs
- Keep node software updated
- Backup validator keys securely
- Use strong firewall rules
- Enable AWS CloudTrail
- Monitor resource usage
