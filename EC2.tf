# 以下、Session Manager用
# Session Managerと連携するEC2用のポリシードキュメント
data "aws_iam_policy_document" "ec2_for_ssm" {
  source_json = data.aws_iam_policy.ec2_for_ssm.policy

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions   = [
      # S3バケットへの書き込み権限
      "s3:PutObject",
      # CloudWatch Logsへの書き込み権限
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      # ECRの参照権限
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      # SSMパラメータストアの参照権限
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",

      "kms:Decrypt",
    ]
  }
}

# EC2のIAMポリシー作成
data "aws_iam_policy" "ec2_for_ssm" {
  # Session Manager用のポリシーを参照する（AWS管理）
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAMロール
# 上記ポリシードキュメントをEC2インスタンスに紐づける
module "ec2_for_ssm_role" {
  source     = "./iam_role"
  name       = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

# インスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  # EC2は直接IAMロール付与できないのでここにIAMロールを付与する
  role = module.ec2_for_ssm_role.iam_role_name
}

# EC2インスタンス
resource "aws_instance" "instance_for_operation" {
  ami           = "ami-034968955444c1fd9"
  instance_type = "t2.micro"
  # 上記のインスタンスプロファイルを指定
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  # プライベートサブネット指定 → 外部アクセス遮断
  subnet_id     = aws_subnet.private_0.id
  # EC2インスタンスプロビジョニング（docker起動）用のスクリプトを指定
  user_data     = file("./user_data.sh")
}

output "operation_instance_id" {
  value = aws_instance.instance_for_operation.id
}


# AWS CLI経由のシェルアクセス
# $ aws ssm start-session --target  i-097a416e6a144a15c
# 　　（--document-name session_manager_run_shell）　← aws_ssm_documentでnameを指定のものにしているなら省略可
# アクセスできたか確認
# $ whoami
# ssm-userはsudo権限持っているので以下も実行可能
# $ sudo su -