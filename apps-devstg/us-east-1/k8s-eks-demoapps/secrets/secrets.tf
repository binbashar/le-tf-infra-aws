module "secrets" {
  source = "github.com/binbashar/terraform-aws-secrets-manager.git?ref=0.13.0"

  # `["AWSCURRENT"]` is what the provider defaults to, so this changes nothing
  # about the secret — it is here to route around a bug in this pin. The
  # module's variable defaults to `null` and validates it with
  # `var.version_stages == null || alltrue([for stage in var.version_stages …])`.
  # HCL evaluates both operands of `||` rather than short-circuiting, so the
  # `for` runs against the null and `tofu validate` fails before the layer can
  # be planned at all. Upstream fixed it with `coalesce()` in a later tag, but
  # that tag also raises the floor to OpenTofu >= 1.11 and AWS provider >= 5.0,
  # which this layer does not meet (`~> 1.3` / `~> 4.10` in config.tf). Passing
  # the value explicitly is the documented usage and keeps the bump a separate
  # decision.
  version_stages = ["AWSCURRENT"]

  secrets = {
    # Consumed by the `demo-google-microservices` workload, whose kustomize base
    # ships an `ExternalSecret` that reads this secret with `dataFrom.extract`
    # and projects it into the `app-secrets` Kubernetes Secret;
    # `paymentservice` then reads the `TEST_SECRET` key from it through a
    # `secretKeyRef` with no `optional`, so the pod does not start if this is
    # missing or unreadable.
    #
    # **It has to be a JSON object.** `extract` unmarshals the secret string
    # into a map and turns every key into a key of the Kubernetes Secret; a
    # bare string fails with `unable to unmarshal secret`, which surfaces as
    # the ExternalSecret stuck in `SecretSyncedError` and the workload stuck in
    # `CreateContainerConfigError` — two layers away from the cause. The value
    # here is a placeholder by design: what is being demonstrated is the path
    # Secrets Manager -> IRSA -> ESO -> pod, not the secrecy of the payload.
    "/k8s-eks-demoapps/test-secrets" = {
      description             = "DemoApps SecretManager Test Secret"
      recovery_window_in_days = 7
      secret_string           = jsonencode({ TEST_SECRET = "placeholder" })
      kms_key_id              = data.terraform_remote_state.keys.outputs.aws_kms_key_id
    },
  }

  tags = local.tags

}

# Set secrets policies
data "aws_iam_policy_document" "secret_policy" {
  statement {
    sid       = "GetSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.accounts.apps-devstg.id}:role/DevOps",
        "arn:aws:iam::${var.accounts.management.id}:role/OrganizationAccountAccessRole"
      ]

    }
  }
}

resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  for_each   = module.secrets.secret_arns
  secret_arn = each.value
  policy     = data.aws_iam_policy_document.secret_policy.json
}
