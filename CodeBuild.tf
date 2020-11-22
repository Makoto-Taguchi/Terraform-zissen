# CodeBuild用のIAMポリシードキュメント
data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      # ビルド出力アーティファクト（CodeBuildがビルド時に生成するファイル）を保存するためのS3操作権限
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",

      # ビルドログを出力するためのCloudWatch Logs操作権限
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      # DockerイメージをプッシュするためのECR操作権限
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
  }
}

# IAMロール
# 上記のポリシードキュメントをCodeBuildに紐づける
module "codebuild_role" {
  source     = "./iam_role"
  name       = "codebuild"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

# CodeBuildプロジェクト定義
resource "aws_codebuild_project" "codebuild_project" {
  name         = "codebuild-project"
  # サービスロールとして上記のIAMロールを指定
  service_role = module.codebuild_role.iam_role_arn

  # 以下いずれも"CODEPIPELINE"と連携することを宣言
  # ビルド対象のファイル
  source {
    type = "CODEPIPELINE"
  }
  # ビルド出力アーティファクトの格納先
  artifacts {
    type = "CODEPIPELINE"
  }

  # ビルド環境
  environment {
    type            = "LINUX_CONTAINER"
    compute_type     = "BUILD_GENERAL1_SMALL"
    # AWSが管理するUbuntuベースのイメージを指定
    image           = "aws/codebuild/standard:2.0"
    # 特権を付与 → ビルドのためにdockerコマンドを使うため
    privileged_mode = true
  }
}