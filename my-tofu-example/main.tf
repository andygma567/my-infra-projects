
# SLURM Head Node (Controller Node)
resource "digitalocean_droplet" "slurm_head_node" {
  name     = "${var.cluster_name}-head"
  image    = var.droplet_image
  size     = var.head_node_size
  region   = var.region
  ssh_keys = var.ssh_key_ids
  vpc_uuid = var.vpc_uuid

  tags = [
    "slurm-cluster",
    "head-node",
    "controller",
    var.cluster_name
  ]
}

# SLURM Compute Node
resource "digitalocean_droplet" "slurm_compute_node" {
  name     = "${var.cluster_name}-compute-01"
  image    = var.droplet_image
  size     = var.compute_node_size
  region   = var.region
  ssh_keys = var.ssh_key_ids
  vpc_uuid = var.vpc_uuid

  tags = [
    "slurm-cluster",
    "compute-node",
    var.cluster_name
  ]
}