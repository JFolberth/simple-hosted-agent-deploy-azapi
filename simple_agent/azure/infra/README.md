# Foundry Basic Runtime - Terraform (Azure)

Provisions Azure infrastructure for a basic hosted-agent workflow using
Terraform with the AzAPI provider.

## Layout

```
azure/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── environments/
│   ├── example.tfvars
│   └── dev.tfvars
└── modules/
    ├── log_analytics/
    ├── application_insights/
    ├── foundry_account/
    ├── foundry_project/
    ├── foundry_connection/
    ├── hosted_agent/
    └── image_registry/
```

## Graph

1. Resource group
2. Deterministic random token for names
3. Log Analytics workspace
4. Application Insights (workspace-based)
5. Foundry account with an account-scoped RAI policy and model deployments attached to it
6. Foundry project with system-assigned identity and required role assignments
7. Required Foundry project connections for Application Insights and ACR
8. Azure Container Registry
9. Remote ACR image build from the local application source
10. Logical Foundry hosted agent managed through the Foundry v1 data plane

## Usage

```bash
terraform -chdir=simple_agent/azure/infra init
terraform -chdir=simple_agent/azure/infra plan \
  -var-file=environments/dev.tfvars \
  -var="image_tag=<git-sha>"
terraform -chdir=simple_agent/azure/infra apply \
  -var-file=environments/dev.tfvars \
  -var="image_tag=<git-sha>"
```

Applying the plan uploads `simple_agent/azure/src` to an ACR quick build. The
authenticated Azure CLI identity must be able to queue ACR builds. Terraform
waits for the `linux/amd64` image build and push to succeed before creating or
updating the hosted agent.

## Notes

- Terraform version constraint is `>= 1.9`.
- Providers are pinned to `Azure/azapi >= 2.9.0, < 3.0.0` and `hashicorp/random ~> 3.0`.
- `image_tag` is required and rejects `latest`.
- App Insights and related connections and role assignments are required.
- The logical hosted agent uses AzAPI's `azapi_data_plane_resource` targeting
  `Microsoft.Foundry/agents@v1`. Its project endpoint parent omits the URL
  scheme as required by AzAPI.
- Terraform manages the current logical-agent definition and invokes the ACR
  image build through `terraform_data`. The image itself is an external build
  artifact, so deleting it outside Terraform does not automatically recreate it.
  Individual historical or draft Foundry versions are not represented as
  separate Terraform resources.
- `foundry_rai_policy` defines one account-scoped content-filter policy shared by all model deployments. Each deployment references the policy by name, while hosted agents reference its full ARM resource ID separately.
- The blocking boundary is the RAI policy attached to model deployments and hosted agents. Application Insights evaluations and tracing provide monitoring evidence; they do not block prompts or responses.
