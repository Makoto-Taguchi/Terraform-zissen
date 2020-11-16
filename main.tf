provider "aws" {
  region = "ap-northeast-1"
}

# ポリシードキュメントの定義
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect      = "Allow"
    actions     = ["ec2:DescribeRegions"]
    resources   = ["*"]
  }
}

# モジュール[iam_role]呼び出し
module "describe_regions_for_ec2" {
  source      = "./iam_role"
  name        = "describe-regions-for-ec2"
  identifier  = "ec2.amazonaws.com"
  policy      = data.aws_iam_policy_document.allow_describe_regions.json
}


# ECSタスク実行用のIAMポリシー作成
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  # ECSタスク実行ポリシーを参照する（AWS管理）
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスク実行IAMロールのポリシードキュメント
data "aws_iam_policy_document" "ecs_task_execution" {
  # source_jsonにより既存のポリシーデータソースを使える
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  # SSMパラメータストアとECSの統合に必要な権限付与
  statement {
    effect     = "Allow"
    actions    = ["ssm:GetParameters", "kms:Decrypt"]
    resources  = ["*"]
  }
}
# IAMロールモジュール呼び出し
module "ecs_task_execution_role" {
  source      = "./iam_role"
  name        = "ecs-task-execution"
  # このロールを紐づけるAWSリソース：ECSタスク
  identifier  = "ecs-tasks.amazonaws.com"
  # ポリシードキュメントを指定
  policy      = data.aws_iam_policy_document.ecs_task_execution.json
}

# CloudwatchイベントからECSを起動するためのIAMロール作成
data "aws_iam_policy" "ecs_events_role_policy" {
  # 「タスク実行」と「タスクにIAMロールを渡す」権限（AWS管理）
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}
# IAMロールモジュール呼び出し
module "ecs_events_role" {
  source     = "./iam_role"
  name       = "ecs-events"
  # このロールを紐づけるAWSリソース：CloudWatchイベント
  identifier = "events.amazonaws.com"
  # IAMポリシーを指定
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

# モジュール[security_group]呼び出し
module "example_sg" {
  source      = "./security_group"
  name        = "security-group"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  # cidr_blocks = [aws_vpc.example.cidr_block]
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}