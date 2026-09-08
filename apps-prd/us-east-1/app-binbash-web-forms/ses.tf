#
# SANDBOX ONLY. In the SES sandbox every recipient must itself be a verified
# identity, so mail to the hiring inbox is rejected until someone with access to
# it clicks the link AWS sends on apply.
#
# Terraform creates the identity and then reports success — verification is a
# human step it cannot perform or wait for. Check with:
#   aws ses get-identity-verification-attributes --identities people@binbash.com.ar
#
# Gated rather than unconditional: once production access is granted this
# resource is pure noise, and var.ses_sandbox flipping to false removes it.
resource "aws_ses_email_identity" "careers_recipient" {
  count = var.ses_sandbox ? 1 : 0
  email = var.careers_recipient
}
