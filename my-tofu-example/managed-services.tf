# Infrastructure Components for Self-Hosted SLURM Cluster
# This file contains infrastructure components that support self-hosted database and NFS
# Similar to what you might use in an on-premises environment

# Additional Block Storage for NFS data (optional)
# This provides extra persistent storage for your self-hosted NFS server
# Useful for testing storage configurations similar to dedicated storage on-prem
resource "digitalocean_volume" "nfs_data_storage" {
  count                    = var.nfs_shared_storage_size_gb > 0 ? 1 : 0
  region                   = var.region
  name                     = "${var.cluster_name}-nfs-data"
  size                     = var.nfs_shared_storage_size_gb
  initial_filesystem_type  = "ext4"
  description              = "Additional data storage for self-hosted NFS server"

  tags = [
    "slurm-cluster",
    "nfs-data",
    var.cluster_name
  ]
}

# Attach additional storage to the head node (if enabled)
resource "digitalocean_volume_attachment" "nfs_data_attachment" {
  count      = length(digitalocean_volume.nfs_data_storage) > 0 ? 1 : 0
  droplet_id = digitalocean_droplet.slurm_head_node.id
  volume_id  = digitalocean_volume.nfs_data_storage[0].id
}

# VPC for network isolation
resource "digitalocean_vpc" "slurm_vpc" {
  count       = var.vpc_uuid == null ? 1 : 0
  name        = "${var.cluster_name}-vpc"
  region      = var.region
  ip_range    = "10.10.0.0/16"
  description = "VPC for SLURM cluster isolation"
}

# Firewall rules for SLURM cluster
resource "digitalocean_firewall" "slurm_firewall" {
  name = "${var.cluster_name}-firewall"

  droplet_ids = [
    digitalocean_droplet.slurm_head_node.id,
    digitalocean_droplet.slurm_compute_node.id
  ]

  # SSH access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # SLURM slurmctld (controller daemon)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "6817"
    source_tags = ["slurm-cluster"]
  }

  # SLURM slurmd (compute node daemon)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "6818"
    source_tags = ["slurm-cluster"]
  }

  # SLURM slurmdbd (database daemon)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "6819"
    source_tags = ["slurm-cluster"]
  }

  # NFS
  inbound_rule {
    protocol    = "tcp"
    port_range  = "2049"
    source_tags = ["slurm-cluster"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  tags = [
    "slurm-cluster",
    "firewall",
    var.cluster_name
  ]
}