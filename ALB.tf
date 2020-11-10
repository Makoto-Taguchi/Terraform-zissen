resource "aws_lb" "example" {
  name                = "example"
  load_balancer_type  = "application"
  # インターネット向けのALBなのでfalse
  internal            = false
  # 60秒でタイムアウト（デフォルトと同じ）
  idle_timeout        = 60
  # 削除保護を有効化
  enable_deletion_protection  = true

  # ALBが所属するサブネット → 複数のAZを指定してクロスゾーン不可分散
  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  # 指定したS3バケットにアクセスログを保存
  access_logs {
    bucket =  aws_s3_bucket.alb_log.id
    enabled = true
  }

  # セキュリティグループはモジュール化して指定
  # HTTP, HTTPS, HTTPのリダイレクトの３つ
  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}

# リスナー（どのポートのリクエストを受け付けるか）の設定
# HTTPリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          ="HTTP"

  # デフォルトアクション（リスナーが設定したルールに合致しない場合のアクション）
  default_action {
    type = "fixed-response"

    # 固定のHTTPレスポンスを応答するアクション
    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = "200"
    }
  }
}

# HTTPSリスナー
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"

  # ACMで作成したSSL証明書を指定
  certificate_arn   = aws_acm_certificate.acm_cert.arn
  # セキュリティポリシー：下記が推奨
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTPS」です"
      status_code  = "200"
    }
  }
}

# HTTPからHTTPSにリダイレクトするリスナー
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type= "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}