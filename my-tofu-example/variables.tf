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
  default     = "s-4vcpu-8gb"  # Increased for self-hosted database and NFS
}

variable "compute_node_size" {
  description = "The size/type of the SLURM compute node droplet"
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "compute_node_count" {
  description = "Number of compute nodes to create"
  type        = number
  default     = 1
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the droplets"
  type        = list(string)
  default     = []
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

# Self-hosted service configuration variables
variable "nfs_shared_storage_size_gb" {
  description = "Size in GB for additional NFS storage volume (set to 0 to disable)"
  type        = number
  default     = 0
}

variable "database_engine" {
  description = "Database engine to use for SLURM accounting (for documentation purposes)"
  type        = string
  default     = "postgresql"
  validation {
    condition     = contains(["postgresql", "mysql"], var.database_engine)
    error_message = "Database engine must be either 'postgresql' or 'mysql'."
  }
}

variable "enable_node_monitoring" {
  description = "Enable detailed monitoring on droplets (similar to on-prem monitoring setup)"
  type        = bool
  default     = true
}

variable "testing_mode" {
  description = "Enable testing mode with smaller resources and additional debugging"
  type        = bool
  default     = true
}

# Legacy variable (keeping for compatibility)
variable "input" {
  description = "This is an example of an input."
  type        = string
  default     = "test"
}
