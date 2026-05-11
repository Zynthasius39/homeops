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
    name   = "angie"
    type   = "CNAME"
    values = ["home.alak."]
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

]
