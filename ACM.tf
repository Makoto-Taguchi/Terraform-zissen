resource "aws_acm_certificate" "acm_cert" {
  # ドメイン名
  domain_name               = aws_route53_record.dns_record.name
  # サブドメイン（追加しないので空欄）
  subject_alternative_names = ["*.terraformtest.work"]
  # ドメイン所有権の検証方法：DNS検証を指定（SSL証明書が自動更新される）
  validation_method         = "DNS"

  lifecycle {
    # 新しい証明書を作ってから古い証明書と差し替える
    create_before_destroy = true
  }
}