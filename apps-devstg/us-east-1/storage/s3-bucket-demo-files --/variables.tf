#=================#
# Layer Variables #
#=================#
variable "prefix" {
  type    = string
  default = "cfs"
}

variable "customers" {
  type    = list(string)
  default = []
}
