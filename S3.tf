# プライベートバケットの定義
resource "aws_s3_bucket" "private" {
  # バケット名
  bucket = "private-for-terraform-20201028"

  # バージョニング有効化
  versioning {
    enabled = true
  }

  # 暗号化を有効(SSE-S3によるデフォルト暗号化)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# ブロックパブリックアクセス（予期しないオブジェクトの公開防止）
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true  #aclで許可していても非公開にする
  restrict_public_buckets = true  #policyで許可していても非公開にする
}

# パブリックバケットの定義
resource "aws_s3_bucket" "public" {
  bucket = "public-for-terraform-20201028"
  acl    = "public-read"  #インターネットからの読み込み許可

  # Cross-Origin Resource Sharing
  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# ALBアクセスログ用のバケット定義
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-for-terraform-20201028"

  # 60日経過したファイルを自動的に削除
  lifecycle_rule {
    enabled = true
    expiration {
      days = "60"
    }
  }
}

# バケットポリシーの定義（他のAWSサービスからバケットへのアクセス権限）
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# ポリシードキュメント
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect          = "Allow"
    actions         = ["s3:PutObject"]
    resources       = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type          = "AWS"
      # S3へ書き込むリソースID（東京リージョンのALBのアカウントIDを指定）
      identifiers   =["582318560864"]
    }
  }
}