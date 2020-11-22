# ElastiCacheのパラメータグループ
resource "aws_elasticache_parameter_group" "ElastiCache_param_group" {
  name    = "redis-param-group"
  family  = "redis5.0"

  # 設定内容（設定のパラメータ名と値をペアで記述）
  parameter {
    # クラスタモード無効（コスト抑えるため）
    name  = "cluster-enabled"
    value = "no"
  }
}

# サブネットグループ
resource "aws_elasticache_subnet_group" "ElastiCache_param_group" {
  name       = "redis-subnet-group"
  # マルチAZ
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}

# レプリケーショングループ
resource "aws_elasticache_replication_group" "ElastiCache_replication_group" {
  # Redisのエンドポイントで使うID
  replication_group_id          = "redis-replication-group"
  # 概要
  replication_group_description = "Cluster Disabled"
  # エンジンはmemchacheではなくRedis
  engine                        = "redis"
  engine_version                = "5.0.4"

  # ノード数（プライマリノード1つ、レプリカノード2つ）
  number_cache_clusters         = 3
  # ノードの種類
  node_type                     = "cache.m3.medium"

  # スナップショット作成時刻
  snapshot_window               = "09:10-10:10"
  # スナップショット保持期間
  snapshot_retention_limit      = 7

  # メンテナンス時刻
  maintenance_window            = "mon:10:40-mon:11:40"

  # 自動フェイルオーバー有効化（マルチAZが前提）
  automatic_failover_enabled    = true

  port                          = 6379

  # 設定変更タイミング：即時反映しない
  apply_immediately             = false

  # セキュリティグループ
  security_group_ids            = [module.redis_sg.security_group_id]

  # パラメータグループ、サブネットグループ紐付け
  parameter_group_name          = aws_elasticache_parameter_group.ElastiCache_param_group.name
  subnet_group_name             = aws_elasticache_subnet_group.ElastiCache_param_group.name
}