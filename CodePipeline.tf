# CodePipeline用のIAMポリシードキュメント
data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      # ステージ間でデータを受け渡すためのS3操作権限
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      # CodeBuildプロジェクトを起動するためのCodeBuild操作権限
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      # ECSにDockerイメージをデプロイするためのECS操作権限
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      # CodeBuildとECSにロールを渡すためのPassRole権限
      "iam:PassRole",
    ]
  }
}

# IAMロール
# 上記ポリシードキュメントをCodePipelineに紐づける
module "codepipeline_role" {
  source     = "./iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

# アーティファクトストアの定義（CodePipelineの各ステージでデータを受け渡す）
resource "aws_s3_bucket" "artifact" {
  bucket = "for-artifactstore-terraform-20201122"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

# CodePipelineの定義
resource "aws_codepipeline" "codepipeline" {
  name     = "my-codepipeline"
  role_arn = module.codepipeline_role.iam_role_arn

  # Sourceステージ（GitHubからソースコード取得）
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      output_artifacts = ["Source"]

      # ソースコードの取得先を指定
      configuration = {
        Owner                = "Makoto-Taguchi"
        Repo                 = "Terraform-zissen"
        Branch               = "main"
        # ポーリング無効（CodePipelineの起動はWebhookから行うため）
        OAuthToken           = "258868bb4339dc1bd08dc78b204ad2a6bfcbd73d"
        PollForSourceChanges = false
      }
    }
  }


  # Buildステージ（CodeBuildを実行し、ECRにDockerイメージをプッシュ）
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.id
      }
    }
  }


  # Deployステージ（ECSへDockerイメージをデプロイ）
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      input_artifacts = ["Build"]

      # デプロイ先のECSクラスタとECSサービスを指定
      configuration = {
        ClusterName = aws_ecs_cluster.ecs_cluster.name
        ServiceName = aws_ecs_service.ecs_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  # アーティファクトストア：上記で定義したS3バケットを指定
  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}

# CodePipeline Webhookを作成（GitHubからWebhookを受け取るため）
resource "aws_codepipeline_webhook" "codepipeline_webhook" {
  name            = "my-codepipeline-webhook"

  # ターゲット（Webhookを受け取ったら起動するパイプライン）の設定
  target_pipeline = aws_codepipeline.codepipeline.name
  # 最初に実行するアクション
  target_action   = "Source"

  # メッセージ認証
  authentication  = "GITHUB_HMAC"
  authentication_configuration {
    # 20バイト以上のランダムな文字列を秘密鍵に指定
    secret_token = "VeryRandomStringMoreThan20Byte!"
  }

  # フィルタ（CodePipelineの起動条件）
  filter {
    json_path     = "$.ref"
    # mainブランチの時のみ起動するよう設定
    match_equals  ="refs/heads/{Branch}"
  }
}

# GitHubプロバイダの定義
provider "github" {
  organization = "Makoto-Taguchi"
}

# GitHub Webhookの定義
resource "github_repository_webhook" "github_webhook" {
  repository = "Terraform-zissen"

  # 通知設定
  configuration {
    # 通知先のCodePipelineのURL
    url       = aws_codepipeline_webhook.codepipeline_webhook.url
    # 認証用の秘密鍵指定
    secret    = "VeryRandomStringMoreThan20Byte!"
    content_type = "json"
    insecure_ssl = false
  }

  # トリガーとなるGitHubのイベントを設定
  events = ["push"]
}