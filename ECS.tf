# ECSクラスタ定義
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "terrarom_ecs_cluster"
}

# タスク（コンテナの実行単位）定義
resource "aws_ecs_task_definition" "ecs_task" {
  # ファミリ（タスク定義名のプレフィックス）
  family          = "terraform-ecs-task"
  # タスクサイズ（タスクが使用するリソースサイズ）
  cpu             = "256"
  memory          = "512"
  # 以下はFargateのときはawsvpc
  network_mode    = "awsvpc"
  # 起動タイプ
  requires_compatibilities = ["FARGATE"]
  # タスクで実行するコンテナ定義ファイルを指定
  container_definitions    = file("./container_definitions.json")
}

# ECSサービス定義 → 起動するタスク数の定義とタスクの維持
resource "aws_ecs_service" "ecs_service" {
  name            = "terraform-ecs-service"
  # クラスタ指定
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  # タスク指定
  task_definition = aws_ecs_task_definition.ecs_task.arn
  # 維持するタスク数
  desired_count   = 2
  # 起動タイプ
  launch_type     = "FARGATE"
  # バージョン（"Latest"の使用はできるだけ避ける）
  platform_version = "1.3.0"
  # タスク起動時のヘルスチェック猶予期間
  health_check_grace_period_seconds = 60

  # ネットワーク構成
  network_configuration {
    # パブリックIPの割り当て有無：プライベートネットワークで起動するため不要
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  # ALBとコンテナの関連づけ（インターネットからのリクエストをALBが受付け、コンテナにフォワードする）
  load_balancer {
    target_group_arn = aws_lb_target_group.targetgroup_for_ecs.arn
    container_name   = "my_container"
    container_port   = 80
  }

  # ライフサイクル
  lifecycle {
    # タスク定義の変更無視 → リソース初回作成時以外は変更無視
    ignore_changes = [task_definition]
  }
}

