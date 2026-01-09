variable "clients" {
  type = map(object({
    sftp_info       = map(any)
    bucket_settings = map(any)
    sites           = map(any)
  }))
  description = "Clients List: new sites, robots and sftp accounts can be onboarded by adding entries to this list."
}
