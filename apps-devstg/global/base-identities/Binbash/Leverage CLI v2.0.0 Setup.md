# Leverage CLI v2.0.0 Setup - OpenTofu

**Successfully configured Leverage CLI v2.0.0 with OpenTofu support for le-tf-infra-aws**

## Key Issues & Solutions

- **Docker connectivity failure** → Used local repo v2.0.0 + Python 3.12 venv + Docker settings
- **Python 3.13 incompatibility** → Created new venv with Python 3.12
- **Version 1.12.x bugs** → Upgraded to development v2.0.0 (as confirmed by Slack)
- **Environment variables** → Required `unset SSH_AUTH_SOCK` + explicit `DOCKER_HOST`

## Docker Desktop Configuration

**Required settings from [troubleshooting guide](https://leverage.binbash.co/user-guide/troubleshooting/general/#macos-after-docker-desktop-upgrade):**
- Enable "Use Docker Compose V2" 
- Disable "Use gRPC FUSE for file sharing"
- Set socket path: `unix:///Users/lgallard/.docker/run/docker.sock`
- Ensure Docker Desktop is running before using Leverage

## Final Configuration

- **Leverage CLI**: v2.0.0 (local development version)
- **OpenTofu**: v1.6.2  
- **Toolbox**: `1.6.2-tofu-0.3.0` (tofu-only by default)
- **Python**: 3.12 virtual environment
- **Config**: Updated `build.env` from `TERRAFORM_IMAGE_TAG` to `TF_IMAGE_TAG`

## Activation Script

```bash
# Source the activation script
source ~/git/binbash/activate-leverage.sh

# Or manual activation:
source ~/.leverage-venv-312/bin/activate
unset SSH_AUTH_SOCK
export DOCKER_HOST=unix:///Users/lgallard/.docker/run/docker.sock
```

## Essential Commands

```bash
# OpenTofu (primary)
leverage tofu version
leverage tf init          # tf = tofu alias in v2.0.0
leverage tofu plan

# Terraform (configurable with different image)
leverage terraform version # Requires terraform-enabled toolbox

# AWS Authentication  
leverage aws configure sso
leverage aws sso login

# Deactivation
deactivate
unset DOCKER_HOST
```

## Notes
- `leverage terraform` requires terraform-enabled toolbox (configurable via `TF_IMAGE`)
- Default toolbox is tofu-only, but terraform support can be added
- Must run from layer directories (e.g., `/apps-devstg/global/base-identities/`)
- Docker Desktop required with proper socket permissions and configuration above