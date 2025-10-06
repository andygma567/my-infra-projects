# SLURM Cluster Infrastructure on DigitalOcean

This OpenTofu/Terraform configuration **provisions DigitalOcean infrastructure** for a SLURM cluster. It creates the necessary compute resources (VPC, droplets) and generates an Ansible inventory file for subsequent configuration.

## What This Does

This infrastructure-as-code project provisions:
- **VPC**: Creates a Virtual Private Cloud for network isolation
- **Head Node Droplet**: Provisions a VM that will host the SLURM controller
- **Compute Node Droplets**: Provisions VMs that will run SLURM compute workloads (configurable count)
- **Ansible Inventory**: Generates an `inventory.yaml` file with node IPs and groups for Ansible playbooks

## What This Does NOT Do

This project does **not** install or configure any services. After infrastructure is provisioned, you will need to use Ansible playbooks to:
- Install and configure SLURM services (slurmctld, slurmd, slurmdbd)
- Set up NFS server and client mounts
- Install and configure PostgreSQL or MySQL for SLURM accounting
- Configure inter-node communication and authentication

## Architecture

This configuration provisions the following DigitalOcean resources:

- **VPC (Virtual Private Cloud)**: Network isolation with a private IP range (10.200.0.0/24)
- **Head Node Droplet**: Single VM intended for SLURM controller, database, and NFS server roles
- **Compute Node Droplets**: Multiple VMs (default: 1) intended for SLURM compute execution
- **Ansible Inventory File**: Auto-generated YAML file mapping nodes to Ansible groups

## Prerequisites

1. **DigitalOcean Account**: Create an account and generate an API token
2. **SSH Key**: Upload your SSH public key to DigitalOcean and note the key ID
3. **OpenTofu/Terraform**: Install OpenTofu or Terraform

## Quick Start

### Deploy Infrastructure

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
   compute_node_count = 2
   ```

3. **Initialize and Deploy**:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

4. **Verify Infrastructure**:
   ```bash
   tofu output
   ```
   
   This will display the public/private IPs of your nodes and confirm the `inventory.yaml` file was generated.

## Configuration Files

### Core Files
- `main.tf`: Defines DigitalOcean infrastructure resources (VPC, droplets)
- `variables.tf`: Input variables for infrastructure configuration
- `outputs.tf`: Output values including IP addresses and Ansible inventory structure
- `providers.tf`: DigitalOcean provider configuration
- `inventory.tftpl`: Template for generating Ansible inventory file

### Optional Managed Services
- `managed-services.tf`: Additional DigitalOcean managed services (disabled by default)

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | DigitalOcean region | `nyc1` |
| `cluster_name` | Name prefix for infrastructure resources | `slurm-cluster` |
| `droplet_image` | OS image for droplets | `ubuntu-22-04-x64` |
| `head_node_size` | Head node droplet size | `s-4vcpu-8gb` |
| `compute_node_size` | Compute node droplet size | `s-4vcpu-8gb` |
| `compute_node_count` | Number of compute nodes to provision | `1` |
| `nfs_shared_storage_size_gb` | Additional storage for NFS (0 to disable) | `0` |
| `database_engine` | Database engine (postgresql/mysql) | `postgresql` |
| `enable_node_monitoring` | Enable droplet monitoring | `true` |
| `testing_mode` | Enable testing mode configurations | `true` |
| `ssh_key_ids` | List of SSH key IDs | `[]` |
| `vpc_uuid` | VPC UUID (optional) | `null` |

## Outputs

The configuration provides infrastructure details for use with Ansible:
- **Node IP addresses**: Public IPs for SSH access, private IPs for inter-node communication
- **Ansible inventory file**: Generated `inventory.yaml` with pre-configured groups (nfs_servers, nfs_clients, slurmservers, slurmexechosts, etc.)
- **Node metadata**: Droplet IDs and names for infrastructure management

The generated `inventory.yaml` file is ready to use with Ansible playbooks for configuring SLURM and related services.

## Next Steps (After Infrastructure is Provisioned)

Once the infrastructure is deployed, you need to configure the nodes using Ansible:

1. **Verify Connectivity**: 
   ```bash
   # Test SSH access to head node
   ssh root@$(tofu output -raw head_node_public_ip)
   
   # Test SSH access to compute nodes
   # Use the IPs from 'tofu output'
   ```

2. **Use Generated Ansible Inventory**:
   The `inventory.yaml` file is automatically created with proper groups:
   - `nfs_servers`: Head node (for NFS server configuration)
   - `nfs_clients`: Compute nodes (for NFS client mounts)
   - `slurmservers`: Head node (for SLURM controller)
   - `slurmexechosts`: Compute nodes (for SLURM execution)
   - `slurmdbdservers`: Head node (for SLURM accounting database)

3. **Run Your Ansible Playbooks**:
   ```bash
   # Example: Configure NFS
   ansible-playbook -i inventory.yaml configure_nfs.yml
   
   # Example: Install and configure SLURM
   ansible-playbook -i inventory.yaml install_slurm.yml
   
   # Example: Set up SLURM accounting database
   ansible-playbook -i inventory.yaml setup_slurm_accounting.yml
   ```

4. **Verify SLURM Configuration**:
   After running your Ansible playbooks:
   ```bash
   # SSH to head node and check SLURM
   ssh root@$(tofu output -raw head_node_public_ip)
   sinfo  # Should show your compute nodes
   squeue # Check job queue
   ```

5. **Scale as Needed**:
   - Modify `compute_node_count` in `terraform.tfvars`
   - Run `tofu apply` to add/remove nodes
   - Re-run Ansible playbooks to configure new nodes

## Scaling

To add more compute nodes:
1. Update `compute_node_count` in your `terraform.tfvars` file
2. Run `tofu apply` to provision additional nodes
3. The `inventory.yaml` file will be automatically updated
4. Run your Ansible playbooks to configure the new nodes

## Security Considerations

1. **SSH Keys**: Always use SSH keys for authentication, never passwords
2. **VPC**: The configuration creates a VPC for network isolation
3. **Private IPs**: Configure services to use private IP addresses for inter-node communication
4. **Firewall**: Consider adding firewall rules if using the optional `managed-services.tf`

## Cost Optimization

1. **Droplet Sizes**: Start with smaller droplets and scale up based on workload needs
2. **Monitoring**: Monitoring is included but can be disabled to reduce costs
3. **Storage**: Additional block storage is disabled by default (set `nfs_shared_storage_size_gb > 0` to enable)
4. **Destroy When Not Needed**: Use `tofu destroy` to tear down infrastructure when testing is complete

## Troubleshooting

### Infrastructure Issues
1. **SSH Key Errors**: Verify SSH key IDs are correct in DigitalOcean dashboard
2. **Network Issues**: Check VPC configuration and ensure private IP range doesn't conflict
3. **Resource Limits**: Verify your DigitalOcean account has sufficient droplet limits

### Connectivity Issues
1. **Cannot SSH to Nodes**: Check that your SSH key is properly added and firewall rules allow SSH
2. **Nodes Cannot Communicate**: Ensure all nodes are in the same VPC and using private IPs

### After Configuration
For SLURM-specific issues after running Ansible playbooks, ensure:
- Private IPs are used in SLURM configuration files
- SLURM services are running on all nodes
- Time synchronization is configured (NTP)
- Firewall rules allow SLURM ports (6817-6819, etc.)

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

