# ホストゾーンの参照
data "aws_route53_zone" "example" {
  name = "terraformtest.work"
}

# ホストゾーンの作成
resource "aws_route53_zone" "test_example" {
  name = "test.terraformtest.work"
}

# DNSレコードの定義
resource "aws_route53_record" "example" {
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
  value = aws_route53_record.example.name
}