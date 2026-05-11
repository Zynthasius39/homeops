terraform {
  required_version = "~> 1.0"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.5.0"
    }
  }
}

provider "dns" {
  update {
    server        = var.bind.server
    port          = var.bind.port
    transport     = var.bind.transport
    key_name      = var.bind.tsig_key_name
    key_algorithm = var.bind.tsig_key_algorithm
    key_secret    = var.bind.tsig_key_secret
  }
}
