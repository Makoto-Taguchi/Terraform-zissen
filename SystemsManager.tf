# Session Manager用のSSM Document
resource "aws_ssm_document" "session_manager_run_shell" {
  # nameは任意だが、下記だとCLIでオプション省略できる
  name            = "SSM-SessionManagerRunShell"

  # ドキュメントタイプ、フォーマット
  document_type   = "Session"
  document_format = "JSON"

  # ドキュメント：ログ保存先のS3とCloudWatch Logsを指定
  content =<<EOF
  {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "${aws_s3_bucket.operation_log.id}",
      "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation_log.name}"
    }
  }
  EOF
}