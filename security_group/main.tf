# セキュリティグループのモジュール
variable "name" {}
variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
    # 文字列を明示的に定義（デフォルトはany型のため）
    type = list(string)
}

# セキュリティグループの定義
resource "aws_security_group" "default" {
    name    = var.name
    vpc_id  = var.vpc_id
}

# セキュリティグループの定義（インバウンド）
resource "aws_security_group_rule" "ingress" {
    type                = "ingress"
    from_port           = var.port
    to_port             = var.port
    protocol            = "tcp"
    cidr_blocks         = var.cidr_blocks
    security_group_id   = aws_security_group.default.id
}

# セキュリティグループの定義（アウトバウンド）
resource "aws_security_group_rule" "egress" {
    type                = "egress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = var.cidr_blocks
    security_group_id   = aws_security_group.default.id
}

output "security_group_id" {
    value = aws_security_group.default.id
}