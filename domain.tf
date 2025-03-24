
# this is just to allow the use of
# https://joseph03.sctp-sandbox.com

data "aws_route53_zone" "zone" {
  name = "sctp-sandbox.com"
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name       = "${local.name_prefix}.sctp-sandbox.com"
  zone_id           = data.aws_route53_zone.zone.zone_id
  validation_method = "DNS"
}

resource "aws_apigatewayv2_api_mapping" "http_api" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.http_api.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_apigatewayv2_domain_name" "http_api" {
  domain_name = "${local.name_prefix}.sctp-sandbox.com"
  // make sure that the value of ${local.name_prefix}
  // does not have '_' else ACM will reject and causes error.

  domain_name_configuration {
    certificate_arn = module.acm.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "http_api" {
  name    = local.name_prefix
  type    = "A"
  zone_id = data.aws_route53_zone.zone.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.http_api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.http_api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = true
  }
}