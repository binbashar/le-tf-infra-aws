locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  users = [
    "angelo.fenoglio",
    "diego.ojeda",
    "exequiel.barrirero",
    "jose.peinado",
    "luis.gallardo",
    "marcelo.beresvil",
    "marcos.pagnucco"
  ]
}
