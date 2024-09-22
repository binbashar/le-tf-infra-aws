mock_provider "aws" {}
variables {
    kms_key_name = "test-kms"
    project = "bb"
    environment = "test"
    region = "us-east-1"
}

run "valid_key_alias_name" {
    assert {
        condition = module.kms_key.alias_name == "alias/bb_test_test-kms_key"
        error_message = "The KMS key alias name is not correct"
    }
}


