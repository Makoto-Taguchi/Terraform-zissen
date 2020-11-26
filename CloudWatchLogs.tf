# ECSで使用するFargateのロギング
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/ECSLogGroup"
  # ログの保持期間
  retention_in_days = 180
}

# バッチ用
resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/ecs-scheduled-tasks/ECSScheduleTask-LogGroup"
  retention_in_days = 180
}

# Session Managerの操作ログ保存先
resource "aws_cloudwatch_log_group" "operation_log" {
  name              = "/operation"
  retention_in_days = 180
}

# CloudWatch Logs用のIAMロール作成
# ポリシードキュメント
data "aws_iam_policy_document" "cloudwatch_logs" {
  # Kinesis Data Firehose操作権限
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:ap-northeast-1:*:*"]
  }

  # PassRole権限
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/cloudwatch-logs"]
  }
}

# IAMロール（上記のポリシードキュメントをCloudWatch Logsに紐付け）
module "cloudwatch_logs_role" {
  source      = "./iam_role"
  name        = "cloudwatch-logs"
  identifier  = "logs.ap-northeast-1.amazonaws.com"
  policy      = data.aws_iam_policy_document.cloudwatch_logs.json
}

# CloudWatch Logsサブスクリプションフィルタ
resource "aws_cloudwatch_log_subscription_filter" "cloudwatchlogs_subscription_filter" {
  name            = "my-subscription-filter"
  # 関連づけるロググループ名を指定 : バッチ用のCloudWatch Logs
  log_group_name  = aws_cloudwatch_log_group.for_ecs_scheduled_tasks.name
  # ログの送信先 : Kinesis配信ストリーム
  destination_arn = aws_kinesis_firehose_delivery_stream.kinesis_delivery_stream.arn
  # Kinesisに流すデータのフィルタリング : 全て送る
  filter_pattern  = "[]"
  # 上記で作成したIAMロールモジュール適用
  role_arn        = module.cloudwatch_logs_role.iam_role_arn
}