# ECRリポジトリ作成（Dockerイメージ保管）
resource "aws_ecr_repository" "ecr_repository" {
  name = "ecr-repository"
}

# ECRライフサイクルポリシー
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}

# Dockerイメージのプッシュ方法
# 1.Dockerクライアントの認証
# $(aws ecr get-login --region ap-northeast-1 --no-include-email)

# 2.Dockerfile作成
# vi Dockerfile

# 3.ECRで、イメージ名のレジストリを適当なDockerfileをビルド
# docker build -t 140178484827.dkr.ecr.ap-northeast-1.amazonaws.com/ecr-repository:latest .

# 4.Dockerイメージをプッシュ
# docker push 140178484827.dkr.ecr.ap-northeast-1.amazonaws.com/ecr-repository:latest