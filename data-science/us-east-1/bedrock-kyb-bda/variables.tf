variable "kyb_extraction_schema" {
  description = "Bedrock Data Automation blueprint schema for KYB data extraction"
  type        = string
  default     = <<-EOF
  {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "description": "Documento que detalla la liquidación de remuneraciones de un empleado",
    "class": "Liquidación de remuneraciones",
    "type": "object",
    "definitions": {
        "CONTACTO": {
            "type": "object",
            "properties": {
                "Correo electrónico": {
                    "type": "string",
                    "inferenceType": "explicit",
                    "instruction": "Correo electrónico de contacto de la persona"
                },
                "Número de teléfono": {
                    "type": "string",
                    "inferenceType": "explicit",
                    "instruction": "Número de teléfono de contacto de la persona"
                }
            }
        },
        "Créditos y descuentos": {
            "type": "object",
            "properties": {
                "Concepto": {
                    "type": "string",
                    "inferenceType": "explicit",
                    "instruction": "Descripción del crédito o descuento aplicado. Requerido.\nEjemplo: FONASA"
                },
                "Monto": {
                    "type": "number",
                    "inferenceType": "inferred",
                    "instruction": "Monto del crédito o descuento. Requerido."
                },
                "Número de cuotas": {
                    "type": "number",
                    "inferenceType": "explicit",
                    "instruction": "Número de cuotas del crédito, si aplica"
                },
                "Plazo del crédito": {
                    "type": "number",
                    "inferenceType": "explicit",
                    "instruction": "Plazo del crédito en meses, si aplica"
                }
            }
        }
    },
    "properties": {
        "Nombre": {
            "type": "string",
            "inferenceType": "explicit",
            "instruction": "Nombre completo del empleado"
        },
        "Fecha liquidación": {
            "type": "string",
            "inferenceType": "explicit",
            "instruction": "Fecha en que se generó la liquidación de sueldo. Puede aparecer como 'Fecha liquidación', 'Periodo', 'Mes', 'Remuneraciones', 'Liquidación de sueldo', etc, seguido por la fecha. Formato esperado de salida: YYYY-MM. Ejemplos: 'Mayo 2025', 'Mes: Mayo 2025', 'Periodo: 05-2025' -> salida: '2025-05'"
        },
        "RUT": {
            "type": "string",
            "inferenceType": "explicit",
            "instruction": "Número de Rol Único Tributario del empleado"
        },
        "Sueldo bruto": {
            "type": "number",
            "inferenceType": "explicit",
            "instruction": "Monto total que la empresa debe pagar al empleado antes de descuentos. Normalmente es el monto que, al aplicarle los descuentos, se convierte en el sueldo liquido. Deberia ser el total de haberes."
        },
        "Sueldo líquido": {
            "type": "number",
            "inferenceType": "explicit",
            "instruction": "Monto que la empresa paga al empleado después de los descuentos legales relacionados con jubilación, salud, impuestos, etc. Ejemplos: Líquido a recibir, Total a pagar, etc."
        },
        "Nombre empleador": {
            "type": "string",
            "inferenceType": "explicit",
            "instruction": "Nombre de la empresa empleadora"
        },
        "RUT empleador": {
            "type": "string",
            "inferenceType": "explicit",
            "instruction": "Número de Rol Único Tributario de la empresa empleadora. Diferente al RUT del empleado. Normalmente, se encuentra cercano al Nombre empleador o a su dirección."
        },
        "Total Descuentos": {
            "type": "number",
            "inferenceType": "explicit",
            "instruction": "Suma total de los descuentos aplicados (si hubiere, y si está explicitamente calculado). Puede aparecer como: 'Total descuentos', etc."
        }
    }
  }
  EOF
}

variable "enable_encryption" {
  description = "Enable KMS encryption for BDA project"
  type        = bool
  default     = true
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 1024
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB."
  }
}

variable "s3_lifecycle_days" {
  description = "Days before transitioning objects to STANDARD_IA storage class"
  type        = number
  default     = 90
  validation {
    condition     = var.s3_lifecycle_days >= 30
    error_message = "s3_lifecycle_days must be >= 30 (AWS S3 Standard-IA minimum requirement)."
  }
}

variable "s3_glacier_days" {
  description = "Days before transitioning objects to GLACIER storage class"
  type        = number
  default     = 365
  validation {
    condition     = var.s3_glacier_days >= var.s3_lifecycle_days
    error_message = "s3_glacier_days must be greater than or equal to s3_lifecycle_days."
  }
}

variable "enable_s3_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "kyb_blueprint_version" {
  description = "Version of the KYB blueprint to use for data automation processing"
  type        = string
  default     = "1"
  validation {
    condition     = can(regex("^[0-9]+$", var.kyb_blueprint_version))
    error_message = "kyb_blueprint_version must be a valid numeric version string (e.g., '1', '2', '10')."
  }
}