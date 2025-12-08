locals {
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Layer       = local.layer_name
  }

  users = [
    "angelo.fenoglio",
    "diego.ojeda",
    "exequiel.barrirero",
    "jose.peinado",
    "luis.gallardo",
    "marcelo.beresvil",
    "marcos.pagnucco",
    "matias.rodriguez",
    "franco.gauchat",
  ]

  machine_users = {
    # These machine users are managed by us, the DevOps/Infra team. For these
    # we don't really need to create separate GPG keys per user because we will
    # be ones decrypting the encrypted secret access key. So, a single key
    # should suffice and simplify the process.
    # Please continue reading the comment below.
    "machine.circle.ci"      = "machine.circle.ci"
    "machine.github.actions" = "machine.github.actions"
    "machine.s3.demo"        = "machine.s3.demo"

    # The machine users below follow the approach suggested by the comment
    # above and so they start using one key for all machine users.
    # Note: once all existing machine users have been migrated to this new
    # approach, the code will need to be simplified and cleaned up.
    "machine.atlantis" = "machine.infra"
  }
}
