variable "nodes" {
  type = map(object({
    ip     = string
    mac    = string
    memory = number
    vcpu   = number
  }))
}

variable "private_key" { type = string }
variable "public_key"  { type = string }
variable "libvirt_uri" { type = string }

variable "storage" {
  type = object({
    image_path = string
    image_pool = string
  })
}

variable "network" {
  type = object({
    gateway         = string
    libvirt_network = string
    search          = list(string)
    dns_servers     = list(string)
  })
}

terraform {
  required_version = "~> 1.0"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

resource "tls_private_key" "node" {
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  filename        = pathexpand(var.private_key)
  content         = tls_private_key.node.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key" {
  filename = pathexpand(var.public_key)
  content  = tls_private_key.node.public_key_openssh
}

resource "libvirt_volume" "node" {
  for_each = var.nodes
  name     = "${each.key}.qcow2"
  pool     = var.storage.image_pool
  capacity = 10737418240  # 10GB
  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path   = pathexpand(var.storage.image_path)
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "init" {
  for_each = var.nodes
  name     = "${each.key}-init"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.key
  })

  user_data = templatefile("${path.module}/cloud-init.tftpl", {
    hostname    = each.key
    ssh_pub_key = [tls_private_key.node.public_key_openssh]
  })

  network_config = templatefile("${path.module}/network-config.tftpl", {
    ip          = [each.value.ip]
    mac         = each.value.mac
    gateway     = var.network.gateway
    search      = var.network.search
    dns_servers = var.network.dns_servers
  })
}

resource "libvirt_volume" "cloudinit" {
  for_each = var.nodes
  name     = "${each.key}-cloudinit.iso"
  pool     = "cloudinit"

  create = {
    content = {
      url = libvirt_cloudinit_disk.init[each.key].path
    }
  }
}

resource "libvirt_domain" "node" {
  for_each    = var.nodes
  name		    = each.key
  memory	    = each.value.memory
  memory_unit = "MiB"
  vcpu		    = each.value.vcpu
  autostart   = true
  running     = true
  type        = "kvm"

  os = {
    type         = "hvm"
    type_machine = "q35"
  }

  features = {
    acpi = true
    apic = {
      eoi = "on"
    }
    vm_port = {
      state = "off"
    }
  }

  cpu = {
    mode = "host-passthrough"
  }

  clock = {
    timer = [
      {
        name        = "rtc"
        tick_policy = "catchup"
      },
      {
        name        = "pit"
        tick_policy = "delay"
      },
      {
        name    = "hpet"
        present = "no"
      }
    ]
  }


  devices = {
    disks = [
      {
        driver = {
          type = "qcow2"
        }
        source = {
          file = {
            file = libvirt_volume.node[each.key].path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        driver = {
          type = "raw"
        }
        source = {
          file = {
            file = libvirt_volume.cloudinit[each.key].path
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        mac = {
          address = each.value.mac
        }
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.network.libvirt_network
          }
        }
      }
    ]
  }
}
