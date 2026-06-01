# Look up existing public SSH key from DigitalOcean by name
data "digitalocean_ssh_key" "my_key" {
  name = "MacBook-Air-key" # Replace with your actual key name in DigitalOcean
}

# VPC for network isolation (simulates on-prem LAN)
resource "digitalocean_vpc" "slurm_vpc" {
  name        = "${var.cluster_name}-vpc"
  region      = var.region
  ip_range    = "10.200.0.0/24"
  description = "VPC for SLURM cluster isolation - simulates on-prem network"
}

# ============================================================================
# SHARED FILESYSTEM (managed Network File Storage)
# ============================================================================
# DigitalOcean managed NFS provides the shared filesystem instead of an
# Ansible-managed NFS server. This mirrors the production bare-metal cluster,
# where NFS already exists and Ansible only configures Slurm.
# ============================================================================

resource "digitalocean_nfs" "shared" {
  name             = "${var.cluster_name}-share"
  region           = var.region
  size             = var.nfs_size_gib
  vpc_id           = digitalocean_vpc.slurm_vpc.id
  performance_tier = var.nfs_performance_tier
}

# Attach the share to the VPC so droplets in it can mount it.
resource "digitalocean_nfs_attachment" "shared" {
  region   = var.region
  share_id = digitalocean_nfs.shared.id
  vpc_id   = digitalocean_vpc.slurm_vpc.id
}

# cloud-init script that mounts the managed share on each droplet at boot.
locals {
  nfs_mount_user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    nfs_host       = digitalocean_nfs.shared.host
    nfs_mount_path = digitalocean_nfs.shared.mount_path
    local_mount    = var.nfs_mount_point
  })
}

# SLURM Head Node (Controller Node)
resource "digitalocean_droplet" "slurm_head_node" {
  name      = "${var.cluster_name}-head"
  image     = var.droplet_image
  size      = var.head_node_size
  region    = var.region
  ssh_keys  = [data.digitalocean_ssh_key.my_key.id] # Reference the data source
  vpc_uuid  = digitalocean_vpc.slurm_vpc.id
  user_data = local.nfs_mount_user_data

  # Ensure the share is attached to the VPC before droplets try to mount it.
  depends_on = [digitalocean_nfs_attachment.shared]

  tags = [
    "slurm-cluster",
    "head-node",
    "controller",
    var.cluster_name
  ]
}

# SLURM Compute Nodes
resource "digitalocean_droplet" "slurm_compute_node" {
  count     = var.compute_node_count
  name      = "${var.cluster_name}-compute-${format("%02d", count.index + 1)}"
  image     = var.droplet_image
  size      = var.compute_node_size
  region    = var.region
  ssh_keys  = [data.digitalocean_ssh_key.my_key.id] # Reference the data source
  vpc_uuid  = digitalocean_vpc.slurm_vpc.id
  user_data = local.nfs_mount_user_data

  # Ensure the share is attached to the VPC before droplets try to mount it.
  depends_on = [digitalocean_nfs_attachment.shared]

  tags = [
    "slurm-cluster",
    "compute-node",
    var.cluster_name
  ]
}

# ============================================================================
# ANSIBLE INVENTORY GENERATION
# ============================================================================
# This resource automatically generates an Ansible inventory.yaml file
# whenever you run 'terraform apply'
# ============================================================================

resource "local_file" "ansible_inventory" {
  # Where to save the generated inventory file.
  # Saves to ../build/hosts.yml so Ansible can find it.
  filename = "${path.module}/../build/hosts.yml"

  # Generate content using the template file
  content = templatefile("${path.module}/hosts.tftpl", {
    # Pass head node information to the template
    head_node_public_ip  = digitalocean_droplet.slurm_head_node.ipv4_address
    head_node_private_ip = digitalocean_droplet.slurm_head_node.ipv4_address_private
    head_node_name       = digitalocean_droplet.slurm_head_node.name

    # Managed shared filesystem details (mounted on every node via cloud-init)
    nfs_share_host  = digitalocean_nfs.shared.host
    nfs_share_path  = digitalocean_nfs.shared.mount_path
    nfs_mount_point = var.nfs_mount_point

    # Pass compute nodes as a list of objects to the template
    # The [*] syntax collects all compute nodes into a list
    compute_nodes = [
      for node in digitalocean_droplet.slurm_compute_node : {
        name       = node.name
        public_ip  = node.ipv4_address
        private_ip = node.ipv4_address_private
      }
    ]
  })
}