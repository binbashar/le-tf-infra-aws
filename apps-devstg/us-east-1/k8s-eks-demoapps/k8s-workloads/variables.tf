#=============================#
# Layer Flags                 #
#=============================#
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
    })
    google_microservices_dev = object({
      enabled = bool
    })
    emojivoto = object({
      enabled = bool
    })
  })
}
