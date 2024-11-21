terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.20"
            configuration_aliases = [ aws, aws.shared ]
        }
    }
}
