locals {
  tags = {
    Terraform    = "true"
    Environment  = var.environment
    Layer        = local.layer_name
    "aws-apn-id" = local.prm_apn_id
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
}
