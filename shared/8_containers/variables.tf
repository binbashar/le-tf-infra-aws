#
# AWS Provider Settings
#
variable "region" {
    description = "AWS Region"
}
variable "profile" {
    description = "AWS Profile"
}

#
# Accounts
#
variable "shared_account_id" {
    description = "Account: Shared Resources"
}
variable "dev_account_id" {
    description = "Account: Dev Modules & Libs"
}