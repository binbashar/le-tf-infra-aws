# EKS DemoApps
This documentation describes how we set up the demo apps on EKS.

## Orchestration
These are the steps to orchestrate the demo app. They are intended for AI harnesses like Claude Code to follow.

### Pre-requisites
- The code is heavily organized around the Binbash Leverage Framework -- it follows its conventions.
- EKS code is organized in the following sublayers:
    - `network`: VPC resources.
    - `cluster`: EKS cluster and nodes.
    - `identities`: EKS IRSA policies and roles.
    - `addons`: EKS add-ons.
    - `k8s-components`: cluster components for networking, monitoring, security, scaling, ci/cd, and more.
    - `k8s-workloads`: demo apps.
- The Binbash Leverage CLI must be installed and available in the system PATH.
- The same applies to `kubectl` and the `aws` CLI -- they are useful for troubleshooting.
- The code has been migrated to OpenTofu, therefore keep in mind the following:
    - You must use `leverage tofu *` commands for init, plan, and apply.
    - Other commands are not proxied through `leverage`, just run `tofu` (which must be installed for that to work)
- Since the cluster API is configured to be privately accessible, VPN access is required. Prompt the user that as a reminder before you continue.

### Step 1
- Go to the `network` sublayer.
- Enable the NAT Gateway.
- Plan, verify, and apply.
- Applying takes usually takes 2-3 minutes. Be prepared.
- If the NAT Gateway is already deployed, that's fine, notify the user and move on.

### Step 2
- Go to the `cluster` sublayer.
- Plan, verify, and apply.
- Applying takes usually takes 15-25 minutes. Really prepare for that.
- This is the key step that requires VPN access. If that has not been covered applying may not succeed.

### Step 3
- Go to the `identities` sublayer.
- Plan, verify, and apply.

### Step 4
- Go to the `addons` sublayer.
- Plan, verify, and apply.

### Step 5
- Go to the `k8s-components` sublayer.
- This sublayer usually requires more involvement from the user to customize which components he wants to deploy.
- Prompt the user if he would like an standard setup (using `terraform.tfvars` defaults) or a custom one. If he chooses the latter, guide the user through the process of choosing which components to enable and install.
- Plan, verify, and apply.
- Applying this might take several minutes, depending on the components that need to be installed. Really prepare for that.
- There might be dependencies between some of the components. For instance, maybe an autoscaler will be needed first if there is another component that deploys too many pods or pods that require high resources usage.

### Step 6
- Go to the `k8s-workloads` sublayer.
- This layer is optional. Prompt the user on whether he would like to install it.
- This layer depends on several cluster components in order to fully work.
- The endpoints created for the demo apps are private so VPN access is required.
- Plan, verify, and apply.
