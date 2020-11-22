# DBパラメータグループ（my.cnfの記述内容）
resource "aws_db_parameter_group" "db_parameter_group" {
  name    = "mysql-parameter-group"
  # エンジン名（ミドルウェア）とバージョン
  family  = "mysql5.7"

  # 設定内容（設定のパラメータ名と値をペアで記述）
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# DBオプショングループ（DBにオプション機能追加）
resource "aws_db_option_group" "db_option_group" {
  name                 = "mysql-option-group"
  engine_name          = "mysql"
  major_engine_version = "5.7"

  # 追加するオプション設定
  option {
    # MariaDB監査プラグイン：ユーザのアクティビティを記録する
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

# DBサブネットグループ（DBを稼働させるサブネット）
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "mysql-subnet-group"
  # マルチAZのため、それぞれ異なるAZのサブネットを指定
  subnet_ids  = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}


# DBインスタンスの設定（DBサーバ作成）
resource "aws_db_instance" "db_instance" {
  # DBのエンドポイントで使うID
  identifier     = "mysql-instance"

  engine         = "mysql"
  engine_version  = "5.7.25"
  instance_class = "db.t3.small"

  # ストレージ
  allocated_storage = 20
  # 指定した容量まで自動的にスケール
  max_allocated_storage =100
  # gp2は汎用SSDを示す
  storage_type          = "gp2"

  # ディスク暗号化
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.kms_key.arn

  # マスターユーザ名
  username              = "admin"
  # マスターパスワード（apply後変更）
  password              = "VeryStrongPassword!"

  # マルチAZ有効化
  multi_az              = true

  # VPCからのアクセス社団
  publicly_accessible   = false

  # バックアップの時刻（UTC）
  backup_window         = "09:10-09:40"
  # バックアップ期間
  backup_retention_period = 30

  # メンテナンスの時刻（UTC）
  maintenance_window    = "mon:10:10-mon:10:40"
  # 自動マイナーバージョンアップを無効化
  auto_minor_version_upgrade = false

  # 削除保護は一時無効化
  deletion_protection   = false
  # インスタンス削除時にスナップショット作成：一時無効化
  skip_final_snapshot   = true

  port                  = 3306

  # RDSの設定変更のタイミング：即時反映しない
  apply_immediately     = false

  # セキュリティグループ
  vpc_security_group_ids = [module.mysql_sg.security_group_id]

  # パラメータグループ、オプショングループ、サブネットグループ紐付け
  parameter_group_name  = aws_db_parameter_group.db_parameter_group.name
  option_group_name     = aws_db_option_group.db_option_group.name
  db_subnet_group_name  = aws_db_subnet_group.db_subnet_group.name

  # apply後にマスターパスワード変更するための設定
  lifecycle {
    ignore_changes = [password]
  }
}
# マスターパスワードはtfstateファイルに平文で書き込まれるので更新する
# aws rds modify-db-instance --db-instance-identifier 'mysql-instance' --master-user-password '変更後のパスワード'