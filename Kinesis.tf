# Kinesis Data Firehose用のIAMロール作成
# ポリシードキュメント:S3の操作権限を付与
data "aws_iam_policy_document" "kinesis_data_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}/*",
    ]
  }
}

# IAMロール（上記のポリシードキュメントをKinesisに紐づけ）
module "kinesis_data_firehose_role" {
  source      = "./iam_role"
  name        = "kinesis-data-firehose"
  identifier  = "firehose.amazonaws.com"
  policy      = data.aws_iam_policy_document.kinesis_data_firehose.json
}

# Kinesis Data Firehose配信ストリーム
resource "aws_kinesis_firehose_delivery_stream" "kinesis_delivery_stream" {
  name        = "my_kinesis_delivery_stream"
  destination = "s3"

  s3_configuration {
    # 上記で作成したIAMロールモジュール適用
    role_arn   = module.kinesis_data_firehose_role.iam_role_arn
    # 配信先のS3ログバケット指定
    bucket_arn = aws_s3_bucket.cloudwatch_logs.arn
    prefix     = "ecs-scheduled-tasks/ECSScheduleTask-LogGroup/"
  }
}