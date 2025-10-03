
# SLURM Head Node (Controller Node)
resource "digitalocean_droplet" "slurm_head_node" {
  name     = "${var.cluster_name}-head"
  image    = var.droplet_image
  size     = var.head_node_size
  region   = var.region
  ssh_keys = var.ssh_key_ids
  vpc_uuid = var.vpc_uuid

  # Enable monitoring and backups for the head node
  monitoring = var.enable_node_monitoring
  backups    = false

  # User data script to prepare the system for Ansible and self-hosted services
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip curl wget
    
    # Create slurm user (will be configured by Ansible)
    useradd -m -s /bin/bash slurm
    
    # Set hostname for easier identification
    hostnamectl set-hostname ${var.cluster_name}-head
    
    # Add hostname to /etc/hosts
    echo "127.0.0.1 ${var.cluster_name}-head" >> /etc/hosts
    
    # Prepare for self-hosted database (PostgreSQL will be installed by Ansible)
    # Create directory for database data
    mkdir -p /opt/slurm/database
    chown slurm:slurm /opt/slurm/database
    
    # Prepare for NFS server (NFS will be configured by Ansible)
    # Create shared directories
    mkdir -p /shared/home
    mkdir -p /shared/data
    mkdir -p /shared/software
    chown -R slurm:slurm /shared
    
    # Install NFS utilities (Ansible will configure the server)
    apt-get install -y nfs-kernel-server nfs-common
    
    # Enable and start services that Ansible will configure
    systemctl enable nfs-kernel-server
  EOF

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

  # Enable monitoring for the compute node
  monitoring = var.enable_node_monitoring
  backups    = false

  # User data script to prepare the system for Ansible and NFS client
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip curl wget
    
    # Create slurm user (will be configured by Ansible)
    useradd -m -s /bin/bash slurm
    
    # Set hostname for easier identification
    hostnamectl set-hostname ${var.cluster_name}-compute-01
    
    # Add hostname to /etc/hosts
    echo "127.0.0.1 ${var.cluster_name}-compute-01" >> /etc/hosts
    
    # Install NFS client utilities (Ansible will configure mounts)
    apt-get install -y nfs-common
    
    # Create mount points for NFS shares
    mkdir -p /shared/home
    mkdir -p /shared/data  
    mkdir -p /shared/software
    
    # Add head node to hosts file (will be updated by Ansible with actual IP)
    echo "# SLURM head node - will be updated by Ansible" >> /etc/hosts
    echo "# ${digitalocean_droplet.slurm_head_node.ipv4_address_private} ${var.cluster_name}-head" >> /etc/hosts
  EOF

  tags = [
    "slurm-cluster",
    "compute-node",
    var.cluster_name
  ]
}

# Legacy resource (keeping for compatibility)
resource "terraform_data" "this" {
  input = {
    example = var.input
  }
}
