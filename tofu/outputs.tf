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

# Managed Shared Filesystem (Network File Storage)
output "nfs_share_host" {
  value       = digitalocean_nfs.shared.host
  description = "Host IP of the managed NFS share (reachable from within the VPC)"
}

output "nfs_share_path" {
  value       = digitalocean_nfs.shared.mount_path
  description = "Export path of the managed NFS share"
}

output "nfs_mount_point" {
  value       = var.nfs_mount_point
  description = "Local directory where the share is mounted on every node"
}

# Ansible Inventory File Location
output "inventory_file" {
  value       = local_file.ansible_inventory.filename
  description = "Path to generated Ansible inventory file"
}
