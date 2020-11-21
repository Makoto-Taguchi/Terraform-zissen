# SSMパラメータストア
resource "aws_ssm_parameter" "db_username" {
  # キー名
  name        = "/db/username"
  # 値
  value       = "root"
  type        = "String"
  description = "データベースのユーザ名"
}

# 暗号化したパスワード作成→これではソースコードから分かってしまう
resource "aws_ssm_parameter" "db_raw_password" {
  name      = "/db/raw_password"
  value     = "VeryStrongPassword!"
  # 暗号化
  type      = "SecureString"
  description = "データベースのパスワード"
}

# 暗号化したパスワード作成（コード上のものは読まれるのであくまで初期設定）
# apply後、AWS CLIで更新して分からなくする。
resource "aws_ssm_parameter" "db_password" {
  name      = "/db/password"
  value     = "uninitialized"
  type      = "SecureString"
  description = "データベースのパスワード"

  lifecycle {
    ignore_changes = [value]
  }
}