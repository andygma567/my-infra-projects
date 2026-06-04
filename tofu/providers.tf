terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      # >= 2.81 required for the managed Network File Storage resources
      # (digitalocean_nfs / digitalocean_nfs_attachment).
      version = ">= 2.81"
    }
  }
  required_version = "~> 1.10"
}

provider "digitalocean" {
  # Authentication token should be set via DIGITALOCEAN_TOKEN environment variable
  # or through digitalocean provider configuration
}

