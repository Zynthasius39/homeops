clusters = {
  k8s = {
    vms = {
      "eclair-0" = { os = "debian13", ip = "10.0.16.11/20", mac = "52:54:00:0a:10:0b", memory = 4096, vcpu = 2}
      "eclair-1" = { os = "debian13", ip = "10.0.16.12/20", mac = "52:54:00:0a:10:0c", memory = 8192, vcpu = 4}
      "eclair-2" = { os = "debian13", ip = "10.0.16.13/20", mac = "52:54:00:0a:10:0d", memory = 8192, vcpu = 4}
    }

    private_key = "~/.ssh/keys/k8s-eclair.pem"
    public_key  = "~/.ssh/keys/k8s-eclair.pub"

    storage = {
      pool     = "main"
      capacity = 10737418240  # 10GB
    }

    network = {
      gateway = "10.0.16.1"
      search = ["alak"]
      dns_servers = ["10.0.16.1"]
      libvirt_network = "ovs.20"
    }
  }
}
