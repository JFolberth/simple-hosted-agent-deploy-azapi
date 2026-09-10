import asyncio
import logging
import os

from agent_framework import Agent
from agent_framework.foundry import FoundryChatClient
from agent_framework_foundry_hosting import ResponsesHostServer
from azure.identity import DefaultAzureCredential


async def main():
    credential = DefaultAzureCredential()
    # Foundry injects the project endpoint; Terraform supplies the model deployment name.
    client = FoundryChatClient(
        project_endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
        credential=credential,
    )
    agent = Agent(
        client=client,
        instructions="You are a helpful assistant. Answer questions clearly and concisely.",
        default_options={"store": False},
    )
    server = ResponsesHostServer(agent)
    await server.run_async()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
