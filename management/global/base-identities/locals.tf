locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
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
