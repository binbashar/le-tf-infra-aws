output "runners" {
  value = {
    lambda_syncer_name = module.github_selfhosted_runners.binaries_syncer.lambda.function_name
  }
}

output "webhook" {
  value = {
    endpoint = module.github_selfhosted_runners.webhook.endpoint
  }
}
