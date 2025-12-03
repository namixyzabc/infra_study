################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPCのID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "パブリックサブネットのリスト"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "クライアントアプリ用のプライベートサブネットのリスト"
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "プライベートサブネットのCIDRブロックのリスト"
  value       = module.vpc.private_subnets_cidr_blocks
}

################################################################################
# クラスター
################################################################################

output "cluster_arn" {
  description = "クラスターを識別するARN"
  value       = module.ecs_cluster.arn
}

output "cluster_id" {
  description = "クラスターを識別するID"
  value       = module.ecs_cluster.id
}

output "cluster_name" {
  description = "クラスターを識別する名前"
  value       = module.ecs_cluster.name
}

output "service_discovery_namespaces" {
  description = "利用可能なサービスディスカバリネームスペース"
  value       = aws_service_discovery_private_dns_namespace.this
}
