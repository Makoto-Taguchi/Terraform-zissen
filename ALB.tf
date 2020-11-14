resource "aws_lb" "example" {
  name                = "example"
  load_balancer_type  = "application"
  # インターネット向けのALBなのでfalse
  internal            = false
  # 60秒でタイムアウト（デフォルトと同じ）
  idle_timeout        = 60
  # 削除保護を有効化
  # enable_deletion_protection  = true

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
    module.nginx_sg.security_group_id,
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

# ターゲットグループの定義（ALBがリクエストをフォワードする対象）：ECSと関連づける
resource "aws_lb_target_group" "targetgroup_for_ecs" {
  name        = "terraform-targetgroup-for-ecs"
  # ターゲットタイプ：ipはECS Fargateを示す
  target_type = "ip"
  # 以下3行でルーティング先指定
  vpc_id      = aws_vpc.example.id
  port        = 80
  protocol    = "HTTP"
  # ターゲット登録解除前にALBが待機する時間
  deregistration_delay  = 300

  # ヘルスチェック
  health_check {
    path        = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout     = 5
    interval    = 30
    matcher     = 200
    port        = "traffic-port"
    protocol    = "HTTP"
  }

  # 依存関係を明示
  depends_on    = [aws_lb.example]
}

# リスナールール
resource "aws_lb_listener_rule" "listerner_rule" {
  listener_arn = aws_lb_listener.https.arn
  # ルールの優先順位（値が小さいほど高い）
  priority     = 100

  # フォワード先のターゲットグループを設定
  action {
    type  = "forward"
    target_group_arn = aws_lb_target_group.targetgroup_for_ecs.arn
  }

  condition {
    # field = "path-pattern"
    # value = ["/*"]
    path_pattern {
      values = ["/*"]
    }
  }

}