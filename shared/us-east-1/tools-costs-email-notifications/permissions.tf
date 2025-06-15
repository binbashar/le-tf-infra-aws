resource "aws_lambda_permission" "lambda_invoke_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monthly_services_usage.arn
  principal     = "events.amazonaws.com"
}