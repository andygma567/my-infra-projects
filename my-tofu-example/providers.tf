terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 5.0"
    }
  }
  required_version = "~> 1.5"
}

provider "digitalocean" {
  # Authentication token should be set via DIGITALOCEAN_TOKEN environment variable
  # or through digitalocean provider configuration
}

