#!/bin/bash
set -e

# Environment variables passed from Terraform
AGENT_ID="${AGENT_ID}"
ACTION_GROUPS="${ACTION_GROUPS}"
AWS_REGION="${AWS_REGION}"
AWS_PROFILE="${AWS_PROFILE}"
FIND_GROUPS="${FIND_GROUPS:-false}"

echo "Starting Bedrock Agent cleanup process..."
echo "Agent ID: ${AGENT_ID}"
echo "Region: ${AWS_REGION}"
echo "Profile: ${AWS_PROFILE}"

# If FIND_GROUPS is true, dynamically find action groups
if [ "${FIND_GROUPS}" == "true" ]; then
    echo "Dynamically finding action groups for agent ${AGENT_ID}..."
    ACTION_GROUP_IDS=$(aws bedrock-agent list-agent-action-groups \
        --agent-id "${AGENT_ID}" \
        --agent-version DRAFT \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" \
        --query 'actionGroupSummaries[].actionGroupId' \
        --output json 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")

    if [ -n "${ACTION_GROUP_IDS}" ]; then
        ACTION_GROUP_IDS=(${ACTION_GROUP_IDS})
        echo "Found ${#ACTION_GROUP_IDS[@]} action group(s)"
    else
        ACTION_GROUP_IDS=()
        echo "No action groups found"
    fi
else
    # Parse action groups JSON array from environment
    ACTION_GROUP_IDS=($(echo "${ACTION_GROUPS}" | jq -r '.[]' 2>/dev/null || echo ""))
fi

# Function to delete action group with retries
delete_action_group() {
    local ag_id="$1"
    if [ -z "${ag_id}" ] || [ "${ag_id}" == "null" ]; then
        echo "Skipping empty action group ID"
        return 0
    fi

    echo "Deleting action group: ${ag_id}"
    for attempt in 1 2 3; do
        if aws bedrock-agent delete-agent-action-group \
            --agent-id "${AGENT_ID}" \
            --agent-version DRAFT \
            --action-group-id "${ag_id}" \
            --region "${AWS_REGION}" \
            --profile "${AWS_PROFILE}" \
            --skip-resource-in-use-check 2>/dev/null; then
            echo "Successfully deleted action group: ${ag_id}"
            return 0
        fi
        echo "Attempt ${attempt} failed for action group ${ag_id}, retrying..."
        sleep 2
    done
    echo "Warning: Could not delete action group ${ag_id} after 3 attempts"
    return 0  # Don't fail the entire cleanup
}

# Delete all action groups first
echo "Step 1: Deleting action groups..."
for ag_id in "${ACTION_GROUP_IDS[@]}"; do
    delete_action_group "${ag_id}"
done

# Wait for AWS to process action group deletions
echo "Waiting for action groups to be processed..."
sleep 3

# Delete the agent
echo "Step 2: Deleting agent ${AGENT_ID}..."
for attempt in 1 2 3; do
    if aws bedrock-agent delete-agent \
        --agent-id "${AGENT_ID}" \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" \
        --skip-resource-in-use-check 2>/dev/null; then
        echo "Successfully initiated agent deletion"
        exit 0
    fi
    echo "Attempt ${attempt} failed for agent deletion, retrying..."
    sleep 3
done

echo "Warning: Could not delete agent after 3 attempts, but continuing..."
exit 0  # Don't fail terraform destroy