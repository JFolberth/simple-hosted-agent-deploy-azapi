# Azure Deploy - Foundry Basic Runtime

End-to-end build -> push -> plan -> apply for the Azure stack.

## Prerequisites

- A local environment file under `infra/environments/`; first use bootstraps ACR automatically.
- Azure CLI authenticated for the target subscription (`az account show`).
- Docker daemon reachable (`docker ps`).

## Run

```bash
./simple_agent/azure/deploy/deploy.sh
```

The workflow computes an image tag from the current git SHA, bootstraps ACR when
needed, builds the image, pushes it to ACR only when the tag does not already
exist, runs `terraform plan`, and prompts before `terraform apply`.

The logical hosted agent is managed declaratively by Terraform through AzAPI's
`azapi_data_plane_resource` targeting `Microsoft.Foundry/agents@v1`. Terraform
updates the logical agent to reference the Git-derived image tag and attaches the
account-scoped RAI policy by its full ARM resource ID. Image build and push stay
outside Terraform. Individual historical or draft agent versions are Foundry
service history and are not modeled as separate Terraform resources.

A no-change plan exits successfully without making a separate Foundry REST
request.

## Flags

| Flag | Effect |
|---|---|
| `--env <name>` | Environment (default `dev`). Selects `environments/<name>.tfvars`. |
| `--tag <string>` | Override the computed image tag. `latest` is rejected. |
| `--yes` | Skip the confirmation prompt before `terraform apply`. |
| `--allow-dirty` | Do not append `-dirty` to the tag when the working tree is unclean. |
| `--skip-build` | Reuse an existing local image; skip `docker build`. |
| `--skip-push` | Do not push to ACR. Implies `--skip-apply`. |
| `--skip-apply` | Produce the plan only; leave `tfplan` in the module dir. |

## Environment variables honored

| Variable | Purpose |
|---|---|
| `PIP_INDEX_URL`, `PIP_TRUSTED_HOST` | Forwarded to `docker build` as `--build-arg`. |
| `DEPLOY_AUTO_APPROVE=1` | Same as `--yes`. |
| `ALLOW_DIRTY=1` | Same as `--allow-dirty`. |
| `SKIP_BUILD=1`, `SKIP_PUSH=1` | Same as the `--skip-*` flags. |
