<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/le-ref-architecture-doc/master/docs/assets/images/logos/binbash-leverage-banner.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/.github/master/assets/images/binbash-aws-startups.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

# Leverage Reference Architecture: Terraform AWS Infrastructure

## Overview
This repository contains all Terraform configuration files used to create Binbash Leverage Reference AWS Cloud
Solutions Architecture.

## Documentation
Check out the [Binbash Leverage Reference Architecture Official Documentation](https://leverage.binbash.com.ar).

---

## Getting Started

In order to get the full automated potential of the
[Binbash Leverage DevOps Automation Code Library](https://leverage.binbash.co/user-guide/infra-as-code-library/overview)  
you should follow the steps below:

1. [Install](https://leverage.binbash.co/user-guide/leverage-cli/installation/) and use the `leverage cli`
2. Update your [configuration files](https://leverage.binbash.co/user-guide/ref-architecture-aws/configuration/#configuration-files)
3. Review and assure you meet all the Terraform AWS pre-requisites
   1. AWS Credentials (Including your MFA setup)
      1. Run `leverage aws sso login` to setup the credentials.
    2. [Initialize your accounts Terraform State Backend](https://leverage.binbash.co/user-guide/ref-architecture-aws/tf-state/)

4. Follow the [standard `leverage cli` workflow](https://leverage.binbash.co/user-guide/ref-architecture-aws/workflow/)
    1. Get into the folder that you need to work with (e.g. [`/security/global/base-identities`](https://github.com/binbashar/le-tf-infra-aws/tree/master/security/global/base-identities) )
    2. Run `leverage terraform init`
    3. Make whatever changes you need to make
    4. Run `leverage terraform plan` (if you only mean to preview those changes)
    5. Run `leverage terraform apply` (if you want to review and likely apply those changes)
    6. Repeat for any desired Reference Architecture layer

### Consideration

The `backend.tfvars` will inject the profile name with the necessary permissions that Terraform will
use to make changes on AWS.
* Such profile is usually one that relies on another profile to assume a role to get access to
  each corresponding account [( AWS IAM: users, groups, roles & policies )](https://leverage.binbash.co/user-guide/ref-architecture-aws/features/identities/identities/)
* Read the following [AWS page doc](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html)
  to understand how to set up a profile to assume a role


## AI Development Configs

This repository includes pre-configured settings for AI-powered development tools to enhance productivity and maintain consistency across the codebase.

### Supported IDE/AI Tools

- **[Cursor IDE](.cursor/)** - AI-first code editor with project-specific rules
  - [`.cursor/rules/`](.cursor/rules/) - Markdown rules for OpenTofu/Terraform best practices
  - [`.cursor/mcp.json`](.cursor/mcp.json) - MCP server configurations for AWS and Terraform documentation
  
- **[Kiro IDE](.kiro/)** - AI development environment with steering documents
  - [`.kiro/steering/`](.kiro/steering/) - Comprehensive documentation about the project structure, tech stack, and best practices
  - [`.kiro/settings/mcp.json`](.kiro/settings/mcp.json) - MCP configurations for enhanced AWS/Terraform support

- **[Claude Code](CLAUDE.md)** - Anthropic's AI coding assistant
  - [`CLAUDE.md`](CLAUDE.md) - Project instructions and context for Claude
  - [`.mcp.json`](.mcp.json) - Root-level MCP server configurations

### Usage

These configurations are automatically loaded when you open the project in the respective IDE/tool. They provide:
- Context-aware code suggestions aligned with Leverage best practices
- AWS and Terraform/OpenTofu specific assistance
- Consistent code formatting and structure guidelines
- Direct access to AWS documentation and Terraform registry

### Learn More

- [Cursor Documentation](https://cursor.sh/docs)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

## Project context commands
```shell
╭─    ~/ref-architecture/le-tf-infra-aws  on   master · ✔  at 12:13:36 
╰─ leverage

Usage: leverage [OPTIONS] COMMAND [ARGS]...

  Leverage Reference Architecture projects command-line tool.

Options:
  -f, --filename TEXT  Name of the build file containing the tasks
                       definitions.  [default: build.py]
  -l, --list-tasks     List available tasks to run.
  -v, --verbose        Increase output verbosity.
  --version            Show the version and exit.
  -h, --help           Show this message and exit.

Commands:
  credentials  Manage AWS cli credentials.
  project      Manage a Leverage project.
  run          Perform specified task(s) and all of its dependencies.
  terraform    Run Terraform commands in a custom containerized...
  tf           Run Terraform commands in a custom containerized...
```

## Layer context Terraform commands
```shell
╭─    ~/ref-architecture/le-tf-infra-aws  on   master · ✔  at 12:13:36 
╰─ leverage terraform
Usage: leverage terraform [OPTIONS] COMMAND [ARGS]...

  Run Terraform commands in a custom containerized environment that provides
  extra functionality when interacting with your cloud provider such as
  handling multi factor authentication for you. All terraform subcommands that
  receive extra args will pass the given strings as is to their corresponding
  Terraform counterparts in the container. For example as in `leverage
  terraform apply -auto-approve` or `leverage terraform init -reconfigure`

Options:
  -h, --help  Show this message and exit.

Commands:
  apply     Build or change the infrastructure in this layer.
  aws       Run a command in AWS cli.
  destroy   Destroy infrastructure in this layer.
  format    Check if all files meet the canonical format and rewrite them...
  import    Import a resource.
  init      Initialize this layer.
  output    Show all output variables of this layer.
  plan      Generate an execution plan for this layer.
  shell     Open a shell into the Terraform container in this layer.
  validate  Validate code of the current directory.
  version   Print version.
```

# Release Management
## [**Reference Architecture | Releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
