variable "clusters" {
  type = map(object({
    private_key = string
    public_key  = string
    storage     = object({
      pool     = string
      capacity = number
    })
    network     = object({
      gateway         = string
      libvirt_network = string
      search          = list(string)
      dns_servers     = list(string)
    })
    vms         = map(object({
      ip     = string
      mac    = string
      vcpu   = number
      memory = number
      os     = string
    }))
  }))
  default = {}
}

variable "cloud_images" {
  type = map(string)
}

variable "libvirt_uri" { type = string }

locals {
  flat_vms = merge([
    for cluster_key, cluster_data in var.clusters : {
      for vm_key, vm_config in cluster_data.vms :
      "${cluster_key}-${vm_key}" => merge(vm_config, {
        private_key = cluster_data.private_key
        public_key  = cluster_data.public_key
        storage     = cluster_data.storage
        network     = cluster_data.network
        group       = cluster_key
      })
    }
  ]...)
}
