# simple-hosted-agent-deploy-azapi

Deploy a Python hosted agent to Microsoft Foundry using Terraform and the
Azure AzAPI provider. Includes the Azure Expert and Terraform Copilot agents,
MCP configuration, and an Azure-focused development container.

## Architecture

Deployment is split into two Terraform stacks with a CLI-driven image build in
between, orchestrated by
[simple_agent/azure/deploy/deploy.sh](simple_agent/azure/deploy/deploy.sh):

1. **foundry_base** (Terraform) - resource group, Azure Container Registry,
   Log Analytics, Application Insights, a Foundry account and project, model
   deployment, content safety policy, connections, and role assignments.
2. **image build** (Docker CLI) - builds the application image and pushes it
   to the ACR created by `foundry_base`.
3. **hosted_agent** (Terraform) - publishes the logical hosted agent using
   `azapi_data_plane_resource` with `Microsoft.Foundry/agents@v1`, referencing
   the image pushed in step 2. Foundry manages the agent version history.

## Development Container

Install Docker and VS Code with the Dev Containers extension, clone this repo,
then run **Dev Containers: Reopen in Container**. The container provides:

- Azure CLI, Terraform, TFLint, Git, and GitHub CLI.
- Docker CLI with access to the host Docker daemon for builds and the Terraform MCP server.
- Python 3.13 and a local `.venv` containing the application requirements.
- Terraform, Python/Pylance, Azure Resources, Docker, and Copilot extensions.

The application requirements include `agent-framework-core`,
`agent-framework-foundry`, `agent-framework-foundry-hosting`, and `azure-identity`.
The post-create script installs them and checks dependency compatibility. Package
versions follow the existing sample constraints; they are not fully locked.
Public package sources are used without an internal mirror or preloaded credentials.
If `PIP_INDEX_URL` and `PIP_TRUSTED_HOST` are set in the shell running `deploy.sh`,
they are forwarded as `docker build` args and promoted to `ENV` in the application
[Dockerfile](simple_agent/azure/src/Dockerfile), so a private mirror can be used
for the image build without changing the Dockerfile.

Only open trusted repositories with host Docker access: that access is highly
privileged. Image builds target `linux/amd64`; ARM hosts need compatible Docker
cross-platform emulation. No cloud infrastructure is deployed during container setup.

## Configure and Deploy

Run from the repository root inside the dev container:

```bash
az login
az account set --subscription "<your-subscription-id>"
cp simple_agent/azure/infra/foundry_base/environments/example.tfvars \
  simple_agent/azure/infra/foundry_base/environments/dev.tfvars
cp simple_agent/azure/infra/hosted_agent/environments/example.tfvars \
  simple_agent/azure/infra/hosted_agent/environments/dev.tfvars
```

Edit the local environment files for your stack name, region, model deployment,
capacity, and safety policy. The example model and region are sample values;
verify current availability, quota, and Hosted Agent support in your subscription.
The deployment identity needs permission to create the resources and role assignments.
The container does not mount host Azure credentials; authenticate again after rebuilding.

```bash
simple_agent/azure/deploy/deploy.sh --environment dev
```

This runs, in order: a `foundry_base` plan/apply, a `docker build` and
`docker push` to the ACR it created, and a `hosted_agent` plan/apply for the
pushed image tag. Each Terraform stage prompts for confirmation before
applying (set `AUTO_APPROVE=1` to skip prompts); the image push prompts
separately. Pass `--stage base|image|agent` to run a single stage, or `--tag`
to pin an explicit image tag instead of the computed git SHA. Review every
plan: deployment creates billable Azure resources. Use an immutable image tag;
`latest` is rejected, but registry-level tag immutability is not enforced.
A successful apply is not an invocation smoke test; verify the hosted agent in
Foundry before relying on it.

Terraform uses local state by default, one state file per stack. State and
real environment files are ignored; use an appropriately secured remote
backend for shared deployments. Do not put credentials in Terraform files or
commit generated state or plans.

## Copilot Agents and MCP

Choose **Azure Expert** or **Terraform** in the VS Code Copilot agent picker.
Azure Expert delegates Terraform file edits to Terraform. Both require explicit
approval before infrastructure mutations.

Use **MCP: List Servers** to review and start the workspace servers:

| Server | Purpose | Requirement |
|---|---|---|
| `terraform` | Provider and module documentation | Docker; image `hashicorp/terraform-mcp-server:1.2.0` |
| `microsoft-learn` | Official Microsoft documentation | HTTPS access to Microsoft Learn |
| `github` | Repository operations | GitHub authentication prompted by VS Code |

Review trust and tool-approval prompts. GitHub CLI authentication (`gh auth login`)
is separate from the VS Code GitHub MCP session. No tokens are embedded in the
configuration, and no additional Azure MCP extension is required by these agents.

## Validation

```bash
terraform -chdir=simple_agent/azure/infra/foundry_base init -backend=false
terraform -chdir=simple_agent/azure/infra/foundry_base fmt -check -recursive
terraform -chdir=simple_agent/azure/infra/foundry_base validate

terraform -chdir=simple_agent/azure/infra/hosted_agent init -backend=false
terraform -chdir=simple_agent/azure/infra/hosted_agent fmt -check -recursive
terraform -chdir=simple_agent/azure/infra/hosted_agent validate

.venv/bin/python -m pip check
```

These checks do not deploy resources or prove runtime invocation succeeds.

## Files

- [Azure infrastructure](simple_agent/azure/infra/README.md)
- [Deployment script](simple_agent/azure/deploy/deploy.sh)
- [Azure Expert](.github/agents/azure.agent.md)
- [Terraform agent](.github/agents/terraform.agent.md)
- [MCP configuration](.vscode/mcp.json)
- [Development container](.devcontainer/devcontainer.json)

Extracted from an Azure multi-cloud reference implementation.
Only the Azure implementation and necessary shared deployment helpers are included;
the research journal, skills, comparison UI, and other cloud implementations are excluded.