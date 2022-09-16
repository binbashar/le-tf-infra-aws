output "registry_url" {
    description = "ECR registry URL"
    value       = values(module.ecr_repositories)[0]["registry_url"]#split("/", values(module.ecr_repositories)[0]["repository_url"])[0]
}
