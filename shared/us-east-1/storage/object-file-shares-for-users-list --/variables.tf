#=================#
# Layer Variables #
#=================#
variable "prefix" {
  type        = string
  description = "A prefix string to name resources. Eg ofs (object file shares)"
  default     = "ofs"
}

variable "usernames" {
  type        = list(string)
  description = "Users List: new users can be onboarded by adding entries to this list."
  default = [
    "jane.doe",
    "john.doe",
    #EOL#
  ]
}
