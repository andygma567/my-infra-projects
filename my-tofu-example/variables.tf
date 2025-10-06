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
  description = "The size/type of the head node droplet (will host SLURM controller, database, and NFS server after Ansible configuration)"
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "compute_node_size" {
  description = "The size/type of the compute node droplets (will run SLURM compute daemon after Ansible configuration)"
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "compute_node_count" {
  description = "Number of compute node droplets to provision"
  type        = number
  default     = 1
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the droplets"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "Name prefix for infrastructure resources"
  type        = string
  default     = "slurm-cluster"
}

variable "vpc_uuid" {
  description = "UUID of the VPC to place the droplets in (optional)"
  type        = string
  default     = null
}
