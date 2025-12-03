

# コアインフラストラクチャ
このフォルダには、ECS FargateワークロードのコアインフラストラクチャをデプロイするためのTerraformコードが含まれています。このスクリプトによって作成されるAWSリソースは次のとおりです。
* ネットワーキング
  * VPC
    * 3つのパブリックサブネット、AZごとに1つ。リージョンのAZが3つ未満の場合、AZと同じ数のパブリックサブネットが作成されます。
    * 3つのプライベートサブネット、AZごとに1つ。リージョンのAZが3つ未満の場合、AZと同じ数のプライベートサブネットが作成されます。
    * 1つのNATゲートウェイ
    * 1つのインターネットゲートウェイ
    * 関連するルートテーブル
* AWS CloudWatch Container Insightsが有効になっている1つのECSクラスター。
* タスク実行IAMロール
* CloudWatchロググループ
* CloudMapサービスディスカバリネームスペース `default`



## 使い方
* 自分のアカウントからフォークしたリポジトリ（aws-ia組織のものではありません）をクローンし、以下のように適切なディレクトリに移動します。
```bash
cd core-infra/
```
* Terraform initを実行して、プロバイダーをダウンロードし、モジュールをインストールします。
```shell
terraform init
```
* terraform planの出力を確認し、terraformが実行する変更を確認してから、適用します。
```shell
terraform plan
terraform apply --auto-approve
```
## 出力
Terraformコードの実行後、次のTerraform適用で入力として必要なIDと値を含む出力が得られます。このインフラストラクチャを使用して他のサンプルブループリントを実行できます。必要なのは `cluster_name` だけです。

## クリーンアップ
以前に作成したすべてのリソースを削除する場合は、次のコマンドを実行します。他のブループリントを作成し、それらがこのインフラストラクチャを使用している場合は、まずそれらのブループリントリソースを破棄してください。
```shell
terraform destroy
```


<!-- BEGIN_TF_DOCS -->
## 前提条件

| 名前 | バージョン |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 5.100.0 |

## プロバイダー

| 名前 | バージョン |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 5.100.0 |

## モジュール

| 名前 | ソース | バージョン |
|------|--------|---------|
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | ~> 5.6 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## リソース

| 名前 | タイプ |
|------|------|
| [aws_service_discovery_private_dns_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/availability_zones) | data source |

## 入力

入力はありません。

## 出力

| 名前 | 説明 |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | クラスターを識別する ARN |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | クラスターを識別する ID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | クラスターを識別する名前 |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | クライアントアプリ用のプライベートサブネットのリスト |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | プライベートサブネットの CIDR ブロックのリスト |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | パブリックサブネットのリスト |
| <a name="output_service_discovery_namespaces"></a> [service\_discovery\_namespaces](#output\_service\_discovery\_namespaces) | 利用可能なサービスディスカバリネームスペース |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC の ID |
<!-- END_TF_DOCS -->
