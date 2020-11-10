# ホストゾーンの参照
data "aws_route53_zone" "example" {
  name = "terraformtest.work"
}

# ホストゾーンの作成
resource "aws_route53_zone" "test_example" {
  name = "test.terraformtest.work"
}

# DNSレコードの定義
resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = data.aws_route53_zone.example.name
  # レコードタイプ ： ALIASレコードを使用する場合はAレコードを指定
  type    = "A"

  alias {
    # ALBのDNS名指定
    name    = aws_lb.example.dns_name
    # ALBのゾーンID指定
    zone_id = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.dns_record.name
}

# SSL証明書のDNS検証用レコード（version3.0より前）
/* resource "aws_route53_record" "terraformwork_certificate" {
  name    = aws_acm_certificate.acm_cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.acm_cert.domain_validation_options[0].resouce_record_type
    records = [aws_acm_certificate.acm_cert.domain_validation_options[0].resource_record_value]
  zone_id = data.aws_route53_zone.example.zone_id
  ttl     = 60
} */

# SSL証明書のDNS検証用レコード（version3.0以降）
resource "aws_route53_record" "terraformwork_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.example.zone_id
}

# これ設定でapply時にSSL証明書の検証が完了するまで待ってくれる
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  # validation_record_fqdns = [aws_route53_record.terraformwork_certificate.fqdn]
  validation_record_fqdns = [for record in aws_route53_record.terraformwork_certificate : record.fqdn]
}