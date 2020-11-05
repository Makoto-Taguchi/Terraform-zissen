# ロール・ポリシーの定義を外部から渡せるようにする
#IAMロールとIAMポリシーの名前
variable "name" {}
#ポリシードキュメント
variable "policy" {}
#IAMロールを紐づけるAWSのサービス識別子
variable "identifier" {}

# 信頼ポリシーの定義(AWSの[var.identifiers]サービスにロールを関連づける)
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type    = "Service"
      identifiers = [var.identifier]
    }
  }
}

# [var.name]ロールに信頼ポリシーを紐づける
resource "aws_iam_role" "default" {
  name    = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# [var.name]ポリシーに[var.policy]ポリシードキュメントを紐づける
resource "aws_iam_policy" "default" {
  name    = var.name
  policy  = var.policy
}

# [aws_iam_role]と[aws_iam_policy]を紐づける
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}