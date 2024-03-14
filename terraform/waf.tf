/*
resource "aws_waf_geo_match_set" "authorized_country" {
  provider = aws.cloudfront
  name     = "waf-authorized-country"

  # Add France
  geo_match_constraint {
    type  = "Country"
    value = "FR"
  }

  # Add Guadeloupe
  geo_match_constraint {
    type  = "Country"
    value = "GP"
  }

  # Add Martinique
  geo_match_constraint {
    type  = "Country"
    value = "MQ"
  }

  # Add Reunion
  geo_match_constraint {
    type  = "Country"
    value = "RE"
  }
}

resource "aws_waf_rule" "waf_rule_geo" {
  name        = "waf-rule-geo"
  provider    = aws.cloudfront
  metric_name = "WafRuleGeoMetric"

  # Allow good country (France)
  predicates {
    type    = "GeoMatch"
    data_id = aws_waf_geo_match_set.authorized_country.id
    negated = false
  }
}

resource "aws_waf_web_acl" "this" {
  provider    = aws.cloudfront
  depends_on  = [aws_waf_rule.waf_rule_geo]
  name        = "onlyAllowRequestsFromFR"
  metric_name = "onlyAllowRequestsFromFR"

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = aws_waf_rule.waf_rule_geo.id
    type     = "REGULAR"
  }
}
*/