# AKS Namespace Module

Tworzy jeden namespace w klastrze AKS.

## Inputs

- `namespace` (default: `ecare`)
- `environment` – dev/test/stage/prod
- `project_name` (default: `ecare`)
- `labels` – dodatkowe etykiety K8s

## Outputs

- `namespace_name`
