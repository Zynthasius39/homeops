clusters = {
  k8s = {
    vms = {
      "naquadah-0" = { os = "almalinux10", ip = "192.168.100.16/24", mac = "52:54:00:0a:10:10", memory = 2048, vcpu = 2}
      "naquadah-1" = { os = "almalinux10", ip = "192.168.100.17/24", mac = "52:54:00:0a:10:11", memory = 4096, vcpu = 4}
      "naquadah-2" = { os = "almalinux10", ip = "192.168.100.18/24", mac = "52:54:00:0a:10:12", memory = 4096, vcpu = 4}
    }

    private_key = "~/.ssh/keys/k8s-naquadah-tuf.pem"
    public_key  = "~/.ssh/keys/k8s-naquadah-tuf.pub"

    storage = {
      pool     = "pool"
      capacity = 10737418240  # 10GB
    }

    network = {
      gateway         = "192.168.100.1"
      libvirt_network = "k3s"
      search          = ["alak"]
      dns_servers     = ["192.168.100.1"]
    }
  }
}

