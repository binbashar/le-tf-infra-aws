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
    "marcos.pagnucco",
    "matias.rodriguez"
  ]

  machine_users = [
    "machine.circle.ci",
    "machine.github.actions",
    "machine.s3.demo"
  ]
}
