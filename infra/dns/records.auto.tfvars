records = [

# --------------------------------
# home.alak
# --------------------------------
{
  zone   = "home.alak."
  type   = "A"
  values = ["10.0.50.23"]
},
{
  zone   = "home.alak."
  name   = "_acme-challenge"
  type   = "CNAME"
  values = ["home.alak."]
},
{
  zone   = "home.alak."
  name   = "whoami.dost"
  type   = "CNAME"
  values = ["home.alak."]
},
{
  zone   = "home.alak."
  name   = "status"
  type   = "CNAME"
  values = ["home.alak."]
},
{
  zone   = "home.alak."
  name   = "ups"
  type   = "A"
  values = ["10.0.50.99"]
},
{
  zone   = "home.alak."
  name   = "ca"
  type   = "A"
  values = ["10.0.50.100"]
},

# --------------------------------
# servers.alak
# --------------------------------
{
  zone   = "servers.alak."
  name   = "nextcloud"
  type   = "A"
  values = ["10.0.50.24"]
},
{
  zone   = "servers.alak."
  name   = "jellyfin"
  type   = "A"
  values = ["10.0.50.41"]
},
{
  zone   = "servers.alak."
  name   = "jellyseerr"
  type   = "A"
  values = ["10.0.50.42"]
},
{
  zone   = "servers.alak."
  name   = "deluge"
  type   = "A"
  values = ["10.0.50.48"]
},

# --------------------------------
# naquadah.alak
# --------------------------------

{
  zone   = "naquadah.alak."
  type   = "A"
  values = ["10.0.20.1"]
},
{
  zone   = "naquadah.alak."
  name   = "gopher"
  type   = "CNAME"
  values = ["naquadah.alak."]
},
{
  zone   = "naquadah.alak."
  name   = "dev.gopher"
  type   = "CNAME"
  values = ["naquadah.alak."]
},
{
  zone   = "naquadah.alak."
  name   = "argocd"
  type   = "A"
  values = ["10.0.20.2"]
},

]
