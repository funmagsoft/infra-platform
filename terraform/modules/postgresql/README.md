# PostgreSQL Flexible Server Module

Terraform module for deploying Azure PostgreSQL Flexible Server with VNet integration for secure
database access.

## Resources Created

- **PostgreSQL Flexible Server** - Managed PostgreSQL database
- **Server Configurations** - Custom configuration overrides
- **Private Endpoint** (optional) - If not using delegated subnet

## Features

- PostgreSQL versions 11-16 supported
- VNet integration via delegated subnet
- High Availability (Zone Redundant or Same Zone)
- Geo-redundant backups
- Automatic maintenance
- Point-in-time restore
- Public network access disabled

## Usage

```hcl
module "postgresql" {
  source = "../../modules/postgresql"

  resource_group_name = "rg-ecare-dev"
  location            = "West Europe"
  environment         = "dev"
  
  postgresql_version = "15"
  sku_name           = "B_Standard_B1ms"  # Burstable for dev
  storage_mb         = 32768

  administrator_login    = "psqladmin"
  administrator_password = var.db_password

  # VNet integration
  delegated_subnet_id = var.data_subnet_id
  private_dns_zone_id = var.postgresql_dns_zone_id

  # Backups
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  
  # High Availability (production only)
  high_availability_enabled = false
}
```

## SKU Tiers

| Tier | SKU Example | Use Case | vCores | Memory |
|------|-------------|----------|---------|---------|
| Burstable | `B_Standard_B1ms` | Dev/Test | 1 | 2 GiB |
| General Purpose | `GP_Standard_D2s_v3` | Production | 2 | 8 GiB |
| Memory Optimized | `MO_Standard_E4s_v3` | High-performance | 4 | 32 GiB |

## Key Inputs

- `postgresql_version`: PostgreSQL version (11-16)
- `sku_name`: Compute tier and size
- `storage_mb`: Storage size (32768-16777216 MB)
- `backup_retention_days`: Backup retention (7-35 days)
- `high_availability_enabled`: Enable HA (PROD only)
- `administrator_password`: Admin password (use TF_VAR or Key Vault)

## Key Outputs

- `postgresql_server_id`: Server resource ID
- `postgresql_fqdn`: Fully qualified domain name
- `postgresql_administrator_login`: Admin username

## High Availability

```hcl
# Production: Enable HA with zone redundancy
high_availability_enabled = true
high_availability_mode    = "ZoneRedundant"

# This creates:
# - Primary server in one availability zone
# - Standby replica in another zone
# - Automatic failover (< 2 min downtime)
```

## Connection Examples

### From Bastion VM

```bash
psql -h psql-ecare-dev.postgres.database.azure.net \
     -U psqladmin \
     -d postgres
```

### From Application (Connection String)

```
postgresql://psqladmin:PASSWORD@psql-ecare-dev.postgres.database.azure.net:5432/mydb?sslmode=require
```

### Using Environment Variable

```bash
export DATABASE_URL="postgresql://psqladmin:${DB_PASSWORD}@psql-ecare-dev.postgres.database.azure.net:5432/postgres"
```

## Security

- `require_secure_transport=off` for private network (configured automatically)
- Password authentication (Managed Identity support coming in future)
- Network isolation via VNet integration
- Encryption at rest (automatic)
- TLS 1.2+ for connections

## Backup and Restore

- Automatic backups daily
- Point-in-time restore to any time within retention period
- Geo-redundant backups replicate to paired region
- Manual backups via `pg_dump`

## Naming

- PostgreSQL Server: `psql-{project_name}-{environment}`

## Terraform Version

- Terraform >= 1.5.0
- AzureRM Provider ~> 3.0

