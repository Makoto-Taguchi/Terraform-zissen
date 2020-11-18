# KMSのカスタマーマスターキーを定義
resource "aws_kms_key" "kms_key" {
  description         = "Example Customer Master Key"
  # キーの自動ローテーション（年に一度）
  enable_key_rotation = true
  # キーを有効化
  is_enabled          = true
  # キーの削除待機期間
  deletion_window_in_days = 30
}

# マスターキーをエイリアスで設定（UUIDだと分かりづらいため）
resource "aws_kms_alias" "kms_alias" {
    # "alias/"とプレフィックス指定することでエイリアスとなる
  name        = "alias/kms-key-alias"
  target_key_id = aws_kms_key.kms_key.key_id
}
