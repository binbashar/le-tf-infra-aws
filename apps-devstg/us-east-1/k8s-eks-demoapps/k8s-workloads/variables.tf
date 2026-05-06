#=============================#
# Layer Flags                 #
#=============================#
variable "demo_apps" {
  description = "Per-app toggles for the demo workloads deployed by this layer. Disable an app to remove its resources on the next apply."
  type = object({
    echo_server = object({
      enabled = bool
    })
    google_microservices_dev = object({
      enabled = bool
    })
    emojivoto = object({
      enabled = bool
    })
  })
}
