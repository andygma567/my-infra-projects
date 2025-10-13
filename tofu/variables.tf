# DigitalOcean Droplet Configuration
variable "region" {
  description = "The DigitalOcean region where droplets will be created"
  type        = string
  default     = "nyc1"
}

variable "droplet_image" {
  description = "The image to use for the droplets (e.g., ubuntu-22-04-x64)"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "head_node_size" {
  description = "The size/type of the SLURM head node droplet (runs SLURM controller, database, and NFS server)"
  type        = string
  default     = "s-1vcpu-512mb-10gb" # Increased for self-hosted database and NFS
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
