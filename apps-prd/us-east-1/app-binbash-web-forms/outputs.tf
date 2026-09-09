output "careers_form_endpoint" {
  description = "The URL the binbash-web careers form posts to. Hardcoded in that app's lib/forms.ts — changing it is a breaking change on both sides."
  value       = "https://${local.forms_fqdn}/careers-application"
}

output "careers_application_function_name" {
  description = "Lambda function name, for log tailing: aws logs tail /aws/lambda/<name> --follow"
  value       = aws_lambda_function.careers_application.function_name
}

output "api_endpoint" {
  description = "The API's own execute-api URL, useful for testing before DNS propagates"
  value       = aws_apigatewayv2_api.forms.api_endpoint
}
