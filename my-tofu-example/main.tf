# VPC for network isolation (simulates on-prem LAN)
resource "digitalocean_vpc" "slurm_vpc" {
  name        = "${var.cluster_name}-vpc"
  region      = var.region
  ip_range    = "10.200.0.0/24" # the 10.116.x.x range is already used by Digital Ocean
  description = "VPC for SLURM cluster isolation - simulates on-prem network"
}

# SLURM Head Node (Controller Node)
resource "digitalocean_droplet" "slurm_head_node" {
  name     = "${var.cluster_name}-head"
  image    = var.droplet_image
  size     = var.head_node_size
  region   = var.region
  ssh_keys = var.ssh_key_ids
  vpc_uuid = digitalocean_vpc.slurm_vpc.id

  tags = [
    "slurm-cluster",
    "head-node",
    "controller",
    var.cluster_name
  ]
}

# SLURM Compute Nodes
resource "digitalocean_droplet" "slurm_compute_node" {
  count    = var.compute_node_count
  name     = "${var.cluster_name}-compute-${format("%02d", count.index + 1)}"
  image    = var.droplet_image
  size     = var.compute_node_size
  region   = var.region
  ssh_keys = var.ssh_key_ids
  vpc_uuid = digitalocean_vpc.slurm_vpc.id

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
  # Where to save the generated inventory file
  filename = "${path.module}/inventory.yaml"

  # Generate content using the template file
  content = templatefile("${path.module}/inventory.tftpl", {
    # Pass head node information to the template
    head_node_public_ip  = digitalocean_droplet.slurm_head_node.ipv4_address
    head_node_private_ip = digitalocean_droplet.slurm_head_node.ipv4_address_private
    head_node_name       = digitalocean_droplet.slurm_head_node.name

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