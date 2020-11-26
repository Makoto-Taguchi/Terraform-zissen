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