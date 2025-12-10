# Import blocks for existing security-base resources
# These imports are based on the plan.txt output showing resources to be created

# ===========================================
# EBS ENCRYPTION BY DEFAULT RESOURCES
# ===========================================

# Apps Dev/Staging Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["apps-devstg-us-east-1"]
  id = "523857393444"
}

# Apps Dev/Staging Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["apps-devstg-us-east-2"]
  id = "523857393444"
}

# Apps Production Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["apps-prd-us-east-1"]
  id = "802787198489"
}

# Apps Production Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["apps-prd-us-east-2"]
  id = "802787198489"
}

# Data Science Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["data-science-us-east-1"]
  id = "905418344519"
}

# Data Science Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["data-science-us-east-2"]
  id = "905418344519"
}

# Management Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["management-us-east-1"]
  id = "754065527950"
}

# Management Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["management-us-east-2"]
  id = "754065527950"
}

# Network Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["network-us-east-1"]
  id = "822280187662"
}

# Network Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["network-us-east-2"]
  id = "822280187662"
}

# Security Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["security-us-east-1"]
  id = "900980591242"
}

# Security Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["security-us-east-2"]
  id = "900980591242"
}

# Shared Account - US-East-1
import {
  to = aws_ebs_encryption_by_default.main["shared-us-east-1"]
  id = "763606934258"
}

# Shared Account - US-East-2
import {
  to = aws_ebs_encryption_by_default.main["shared-us-east-2"]
  id = "763606934258"
}

# ===========================================
# S3 ACCOUNT PUBLIC ACCESS BLOCK RESOURCES
# ===========================================

# Apps Dev/Staging Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["apps-devstg-us-east-1"]
  id = "523857393444"
}

# Apps Dev/Staging Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["apps-devstg-us-east-2"]
  id = "523857393444"
}

# Apps Production Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["apps-prd-us-east-1"]
  id = "802787198489"
}

# Apps Production Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["apps-prd-us-east-2"]
  id = "802787198489"
}

# Data Science Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["data-science-us-east-1"]
  id = "905418344519"
}

# Data Science Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["data-science-us-east-2"]
  id = "905418344519"
}

# Management Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["management-us-east-1"]
  id = "754065527950"
}

# Management Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["management-us-east-2"]
  id = "754065527950"
}

# Network Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["network-us-east-1"]
  id = "822280187662"
}

# Network Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["network-us-east-2"]
  id = "822280187662"
}

# Security Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["security-us-east-1"]
  id = "900980591242"
}

# Security Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["security-us-east-2"]
  id = "900980591242"
}

# Shared Account - US-East-1
import {
  to = aws_s3_account_public_access_block.main["shared-us-east-1"]
  id = "763606934258"
}

# Shared Account - US-East-2
import {
  to = aws_s3_account_public_access_block.main["shared-us-east-2"]
  id = "763606934258"
}
