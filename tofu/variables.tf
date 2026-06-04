# DigitalOcean Droplet Configuration
variable "region" {
  description = "The DigitalOcean region where droplets will be created. Must be a region where managed Network File Storage is available (atl1, nyc2, ams3)."
  type        = string
  default     = "nyc2"

  validation {
    condition     = contains(["atl1", "nyc2", "ams3"], var.region)
    error_message = "region must be one of atl1, nyc2, or ams3 (the regions where DigitalOcean managed Network File Storage is GA)."
  }
}

variable "droplet_image" {
  description = "The image to use for the droplets (e.g., ubuntu-22-04-x64)"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "head_node_size" {
  description = "The size/type of the SLURM head node droplet (runs SLURM controller and accounting database). NFS is provided by a managed share, not this node."
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "compute_node_size" {
  description = "The size/type of the SLURM compute node droplet"
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "compute_node_count" {
  description = "Number of compute nodes to create"
  type        = number
  default     = 1
}

variable "cluster_name" {
  description = "Name prefix for the SLURM cluster resources"
  type        = string
  default     = "slurm-cluster"
}

variable "vpc_uuid" {
  description = "UUID of the VPC to place the droplets in (optional)"
  type        = string
  default     = null
}

# Managed Network File Storage (shared filesystem)
variable "nfs_size_gib" {
  description = "Size of the managed Network File Storage share in GiB (minimum 50)."
  type        = number
  default     = 50

  validation {
    condition     = var.nfs_size_gib >= 50
    error_message = "nfs_size_gib must be at least 50 GiB (DigitalOcean managed NFS minimum)."
  }
}

variable "nfs_performance_tier" {
  description = "Performance tier for the managed NFS share. Either 'standard' or 'high'."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "high"], var.nfs_performance_tier)
    error_message = "nfs_performance_tier must be either 'standard' or 'high'."
  }
}

variable "nfs_mount_point" {
  description = "Local directory on each droplet where the managed NFS share is mounted (simulates the pre-existing shared filesystem on the bare-metal cluster)."
  type        = string
  default     = "/shared"
}
