# hcp-terraform-agent-azure

Azure VM 上に HCP Terraform Agent を構築するための Terraform 構成です。
プライベートネットワーク内のリソースに対して、HCP Terraform からの Terraform 実行を安全に自動化することを目的としています。

## 概要

HCP Terraform Agent は、HCP Terraform（旧 Terraform Cloud）からの指示を受けて、プライベート環境内で `terraform plan` / `apply` を実行するエージェントです。
本リポジトリでは、そのエージェントを動かす Azure VM と周辺ネットワークリソースを Terraform で構築します。

エージェントトークンは Azure Key Vault に保管し、VM に付与した User Assigned Managed Identity 経由で安全に取得します。トークンをコードや変数ファイルに直接埋め込む必要はありません。

### 構成図

```
                        HCP Terraform
                             |
                    (アウトバウンド接続)
                             |
  Azure Virtual Network
  ┌──────────────────────────────────┐
  │                                  │
  │   AzureBastionSubnet             │
  │   ┌────────────┐                 │
  │   │   Bastion  │ ← 管理用SSH接続 │
  │   └────────────┘                 │
  │                                  │
  │   subnet-agent (10.0.2.64/28)    │
  │   ┌──────────────────────────┐   │
  │   │  Agent VM (Ubuntu)       │   │
  │   │  + User Assigned         │   │
  │   │    Managed Identity      │   │
  │   └──────────┬───────────────┘   │
  │              │ Managed Identity  │
  └──────────────┼───────────────────┘
                 │
         ┌───────▼────────┐
         │  Azure          │
         │  Key Vault      │ ← TFC エージェントトークンを保管
         └────────────────┘
```

- Agent VM はパブリック IP を持たず、HCP Terraform へのアウトバウンド接続のみで動作します
- VM への管理アクセスは Azure Bastion 経由で行います
- VM 起動時に cloud-init が Key Vault からトークンを取得し、tfc-agent を自動起動します

## ディレクトリ構成

```
.
├── main.tf                          # プロバイダー設定・リソースグループ・モジュール呼び出し
├── variables.tf                     # ルート変数定義
├── terraform.tfvars.example         # 変数値のサンプル
└── modules/
    ├── network/                     # 共有ネットワークリソース
    │   ├── main.tf                  # VNet・Bastion
    │   ├── variables.tf
    │   └── outputs.tf
    ├── key_vault/                   # Key Vault・Managed Identity
    │   ├── main.tf                  # Key Vault・User Assigned Identity・アクセスポリシー
    │   ├── variables.tf
    │   └── outputs.tf
    └── agent/                       # HCP Terraform Agent リソース
        ├── main.tf                  # network・virtual_machine モジュールの呼び出し
        ├── variables.tf
        ├── network/                 # Agent 用サブネット
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── virtual_machine/         # NIC・VM
            ├── main.tf
            ├── variables.tf
            └── cloud-init.yaml.tpl  # 起動時トークン取得・tfc-agent 自動起動
```

## 作成されるリソース

| リソース | 名前 | 説明 |
|---|---|---|
| Resource Group | `rg-agent-example` | 全リソースのコンテナ |
| Virtual Network | `vnet-agent` | 共有仮想ネットワーク |
| Subnet (Bastion) | `AzureBastionSubnet` | Bastion 専用サブネット (`10.0.2.0/26`) |
| Subnet (Agent) | `subnet-agent` | Agent VM 用サブネット (`10.0.2.64/28`) |
| Public IP | `public-ip-bastion` | Bastion 用パブリック IP |
| Bastion Host | `bastion-host` | VM へのセキュアな管理アクセス |
| Key Vault | `kv-langfuse-20260413` | TFC エージェントトークンの安全な保管 |
| User Assigned Identity | `uai-langfuse` | VM が Key Vault にアクセスするための Managed Identity |
| Key Vault Access Policy | — | エージェント VM・HCP Terraform SP・管理者ユーザーへのアクセス権付与 |
| Key Vault Secret | `tfc-agent-token` | HCP Terraform Agent Token |
| Network Interface | `nic-agent` | Agent VM 用 NIC（プライベート IP のみ） |
| Linux VM | `vm-agent` | HCP Terraform Agent を動かす Ubuntu VM |

## 前提条件

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.1.0
- Azure サブスクリプション
- Azure CLI（認証用）
- HCP Terraform アカウントおよび Agent Token
- HCP Terraform が Azure リソースを管理するためのサービスプリンシパル

## 使い方

### 1. 変数ファイルの作成

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集して、実際の値を設定してください。

```hcl
location             = "eastasia"
resource_group_name  = "rg-agent-example"
virtual_network_name = "vnet-agent"
ssh_public_key       = "ssh-rsa AAAA..."

# Azure テナント ID
tenant_id = "<your-tenant-id>"

# HCP Terraform Agent Token（Key Vault に保管されます）
tfc_agent_token = "<your-agent-token>"

# HCP Terraform が使用するサービスプリンシパルの Object ID
hcp_terraform_sp_object_id = "<your-sp-object-id>"

# Azure Portal でシークレットを参照する管理者ユーザーの Object ID
admin_user_object_id = "<your-admin-user-object-id>"
```

### 2. Azure へのログイン

```bash
az login
```

### 3. Terraform の実行

```bash
terraform init
terraform plan
terraform apply
```

`apply` 完了後、VM が起動すると cloud-init が自動的に以下を実行します。

1. IMDS（Instance Metadata Service）経由で Managed Identity のアクセストークンを取得
2. Key Vault から TFC エージェントトークンを取得
3. `tfc-agent` を systemd サービスとして起動し、HCP Terraform に接続

### 4. HCP Terraform と連携する場合

`main.tf` 内の `cloud {}` ブロックのコメントアウトを外し、organization 名と workspace 名を設定してください。

```hcl
cloud {
  organization = "<your-organization>"
  workspaces {
    name = "<your-workspace>"
  }
}
```
