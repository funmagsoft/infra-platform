# Service Bus Module

Terraform module for deploying Azure Service Bus with Private Endpoint for secure messaging.

## Resources Created

- **Service Bus Namespace** - Messaging infrastructure
- **Private Endpoint** - Private network access

## Features

- Standard and Premium tiers supported
- Private Endpoint integration
- Zone redundancy (Premium tier)
- TLS 1.2 minimum
- Public network access disabled
- Messaging units configurable (Premium)

## Usage

```hcl
module "service_bus" {
  source = "../../modules/service-bus"

  resource_group_name = "rg-ecare-dev"
  location            = "West Europe"
  environment         = "dev"
  
  sku            = "Standard"
  capacity       = 1  # Premium only
  zone_redundant = false  # Premium only

  subnet_id           = var.data_subnet_id
  private_dns_zone_id = var.servicebus_dns_zone_id
}
```

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Max message size | 256 KB | 256 KB | 1 MB |
| Topics | ✗ | ✓ | ✓ |
| Transactions | ✗ | ✓ | ✓ |
| Message batching | ✓ | ✓ | ✓ |
| Geo-disaster recovery | ✗ | ✗ | ✓ |
| Private Endpoints | ✗ | ✗ | ✓ |
| Zone redundancy | ✗ | ✗ | ✓ |

**Note**: Private Endpoints require Premium SKU in this module configuration.

## Key Inputs

- `sku`: Basic, Standard, or Premium
- `capacity`: Messaging units for Premium (1, 2, 4, 8, 16)
- `zone_redundant`: Enable zone redundancy (Premium only)

## Key Outputs

- `servicebus_namespace_id`: Namespace resource ID
- `servicebus_namespace_name`: Namespace name
- `servicebus_endpoint`: Service Bus endpoint URL
- `servicebus_primary_connection_string`: Connection string (sensitive)

## Creating Queues and Topics

Queues and topics are not created by this module. Create them separately:

```hcl
resource "azurerm_servicebus_queue" "example" {
  name         = "my-queue"
  namespace_id = module.service_bus.servicebus_namespace_id

  max_delivery_count = 10
  lock_duration      = "PT5M"
}

resource "azurerm_servicebus_topic" "example" {
  name         = "my-topic"
  namespace_id = module.service_bus.servicebus_namespace_id
}
```

## Access from Applications

```bash
# Using connection string (not recommended)
export SERVICE_BUS_CONNECTION_STRING=$(terraform output -raw servicebus_primary_connection_string)

# Using Managed Identity (recommended)
az role assignment create \
  --assignee <app-identity-id> \
  --role "Azure Service Bus Data Owner" \
  --scope <servicebus-namespace-id>
```

## Naming

- Service Bus Namespace: `sb-{project_name}-{environment}`

## Terraform Version

- Terraform >= 1.5.0
- AzureRM Provider ~> 3.0

