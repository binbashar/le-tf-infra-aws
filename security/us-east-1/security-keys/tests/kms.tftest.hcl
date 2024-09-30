variables {
  kms_key_name        = "test-kms"
  environment         = "test"
  enable_remote_state = true
}

run "valid_key_alias_name" {
  assert {
    condition     = module.kms_key.alias_name == "alias/bb_test_test-kms_key"
    error_message = "The KMS key alias name is not correct"
  }
}
