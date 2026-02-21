"""Minimal Strands agent for AgentCore Runtime."""
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent
from strands.models import BedrockModel

app = BedrockAgentCoreApp()

model = BedrockModel(model_id="us.amazon.nova-lite-v1:0")
agent = Agent(model=model, system_prompt="You are a helpful assistant.")


@app.entrypoint
def invoke(payload: dict) -> dict:
    prompt = payload.get("prompt", "")
    if not prompt:
        return {"error": "No prompt provided", "status": "error"}
    response = agent(prompt)
    return {"response": str(response), "status": "success"}


if __name__ == "__main__":
    app.run()
