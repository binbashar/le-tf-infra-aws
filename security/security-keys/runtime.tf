
locals {
 # ===========================================
 # STANDARD TAGS FOR ALL RESOURCES IN THIS LAYER
 # -------------------------------------------
 # Purpose: Provide a consistent tagging baseline across resources
 # created by this module. These are merged with per-resource tags
 # when applicable.
 # ===========================================
 tags = {
   Terraform   = "true"
   Environment = var.environment
   Layer       = "security-keys"
 } 


 # ===========================================
 # RUNTIME DEPENDENCY INJECTION: AWS REGIONS
 # -------------------------------------------
 # Purpose: Define the primary and secondary regions for the account
 # ===========================================
  
}
