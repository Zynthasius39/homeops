clusters = {
  docker = {
    vms = {
      duranium-0 = {
        ip     = "10.0.16.21/20"
        mac    = "52:54:00:0a:10:15"
        vcpu   = 4
        memory = 4096
        os     = "almalinux10"
      }
    }

    private_key = "~/.ssh/keys/docker-duranium.pem"
    public_key  = "~/.ssh/keys/docker-duranium.pub"

    storage = {
      pool     = "main"
      capacity = 10737418240  # 10GB
    }

    network = {
      gateway         = "10.0.16.1"
      libvirt_network = "ovs.20"
      search          = ["alak"]
      dns_servers     = ["10.0.16.1"]
    }
  }
  k8s = {
    vms = {
      "naquadah-0" = { os = "almalinux10", ip = "10.0.16.16/20", mac = "52:54:00:0a:10:10", memory = 4096, vcpu = 2}
      "naquadah-1" = { os = "almalinux10", ip = "10.0.16.17/20", mac = "52:54:00:0a:10:11", memory = 8192, vcpu = 4}
      "naquadah-2" = { os = "almalinux10", ip = "10.0.16.18/20", mac = "52:54:00:0a:10:12", memory = 8192, vcpu = 4}
    }

    private_key = "~/.ssh/keys/k8s-naquadah.pem"
    public_key  = "~/.ssh/keys/k8s-naquadah.pub"

    storage = {
      pool     = "main"
      capacity = 10737418240  # 10GB
    }

    network = {
      gateway         = "10.0.16.1"
      libvirt_network = "ovs.20"
      search          = ["alak"]
      dns_servers     = ["10.0.16.1"]
    }
  }
}

