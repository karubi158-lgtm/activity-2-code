
data "aws_route53_zone" "main" {
  count = var.route53_domain_name == "" ? 0 : 1

  name         = "${trimsuffix(var.route53_domain_name, ".")}."
  private_zone = false
}

resource "aws_route53_health_check" "mumbai" {
  count = var.route53_domain_name == "" ? 0 : 1

  fqdn              = module.mumbai_app.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-mumbai-health"
  }
}

resource "aws_route53_health_check" "singapore" {
  count = var.route53_domain_name == "" ? 0 : 1

  fqdn              = module.singapore_app.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-singapore-health"
  }
}

resource "aws_route53_record" "mumbai" {
  count = var.route53_domain_name == "" ? 0 : 1

  zone_id        = data.aws_route53_zone.main[0].zone_id
  name           = "app.${trimsuffix(var.route53_domain_name, ".")}"
  type           = "A"
  set_identifier = "Mumbai-Primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = module.mumbai_app.alb_dns_name
    zone_id                = module.mumbai_app.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.mumbai[0].id
}

resource "aws_route53_record" "singapore" {
  count = var.route53_domain_name == "" ? 0 : 1

  zone_id        = data.aws_route53_zone.main[0].zone_id
  name           = "app.${trimsuffix(var.route53_domain_name, ".")}"
  type           = "A"
  set_identifier = "Singapore-Secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = module.singapore_app.alb_dns_name
    zone_id                = module.singapore_app.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.singapore[0].id
}
