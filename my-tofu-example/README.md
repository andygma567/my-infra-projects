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
| `head_node_size` | Head node droplet size | `s-1vcpu-512mb-10gb` |
| `compute_node_size` | Compute node droplet size | `s-1vcpu-512mb-10gb` |
| `compute_node_count` | Number of compute nodes to provision | `1` |
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

## Cost Optimization

1. **Droplet Sizes**: Start with smaller droplets and scale up based on workload needs
2. **Monitoring**: Monitoring is included but can be disabled to reduce costs
3. **Storage**: Additional block storage is disabled by default (set `nfs_shared_storage_size_gb > 0` to enable)
4. **Destroy When Not Needed**: Use `tofu destroy` to tear down infrastructure when testing is complete

