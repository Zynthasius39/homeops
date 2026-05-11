variable "bind" {
  type = object({
    server             = string
    tsig_key_name      = string
    tsig_key_algorithm = string
    tsig_key_secret    = string
    port               = optional(number, 53)
    transport          = optional(string, "tcp")
  })
  sensitive = true
}

variable "records" {
  type = list(object({
    zone   = string
    type   = string
    name   = optional(string, null)
    ttl    = optional(number, 300)
    values = optional(list(string), [])

    mx_entries = optional(list(object({
      preference = number
      exchange   = string
    })), [])

    srv_entries = optional(list(object({
      priority = number
      weight   = number
      port     = number
      target   = string
    })), [])
  }))

  validation {
    condition = alltrue([
      for r in var.records :
      contains(["A", "AAAA", "CNAME", "MX", "TXT", "PTR", "SRV"], r.type)
    ])
    error_message = "Each record 'type' must be one of: A, AAAA, CNAME, MX, TXT, PTR, SRV."
  }

  validation {
    condition = alltrue([
      for r in var.records :
      endswith(r.zone, ".")
    ])
    error_message = "Each 'zone' must end with a trailing dot, e.g. 'example.com.'."
  }
}

locals {
  by_type = {
    A     = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "A" }
    AAAA  = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "AAAA" }
    CNAME = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "CNAME" }
    MX    = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "MX" }
    TXT   = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "TXT" }
    PTR   = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "PTR" }
    SRV   = { for r in var.records : "${r.zone}__${r.name != null ? r.name : "."}" => r if r.type == "SRV" }
  }
}
