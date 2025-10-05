# VPC for network isolation (simulates on-prem LAN)
resource "digitalocean_vpc" "slurm_vpc" {
  name        = "${var.cluster_name}-vpc"
  region      = var.region
  ip_range    = "10.10.0.0/16"
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