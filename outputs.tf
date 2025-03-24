output "invoke_url" {
  value = trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
}

output "aws_caller_identity_arn" {
  value = data.aws_caller_identity.current.arn
}

output "aws_caller_identity_id" {
  value = data.aws_caller_identity.current.account_id
}


output "name_orefix" {
  value = local.name_prefix
}