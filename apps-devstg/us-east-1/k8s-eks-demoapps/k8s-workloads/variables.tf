#=============================#
# Layer Flags                 #
#=============================#
# Source CIDRs allowed to reach echo-server's public hostname, enforced in
# Envoy by a SecurityPolicy attached to its HTTPRoute.
#
# Per-app rather than shared from the platform layer, deliberately: this is the
# translation of a per-Ingress `whitelist-source-range` annotation, where the
# value belongs to the application and differs between them. The public
# gateway's own perimeter allowlist is a separate list living in k8s-components,
# and the two are only equal by coincidence while there is one operator.
#
# Not set in the versioned tfvars — the list is made of operators' home/office
# addresses. Populate `allowlist.local.auto.tfvars`, which OpenTofu auto-loads
# and .gitignore excludes; copy the .example next to it to get started.
#
# An empty list means "no restriction": the SecurityPolicy is not created and
# the hostname is reachable by anyone the perimeter admits. That is the
# behaviour an application with no annotation has today, so it is the honest
# default -- but it is a *silent* one, which is why enabling it is opt-in
# through `echo_server.restrict_public_access` rather than inferred from the
# list being non-empty.
variable "echo_server_public_allowed_cidrs" {
  description = "CIDRs permitted to reach echo-server's public hostname. Enforced by an Envoy SecurityPolicy on its HTTPRoute."
  type        = list(string)
  default     = []
}

variable "demo_apps" {
  description = "Per-app toggles for the demo workloads deployed by this layer. Disable an app to remove its resources on the next apply."
  type = object({
    echo_server = object({
      enabled = bool
      # Publishes echo-server.binbash.com.ar through the public Envoy Gateway
      # and labels its namespace so the gateway's HTTPS listener accepts the
      # attachment. Requires `envoy_gateway.public_gateway.enabled = true` in
      # the k8s-components layer.
      public_endpoint = bool
      # Restricts the public hostname to `echo_server_public_allowed_cidrs`,
      # enforced in Envoy rather than at the load balancer. This is the
      # per-application filtering an nginx `whitelist-source-range` annotation
      # does; leaving it false is the "open to the internet" case.
      restrict_public_access = bool
    })
    google_microservices_dev = object({
      enabled = bool
    })
    emojivoto = object({
      enabled = bool
    })
  })
}
