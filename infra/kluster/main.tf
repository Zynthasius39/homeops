resource "tls_private_key" "cluster" {
  for_each  = toset([for vm in local.flat_vms : vm.group])
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  for_each        = tls_private_key.cluster
  content         = each.value.private_key_pem
  filename        = pathexpand([for vm in local.flat_vms : vm.private_key if vm.group == each.key][0])
  file_permission = "0600"
}

resource "local_file" "public_key" {
  for_each = tls_private_key.cluster
  content  = each.value.public_key_openssh
  filename = pathexpand([for vm in local.flat_vms : vm.public_key if vm.group == each.key][0])
}

resource "libvirt_volume" "vm" {
  for_each = local.flat_vms
  name     = "${each.key}.qcow2"
  pool     = each.value.storage.pool
  capacity = each.value.storage.capacity
  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path   = pathexpand(var.cloud_images[each.value.os])
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "vm" {
  for_each = local.flat_vms
  name     = "${each.key}-init"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.key
  })

  user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
    hostname    = each.key
    ssh_pub_key = [tls_private_key.cluster[each.value.group].public_key_openssh]
  })

  network_config = templatefile("${path.module}/templates/network-config.tftpl", {
    ip          = [each.value.ip]
    mac         = each.value.mac
    gateway     = each.value.network.gateway
    search      = each.value.network.search
    dns_servers = each.value.network.dns_servers
  })
}

resource "libvirt_volume" "cloudinit" {
  for_each = local.flat_vms
  name     = "${each.key}-cloudinit.iso"
  pool     = "cloudinit"

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm[each.key].path
    }
  }
}

resource "libvirt_domain" "node" {
  for_each    = local.flat_vms
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
            file = libvirt_volume.vm[each.key].path
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
            network = each.value.network.libvirt_network
          }
        }
      }
    ]
  }
}
