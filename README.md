<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/le-ref-architecture-doc/master/docs/assets/images/logos/binbash-leverage-banner.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/.github/master/assets/images/binbash-aws-startups.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

# Leverage Reference Architecture: OpenTofu/Terraform AWS Infrastructure

## Overview
This repository contains all OpenTofu/Terraform configuration files used to create Binbash Leverage Reference AWS Cloud
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
3. Review and assure you meet all the OpenTofu/Terraform AWS pre-requisites
   1. AWS Credentials (Including your MFA setup)
      1. Run `leverage aws sso login` to setup the credentials.
    2. [Initialize your accounts OpenTofu/Terraform State Backend](https://leverage.binbash.co/user-guide/ref-architecture-aws/tf-state/)

4. Follow the [standard `leverage cli` workflow](https://leverage.binbash.co/user-guide/ref-architecture-aws/workflow/)
    1. Get into the folder that you need to work with (e.g. [`/security/global/base-identities`](https://github.com/binbashar/le-tf-infra-aws/tree/master/security/global/base-identities) )
    2. Run `leverage tf init`
    3. Make whatever changes you need to make
    4. Run `leverage tf plan` (if you only mean to preview those changes)
    5. Run `leverage tf apply` (if you want to review and likely apply those changes)
    6. Repeat for any desired Reference Architecture layer

### Consideration

The `backend.tfvars` will inject the profile name with the necessary permissions that OpenTofu/Terraform will
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
  - [`.cursor/mcp.json`](.cursor/mcp.json) - MCP server configurations for AWS and OpenTofu/Terraform documentation

- **[Kiro IDE](.kiro/)** - AI development environment with steering documents
  - [`.kiro/steering/`](.kiro/steering/) - Comprehensive documentation about the project structure, tech stack, and best practices
  - [`.kiro/settings/mcp.json`](.kiro/settings/mcp.json) - MCP configurations for enhanced AWS/OpenTofu/Terraform support

- **[Claude Code](CLAUDE.md)** - Anthropic's AI coding assistant
  - [`CLAUDE.md`](CLAUDE.md) - Project instructions and context for Claude
  - [`.mcp.json`](.mcp.json) - Root-level MCP server configurations

### Usage

These configurations are automatically loaded when you open the project in the respective IDE/tool. They provide:
- Context-aware code suggestions aligned with Leverage best practices
- AWS and OpenTofu/Terraform specific assistance
- Consistent code formatting and structure guidelines
- Direct access to AWS documentation and OpenTofu/Terraform registry

### Learn More

- [Cursor Documentation](https://cursor.sh/docs)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

## Project-wide Leverage CLI commands
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
  credentials  Manage AWS CLI credentials.
  project      Manage a Leverage project.
  run          Perform specified task(s) and all of its dependencies.
  terraform    Run Terraform commands through the Leverage CLI
  tofu         Run OpenTofu commands through the Leverage CLI
  tf           Short form of the "tofu" command
```

## Layer-wide Leverage CLI OpenTofu commands
```shell
╭─    ~/ref-architecture/le-tf-infra-aws  on   master · ✔  at 12:13:36 
╰─ leverage tofu
Usage: leverage tofu [OPTIONS] COMMAND [ARGS]...

  Run OpenTofu commands through the Leverage CLI in order to obtain
  additional functionality such as automatic AWS credentials injection or
  config files autoloading.
  All OpenTofu subcommands and their flags/arguments will be passed on to
  the OpenTofu binary. For example the following:
    - leverage tf init -reconfigure
    - leverage tofu apply -auto-approve

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
  shell     Open a shell into the Leverage toolbox container in this layer (deprecated).
  validate  Validate code of the current directory.
  version   Print version.
```

# Release Management
## [**Reference Architecture | Releases**](https://github.com/binbashar/le-tf-infra-aws/releases)
