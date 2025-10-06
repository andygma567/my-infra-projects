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
output "compute_node_public_ips" {
  value       = digitalocean_droplet.slurm_compute_node[*].ipv4_address
  description = "Public IP addresses of the SLURM compute nodes"
}

output "compute_node_private_ips" {
  value       = digitalocean_droplet.slurm_compute_node[*].ipv4_address_private
  description = "Private IP addresses of the SLURM compute nodes"
}

output "compute_node_ids" {
  value       = digitalocean_droplet.slurm_compute_node[*].id
  description = "DigitalOcean droplet IDs of the compute nodes"
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
      hosts = merge([
        for idx, node in digitalocean_droplet.slurm_compute_node : {
          "${node.name}" = {
            ansible_host = node.ipv4_address
            private_ip   = node.ipv4_address_private
            node_type    = "compute"
          }
        }
      ]...)
    }
  }
  description = "Ansible inventory structure for SLURM cluster nodes"
}

# All Node IPs for convenience
output "all_node_ips" {
  value = {
    public_ips = concat(
      [digitalocean_droplet.slurm_head_node.ipv4_address],
      digitalocean_droplet.slurm_compute_node[*].ipv4_address
    )
    private_ips = concat(
      [digitalocean_droplet.slurm_head_node.ipv4_address_private],
      digitalocean_droplet.slurm_compute_node[*].ipv4_address_private
    )
  }
  description = "All public and private IP addresses of cluster nodes"
}