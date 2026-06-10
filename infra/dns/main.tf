resource "dns_a_record_set" "this" {
  for_each = local.by_type["A"]

  zone      = each.value.zone
  name      = each.value.name
  addresses = each.value.values
  ttl       = each.value.ttl
}

resource "dns_aaaa_record_set" "this" {
  for_each = local.by_type["AAAA"]

  zone      = each.value.zone
  name      = each.value.name
  addresses = each.value.values
  ttl       = each.value.ttl
}

resource "dns_cname_record" "this" {
  for_each = local.by_type["CNAME"]

  zone  = each.value.zone
  name  = each.value.name
  cname = each.value.values[0]
  ttl   = each.value.ttl
}

resource "dns_mx_record_set" "this" {
  for_each = local.by_type["MX"]

  zone = each.value.zone
  name = each.value.name
  ttl  = each.value.ttl

  dynamic "mx" {
    for_each = each.value.mx_entries
    content {
      preference = mx.value.preference
      exchange   = mx.value.exchange
    }
  }
}

resource "dns_ns_record_set" "this" {
  for_each = local.by_type["NS"]

  zone        = each.value.zone
  name        = each.value.name
  nameservers = each.value.values
  ttl         = each.value.ttl
}

resource "dns_txt_record_set" "this" {
  for_each = local.by_type["TXT"]

  zone = each.value.zone
  name = each.value.name
  txt  = each.value.values
  ttl  = each.value.ttl
}

resource "dns_ptr_record" "this" {
  for_each = local.by_type["PTR"]

  zone = each.value.zone
  name = each.value.name
  ptr  = each.value.values[0]
  ttl  = each.value.ttl
}

resource "dns_srv_record_set" "this" {
  for_each = local.by_type["SRV"]

  zone = each.value.zone
  name = each.value.name
  ttl  = each.value.ttl

  dynamic "srv" {
    for_each = each.value.srv_entries
    content {
      priority = srv.value.priority
      weight   = srv.value.weight
      port     = srv.value.port
      target   = srv.value.target
    }
  }
}
