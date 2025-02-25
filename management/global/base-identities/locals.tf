locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  users = [
    "angelo.fenoglio",
    "diego.ojeda",
    "emiliano.brest",
    "exequiel.barrirero",
    "jose.peinado",
    "luis.gallardo",
    "marcelo.beresvil",
    "marcos.pagnucco",
    "matias.rodriguez"
  ]
}
