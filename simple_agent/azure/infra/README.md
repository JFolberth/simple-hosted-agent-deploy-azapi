# Foundry Basic Runtime - Terraform (Azure)

Provisions Azure infrastructure for a basic hosted-agent workflow using
Terraform with the AzAPI provider. The deployment is split into two
independent Terraform stacks so the container image can be built and pushed
from the CLI between them; see
[../deploy/deploy.sh](../deploy/deploy.sh) for the orchestrating script.

## Layout

```
azure/infra/
├── foundry_base/        # Stack 1: everything except the hosted agent
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── example.tfvars
│       └── dev.tfvars
├── hosted_agent/         # Stack 3: the hosted agent, deployed after the image is pushed
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── example.tfvars
│       └── dev.tfvars
└── modules/
    ├── log_analytics/
    ├── application_insights/
    ├── foundry_account/
    ├── foundry_project/
    ├── foundry_connection/
    ├── image_registry/
    └── hosted_agent/
```

## Graph

**foundry_base**

1. Resource group
2. Deterministic random token for names
3. Log Analytics workspace
4. Application Insights (workspace-based)
5. Foundry account with an account-scoped RAI policy and model deployments attached to it
6. Foundry project with system-assigned identity and required role assignments
7. Azure Container Registry
8. Required Foundry project connections for Application Insights and ACR

**hosted_agent**

9. Logical Foundry hosted agent managed through the Foundry v1 data plane,
   using an image already built and pushed to the `foundry_base` ACR.

## Usage

Prefer running [../deploy/deploy.sh](../deploy/deploy.sh), which drives all
three stages below. To run the stages by hand:

```bash
# 1. Base infrastructure (resource group, Foundry account/project, ACR, ...)
terraform -chdir=simple_agent/azure/infra/foundry_base init
terraform -chdir=simple_agent/azure/infra/foundry_base plan -var-file=environments/dev.tfvars
terraform -chdir=simple_agent/azure/infra/foundry_base apply -var-file=environments/dev.tfvars

# 2. Build and push the application image (CLI, not Terraform)
ACR_NAME="$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw acr_name)"
ACR_LOGIN_SERVER="$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw acr_login_server)"
IMAGE_TAG="<git-sha>"
docker build --platform linux/amd64 -t "${ACR_LOGIN_SERVER}/basic-agent:${IMAGE_TAG}" simple_agent/azure/src
az acr login --name "$ACR_NAME"
docker push "${ACR_LOGIN_SERVER}/basic-agent:${IMAGE_TAG}"

# 3. Hosted agent, referencing the pushed image and foundry_base's outputs
terraform -chdir=simple_agent/azure/infra/hosted_agent init
terraform -chdir=simple_agent/azure/infra/hosted_agent plan \
  -var-file=environments/dev.tfvars \
  -var="acr_login_server=${ACR_LOGIN_SERVER}" \
  -var="agent_name=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw agent_name)" \
  -var="model_deployment_name=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw model_deployment_name)" \
  -var="project_endpoint=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw foundry_project_endpoint)" \
  -var="rai_policy_id=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw foundry_rai_policy_id)" \
  -var="image_tag=${IMAGE_TAG}"
terraform -chdir=simple_agent/azure/infra/hosted_agent apply \
  -var-file=environments/dev.tfvars \
  -var="acr_login_server=${ACR_LOGIN_SERVER}" \
  -var="agent_name=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw agent_name)" \
  -var="model_deployment_name=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw model_deployment_name)" \
  -var="project_endpoint=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw foundry_project_endpoint)" \
  -var="rai_policy_id=$(terraform -chdir=simple_agent/azure/infra/foundry_base output -raw foundry_rai_policy_id)" \
  -var="image_tag=${IMAGE_TAG}"
```

## Notes

- Terraform version constraint is `>= 1.9`.
- Providers are pinned to `Azure/azapi >= 2.9.0, < 3.0.0`, `hashicorp/random ~> 3.0`, and `hashicorp/time ~> 0.14` (foundry_base only).
- `hosted_agent` does not read `foundry_base`'s state directly. Its
  `acr_login_server`, `agent_name`, `model_deployment_name`, `project_endpoint`,
  and `rai_policy_id` variables must be supplied as `-var` overrides (or a
  matching `environments/*.tfvars` entry), sourced from `foundry_base`'s
  outputs. [../deploy/deploy.sh](../deploy/deploy.sh) does this automatically;
  apply `foundry_base` before planning or applying `hosted_agent` by hand.
- `image_tag` is required in the `hosted_agent` stack and rejects `latest`; the
  image must already exist at `<acr_login_server>/<image_repository_name>:<image_tag>`
  before the hosted agent is applied.
- App Insights and related connections and role assignments are created in `foundry_base`.
- The logical hosted agent uses AzAPI's `azapi_data_plane_resource` targeting
  `Microsoft.Foundry/agents@v1`. Its project endpoint parent omits the URL
  scheme as required by AzAPI.
- The container image is an external build artifact built and pushed by
  [../deploy/deploy.sh](../deploy/deploy.sh) (or the manual `docker`/`az acr`
  commands above), not by Terraform. Individual historical or draft Foundry
  versions are not represented as separate Terraform resources.
- `foundry_rai_policy` defines one account-scoped content-filter policy shared by all model deployments. Each deployment references the policy by name, while hosted agents reference its full ARM resource ID separately.
- The blocking boundary is the RAI policy attached to model deployments and hosted agents. Application Insights evaluations and tracing provide monitoring evidence; they do not block prompts or responses.
- The `rai_policy` resource ignores changes to `body.properties.contentFilters` and the `foundry_connection` module ignores changes to `body.properties.isSharedToAll`: Azure asynchronously appends platform-managed RAI filters (`DefenderForAI`, `Indirect Attack`) and the connection read-back briefly lags the write, which otherwise produces a perpetual plan diff. Removing those `lifecycle.ignore_changes` entries is required before an intentional change to `foundry_rai_policy.content_filters` or a connection's shared-to-all setting will apply.
- Each stack uses its own local Terraform state (`backend "local" {}` in its own directory). Use an appropriately secured remote backend per stack for shared deployments.
