# simple-hosted-agent-deploy-azapi

Deploy a Python hosted agent to Microsoft Foundry using Terraform and the
Azure AzAPI provider. Includes the Azure Expert and Terraform Copilot agents,
MCP configuration, and an Azure-focused development container.

## Architecture

Terraform provisions a resource group, Azure Container Registry, Log Analytics,
Application Insights, a Foundry account and project, model deployment, content
safety policy, connections, role assignments, and the logical hosted agent.
The hosted agent uses `azapi_data_plane_resource` with
`Microsoft.Foundry/agents@v1`. Docker builds and pushes the application image
outside Terraform; Foundry manages the agent version history.

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

Only open trusted repositories with host Docker access: that access is highly
privileged. Image builds target `linux/amd64`; ARM hosts need compatible Docker
cross-platform emulation. No cloud infrastructure is deployed during container setup.

## Configure and Deploy

Run from the repository root inside the dev container:

```bash
az login
az account set --subscription "<your-subscription-id>"
cp simple_agent/azure/infra/environments/example.tfvars \
  simple_agent/azure/infra/environments/dev.tfvars
```

Edit the local environment file for your stack name, region, model deployment,
capacity, and safety policy. The example model and region are sample values;
verify current availability, quota, and Hosted Agent support in your subscription.
The deployment identity needs permission to create the resources and role assignments.
The container does not mount host Azure credentials; authenticate again after rebuilding.

```bash
./simple_agent/azure/deploy/deploy.sh --env dev
```

On first use the script prompts to bootstrap ACR, builds and pushes the image,
then prompts to apply the full Terraform plan. Subsequent runs reuse the registry.
Image tags are Git-derived and `latest` is rejected; registry-level tag immutability
is not enforced. Review each plan: deployment creates billable Azure resources.
A successful apply is not an invocation smoke test; verify the hosted agent in
Foundry before relying on it.

Terraform uses local state by default. State and real environment files are
ignored; use an appropriately secured remote backend for shared deployments.
Do not put credentials in Terraform files or commit generated state or plans.

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
terraform -chdir=simple_agent/azure/infra init -backend=false
terraform -chdir=simple_agent/azure/infra fmt -check -recursive
terraform -chdir=simple_agent/azure/infra validate
bash -n simple_agent/azure/deploy/deploy.sh
.venv/bin/python -m pip check
```

These checks do not deploy resources or prove runtime invocation succeeds.

## Files

- [Azure infrastructure](simple_agent/azure/infra/README.md)
- [Deployment workflow](simple_agent/azure/deploy/README.md)
- [Azure Expert](.github/agents/azure.agent.md)
- [Terraform agent](.github/agents/terraform.agent.md)
- [MCP configuration](.vscode/mcp.json)
- [Development container](.devcontainer/devcontainer.json)

Extracted from the Azure implementation in
[Azure-Samples/ProjectChopped](https://github.com/Azure-Samples/ProjectChopped).
Only the Azure implementation and necessary shared deployment helpers are included;
the research journal, skills, comparison UI, and other cloud implementations are excluded.