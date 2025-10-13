# Self-Hosted SLURM Cluster on DigitalOcean with OpenTofu

This OpenTofu configuration creates a SLURM cluster on DigitalOcean designed for **testing self-hosted services** that mirror on-premises deployments. All services (database, NFS, SLURM) are deployed on the VMs using Ansible, making this an ideal testing ground for your on-prem cluster tools and configurations.

## Architecture (Self-Hosted Services)

- **Head Node**: Runs SLURM controller daemon (slurmctld), PostgreSQL database, and NFS server
- **Compute Node**: Runs SLURM compute daemon (slurmd), connects to head node for scheduling and mounts NFS shares
- **All services self-hosted**: No managed DigitalOcean services used (except basic infrastructure)

## Why Self-Hosted?

This configuration mirrors typical on-premises SLURM deployments where:
- Database runs on dedicated hardware or VMs
- NFS provides shared storage from dedicated storage nodes
- All components are managed by your tools (Ansible, monitoring, etc.)

Testing here ensures your Ansible playbooks and configurations work before deploying on-prem.

## Prerequisites

1. **DigitalOcean Account**: Create an account and generate an API token
2. **SSH Key**: Upload your SSH public key to DigitalOcean and note the key ID
3. **OpenTofu/Terraform**: Install OpenTofu or Terraform

## Quick Start

1. **Set Environment Variables**:
   ```bash
   export DIGITALOCEAN_TOKEN="your-do-token-here"
   ```

2. **Configure Variables**:
   Create a `terraform.tfvars` file:
   ```hcl
   region = "nyc1"
   cluster_name = "my-slurm-cluster"
   ssh_key_ids = ["your-ssh-key-id"]
   head_node_size = "s-2vcpu-4gb"
   compute_node_size = "s-4vcpu-8gb"
   ```

3. **Deploy the Infrastructure**:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

4. **Get Output Information**:
   ```bash
   tofu output
   ```

## Configuration Files

### Core Files
- `main.tf`: Droplet resources for SLURM cluster
- `variables.tf`: Input variables for configuration
- `outputs.tf`: Output values including IP addresses and Ansible inventory
- `providers.tf`: DigitalOcean provider configuration

### Optional Managed Services
- `managed-services.tf`: Additional DigitalOcean managed services (disabled by default)

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | DigitalOcean region | `nyc1` |
| `cluster_name` | Name prefix for resources | `slurm-cluster` |
| `droplet_image` | OS image for droplets | `ubuntu-22-04-x64` |
| `head_node_size` | Head node droplet size (runs DB + NFS + SLURM) | `s-4vcpu-8gb` |
| `compute_node_size` | Compute node droplet size | `s-4vcpu-8gb` |
| `nfs_shared_storage_size_gb` | Additional storage for NFS (0 to disable) | `0` |
| `database_engine` | Database engine (postgresql/mysql) | `postgresql` |
| `enable_node_monitoring` | Enable droplet monitoring | `true` |
| `testing_mode` | Enable testing mode configurations | `true` |
| `ssh_key_ids` | List of SSH key IDs | `[]` |
| `vpc_uuid` | VPC UUID (optional) | `null` |

## Outputs

The configuration provides several outputs useful for Ansible:
- Individual node IP addresses (public and private)
- Ansible inventory structure
- Node IDs and metadata

## Infrastructure Components for Self-Hosted Services

The `managed-services.tf` file includes infrastructure components that support your self-hosted approach:

### Network Infrastructure
- **VPC**: Network isolation and security (similar to on-prem VLANs)
- **Firewall**: Managed firewall rules for SLURM ports and NFS
- Provides foundation similar to on-premises network setup

### Optional Additional Storage
- **Block Storage Volume**: Additional persistent storage for NFS data
- Set `nfs_shared_storage_size_gb > 0` to enable
- Simulates dedicated storage hardware in on-prem environments

### Self-Hosted Service Preparation
- Head node pre-configured with directories for database and NFS
- NFS utilities pre-installed on all nodes
- Service preparation that mirrors on-prem server preparation

## Ansible Integration

The configuration outputs an `ansible_inventory` structure that can be used directly:

```bash
# Get Ansible inventory from Terraform output
tofu output -json ansible_inventory > inventory.json

# Or get individual IPs
HEAD_NODE_IP=$(tofu output -raw head_node_public_ip)
COMPUTE_NODE_IP=$(tofu output -raw compute_node_public_ip)
```

## Security Considerations

1. **SSH Keys**: Always use SSH keys, never passwords
2. **VPC**: Consider using a VPC for network isolation
3. **Firewall**: The configuration includes a firewall with SLURM-specific ports
4. **Private IPs**: Use private IP addresses for inter-node communication

## Cost Optimization

1. **Droplet Sizes**: Start small and scale up as needed
2. **Monitoring**: Enable droplet monitoring (included)
3. **Backups**: Backups are disabled by default to save costs
4. **Managed Services**: Consider cost vs. management overhead

## Next Steps

After deployment:

1. **Verify Connectivity**: SSH to both nodes
2. **Run Ansible Playbooks**: Configure SLURM using your existing playbooks
3. **Test SLURM**: Submit test jobs to verify the cluster works
4. **Scale**: Add more compute nodes as needed

## Scaling

To add more compute nodes, duplicate the compute node resource in `main.tf` with different names and update the outputs accordingly.

## Troubleshooting

1. **SSH Issues**: Verify SSH key IDs are correct
2. **Network Issues**: Check VPC and firewall settings
3. **SLURM Issues**: Ensure private IPs are used for inter-node communication

This package was automatically generated by the [Terraform in Depth Cookiecutter Template](https://github.com/TerraformInDepth/terraform-module-cookiecutter). You should replace this description with some information about your project.

## API

<!-- BEGIN_TF_DOCS -->
This section will be automatically generated with Terraform-Docs. Run `make documentation` after making changes.
<!-- END_TF_DOCS -->

## Development

### Dependencies

This project can install most dependencies automatically using a package manager, so please make sure they are installed.

* Windows: [Chocolatey](https://chocolatey.org/)
* MacOS: [Homebrew](https://brew.sh/)

Now run `make install` and most tools will be installed for you.

> [!WARNING]
> [pre-commit](https://pre-commit.com/#install) and [Checkov](https://www.checkov.io/2.Basics/Installing%20Checkov.html) need to be installed manually on Windows.

### Pre Commit

The Pre-Commit framework is used to manage and install pre-commit hooks on your local machine. After cloning this repository you can run `make precommit_install` to initialize the hooks. This only needs to be done once after cloning.

### Running Chores

The `make chores` command will automatically update documentation using Terraform-Docs, and will run automatic formatting.

### Security Checks

This project uses Trivy and Checkov for security scanning. You can run `make test_security` to run both tools, while `make test_trivy` and `make test_checkov` run each component on its own.

### Linting

To run TFLint use the command `make test_tflint`.

It is possible to automatically apply some fixes, but these should be reviewed before running. If you are comfortable with all of the results from `make test_tflint` being fixed automatically then run `make fix_tflint`.

