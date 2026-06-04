# OpenTofu variables (auto-loaded by `tofu apply`).
# region MUST be one of atl1, nyc2, ams3 (regions where managed NFS is GA).
region       = "nyc2"
cluster_name = "slurm-dev"

head_node_size    = "s-1vcpu-2gb"
compute_node_size = "s-1vcpu-2gb"

# Managed Network File Storage (shared filesystem)
nfs_size_gib         = 50
nfs_performance_tier = "standard"
nfs_mount_point      = "/shared"

droplet_image      = "ubuntu-22-04-x64"
compute_node_count = 2
