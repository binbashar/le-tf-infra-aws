# AWS Step Functions: Lambda, DynamoDB, API Gateway, and Callbacks Integration

## Overview
This is based on this post: https://aws.amazon.com/blogs/compute/integrating-aws-step-functions-callbacks-and-external-systems/

Refer to the post above to learn about the purpose, architecture details and more.

## Setting up
1. Set up the AWS credentials.
2. Run Terraform init, plan, and apply.
3. You will be prompted for an email address. Use one that you own so you can perform the following actions:
  1. Receive the subscription confirmation email. You should receive this one soon after successfully provisioning the resources defined in this folder.
  2. Receive new shipping order notificationss.
  3. Cancel your email subscription.

## Testing out the worklow
1. Add sample item to the DynamoDB table. Refer to the "Orders table input example" sub-section.
2. Start the workflow. Refer to the "Start workflow example" sub-section.
3. Verify that you got the order data in your inbox.
4. Call the externalCallback API Gateway endpoint. Refer to the "Callback trigger example" sub-section.
5. Verify that the workflow completed its execution.

### Orders table input example
You can add an item similar to the one below:
```
{
  "order_id": {
    "S": "order-123"
  },
  "order_contents": {
    "M": {
      "shoes": {
        "S": "5"
      },
      "socks": {
        "S": "2"
      }
    }
  }
}
```

### Start workflow example
Use the following input as an example:
```
{
    "order_id": "order-123"
}
```

### Callback trigger example
The easiest option is to trigger the callback through the AWS Management Console, which can be done as follows:
- Navigate to the API Gateway page
- Find the OrderApi and click on it
- Then click on Stages under the left menu
- Then, under Resources, expand the / path, then the /externalCallback path, and finally click on the POST method
- Locate the Test tab
- In the Request Body field enter the expected JSON payload (you can find an example of that in the `utils/run.py` file)

Now, if you prefer to try a more involved option, open the file `utils/run.py` and follow the instructions in the comments to understand how to run it.

## Tearing up
Running Terraform destroy should destroy all resources except the Email Subscription to the shipping service SNS topic which must be done by the user that owns the subscribed email (via the unsubscribe link, present in every email sent by SNS).
