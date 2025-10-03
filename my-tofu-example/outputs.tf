# SLURM Head Node Information
output "head_node_public_ip" {
  value       = digitalocean_droplet.slurm_head_node.ipv4_address
  description = "Public IP address of the SLURM head node"
}

output "head_node_private_ip" {
  value       = digitalocean_droplet.slurm_head_node.ipv4_address_private
  description = "Private IP address of the SLURM head node"
}

output "head_node_id" {
  value       = digitalocean_droplet.slurm_head_node.id
  description = "DigitalOcean droplet ID of the head node"
}

# SLURM Compute Node Information
output "compute_node_public_ip" {
  value       = digitalocean_droplet.slurm_compute_node.ipv4_address
  description = "Public IP address of the SLURM compute node"
}

output "compute_node_private_ip" {
  value       = digitalocean_droplet.slurm_compute_node.ipv4_address_private
  description = "Private IP address of the SLURM compute node"
}

output "compute_node_id" {
  value       = digitalocean_droplet.slurm_compute_node.id
  description = "DigitalOcean droplet ID of the compute node"
}

# Ansible Inventory Helper
output "ansible_inventory" {
  value = {
    head_nodes = {
      hosts = {
        "${digitalocean_droplet.slurm_head_node.name}" = {
          ansible_host = digitalocean_droplet.slurm_head_node.ipv4_address
          private_ip   = digitalocean_droplet.slurm_head_node.ipv4_address_private
          node_type    = "head"
        }
      }
    }
    compute_nodes = {
      hosts = {
        "${digitalocean_droplet.slurm_compute_node.name}" = {
          ansible_host = digitalocean_droplet.slurm_compute_node.ipv4_address
          private_ip   = digitalocean_droplet.slurm_compute_node.ipv4_address_private
          node_type    = "compute"
        }
      }
    }
  }
  description = "Ansible inventory structure for SLURM cluster nodes"
}

# All Node IPs for convenience
output "all_node_ips" {
  value = {
    public_ips = [
      digitalocean_droplet.slurm_head_node.ipv4_address,
      digitalocean_droplet.slurm_compute_node.ipv4_address
    ]
    private_ips = [
      digitalocean_droplet.slurm_head_node.ipv4_address_private,
      digitalocean_droplet.slurm_compute_node.ipv4_address_private
    ]
  }
  description = "All public and private IP addresses of cluster nodes"
}

# Additional NFS Storage Information
output "nfs_additional_storage" {
  value = var.nfs_shared_storage_size_gb > 0 ? {
    volume_id   = digitalocean_volume.nfs_data_storage[0].id
    volume_name = digitalocean_volume.nfs_data_storage[0].name
    size_gb     = digitalocean_volume.nfs_data_storage[0].size
    device_path = "/dev/disk/by-id/scsi-0DO_Volume_${digitalocean_volume.nfs_data_storage[0].name}"
  } : null
  description = "Additional NFS storage volume information (null if disabled)"
}

# Configuration Summary for Ansible
output "cluster_configuration" {
  value = {
    cluster_name     = var.cluster_name
    database_engine  = var.database_engine
    testing_mode     = var.testing_mode
    additional_nfs_storage = var.nfs_shared_storage_size_gb > 0
  }
  description = "Cluster configuration summary for Ansible variable files"
}

# Legacy output (keeping for compatibility)
output "output" {
  value       = terraform_data.this.output
  description = "This is an example of an output."
}
