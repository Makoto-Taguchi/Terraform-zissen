# VPC定義
resource "aws_vpc" "example" {
  cidr_block              = "10.0.0.0/16"
  # DNSサーバによる名前解決を有効化
  enable_dns_support      = true
  # リソースへのパブリックDNSホスト名の自動割り当てを有効化
  enable_dns_hostnames    = true

  tags = {
    Name = "example"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# デフォルトルート（インターネットへの通信）
resource "aws_route" "public" {
  route_table_id          = aws_route_table.public.id
  gateway_id              = aws_internet_gateway.example.id
  destination_cidr_block  = "0.0.0.0/0"
}

# パブリックサブネット1a （マルチAZ構成）
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  # サブネット内で起動したインスタンスにパブリックIPを自動割り当て
  map_public_ip_on_launch = true
}

# パブリックサブネット1c （マルチAZ構成）
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  # サブネット内で起動したインスタンスにパブリックIPを自動割り当て
  map_public_ip_on_launch = true
}

# サブネット1aとルートテーブルの紐付け
resource "aws_route_table_association" "public_0" {
  subnet_id       = aws_subnet.public_0.id
  route_table_id  = aws_route_table.public.id
}

# サブネット1bとルートテーブルの紐付け
resource "aws_route_table_association" "public_1" {
  subnet_id       = aws_subnet.public_1.id
  route_table_id  = aws_route_table.public.id
}

# EIP (NATゲートウェイ 1a)
resource "aws_eip" "nat_gateway_0" {
  vpc         = true
  # インターネットゲートウェイ作成時にEIPを作成（暗黙的な依存関係を明示）
  depends_on  = [aws_internet_gateway.example]
}

# EIP (NATゲートウェイ 1c)
resource "aws_eip" "nat_gateway_1" {
  vpc         = true
  depends_on  = [aws_internet_gateway.example]
}

# NATゲートウェイ 1a
resource "aws_nat_gateway" "nat_gateway_0" {
  # 上記のEIPを割り当て
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  # インターネットゲートウェイ作成時にNATゲートウェイを作成（暗黙的な依存関係を明示）
  depends_on    = [aws_internet_gateway.example]
}

# NATゲートウェイ 1c
resource "aws_nat_gateway" "nat_gateway_1" {
  # 上記のEIPを割り当て
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  # インターネットゲートウェイ作成時にNATゲートウェイを作成（暗黙的な依存関係を明示）
  depends_on    = [aws_internet_gateway.example]
}

# プライベートルートテーブル 1a
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

# プライベートルートテーブル 1a
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

# プライベートルート 1a
resource "aws_route" "private_0" {
  route_table_id          = aws_route_table.private_0.id
  # 以下2行でデフォルトルートをNATゲートウェイにルーティング
  nat_gateway_id          = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block  = "0.0.0.0/0"
}

# プライベートルート 1c
resource "aws_route" "private_1" {
  route_table_id          = aws_route_table.private_1.id
  nat_gateway_id          = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block  = "0.0.0.0/0"
}

# プライベートサブネット1a （マルチAZ構成）
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  # パブリックIPは割り当てないのでfalse
  map_public_ip_on_launch = false
}

# プライベートサブネット1c （マルチAZ構成）
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  # パブリックIPは割り当てないのでfalse
  map_public_ip_on_launch = false
}

#プライベートサブネットとルートテーブルの紐付け 1a
resource "aws_route_table_association" "private_0" {
  subnet_id       = aws_subnet.private_0.id
  route_table_id  = aws_route_table.private_0.id
}

#プライベートサブネットとルートテーブルの紐付け 1c
resource "aws_route_table_association" "private_1" {
  subnet_id       = aws_subnet.private_1.id
  route_table_id  = aws_route_table.private_1.id
}