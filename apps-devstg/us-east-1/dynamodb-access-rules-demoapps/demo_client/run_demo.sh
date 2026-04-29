#!/bin/bash

# --- Configuration ---
PYTHON_SCRIPT="main.py" # ⚠️ Replace with the actual name of your Python script
# ---------------------

echo "🚀 Fetching Terraform outputs and setting environment variables..."

cd /home/jdelacamara/Dev/work/BinBash/code/le-tf-infra-aws/apps-devstg/us-east-1/research-dynamodb-access-rules/
# Run 'terraform output -json' and use 'jq' to iterate over the key-value pairs.
# -r: raw output, to get plain strings without quotes.
# .[] | @json: formats each object into a JSON string, which is easier to parse.
LEVERAGE_OUTPUT=$(leverage tf output -json | \
  grep -v '^\[[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\.[0-9]\{3\}\] INFO' | \
  jq -r 'to_entries[] | {key: .key, value: .value.value} | @json')

ENV_CONTENT=$(echo $LEVERAGE_OUTPUT | jq -r '. | "\(.key| ascii_upcase)=\(.value)"')

echo "---"
echo "📂 Changing directory back..."
cd -
echo "$ENV_CONTENT"
if [ -n "$ENV_CONTENT" ]; then
    # Overwrite/Create the .env file with the accumulated content
    echo -e "$ENV_CONTENT" > .env
    echo "🎉 All Terraform outputs saved to **.env** file."

    # NOTE: You MUST source the .env file if you want the environment variables
    #       to be available to the current shell and subsequent commands.
    # source .env

    # Call your Python script (assuming it uses the .env file or the sourced variables)
    # echo "🐍 Running the Python script: $PYTHON_SCRIPT"
    # python "$PYTHON_SCRIPT"
else
    echo "⚠️ Warning: No Terraform outputs were found to save."
    exit 1
fi

# --- Execution ---
echo "---"
echo "🐍 Running the Python script: $PYTHON_SCRIPT"
# You might want to use 'python3' instead of 'python' depending on your environment
python "$PYTHON_SCRIPT"

# Optional: Clean up environment variables after execution if needed (not done here for simplicity)

# Check the exit status of the Python script
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "🎉 Python script executed successfully."
else
    echo "❌ Python script failed with exit code $EXIT_CODE."
fi
