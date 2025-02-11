# Clean up

> **Important Notice**: Only proceed with cleanup when you are absolutely certain that you no longer need the resources deployed by this workshop. These resources can be valuable for future reference, testing, or development. If you're unsure, it's recommended to keep the resources in your account.

If you've decided to remove the resources, follow these steps carefully:

1. Destroy the stacks:

   ```bash
   pnpm cdk_infra:destroy
   ```
   This command will destroy the CDK application without asking for confirmation.

2. Verify deletion in [CloudFormation](https://console.aws.amazon.com/cloudformation)

3. Manually force delete any remaining resources if necessary.
