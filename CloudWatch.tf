# CloudWatchイベントルール（ジョブの実行スケジュール）を定義
resource "aws_cloudwatch_event_rule" "batch_eventrule" {
  name        = "batch-EventRule"
  description = "とても重要なバッチ処理です"
  # スケジュール：cron式で記述
  schedule_expression = "cron(*/2 * * * ? *)"
}

# CloudWatchイベントターゲット（実行するジョブ）を定義
resource "aws_cloudwatch_event_target" "batch_eventtarget" {
  target_id = "batch-EventTarget"
  # イベントルール指定
  rule      = aws_cloudwatch_event_rule.batch_eventrule.name
  # IAMロール指定→ECSタスク起動可能に
  role_arn  = module.ecs_events_role.iam_role_arn
  # ターゲット：ECSクラスタ指定
  arn       = aws_ecs_cluster.ecs_cluster.arn

  # タスク実行時の設定
  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.batch_task.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.private_0.id]
    }
  }
}
