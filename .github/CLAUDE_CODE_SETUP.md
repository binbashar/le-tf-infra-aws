# Claude Code GitHub Action Setup

This document explains how to use the Claude Code GitHub Action integrated into this Binbash Leverage Reference Architecture repository.

## Overview

The Claude Code GitHub Action provides AI-powered assistance for infrastructure development, code reviews, and issue resolution. It's specifically configured for AWS infrastructure using Terraform/OpenTofu with the Leverage CLI.

## Features

- **Intelligent Code Reviews**: Automatic analysis of Terraform/OpenTofu changes
- **Infrastructure Assistance**: Expert guidance on AWS best practices
- **Issue Resolution**: Help with troubleshooting and problem-solving
- **Interactive Support**: Respond to @claude mentions in PRs and issues

## Usage

### In Pull Requests

When you create or update a PR, Claude will automatically:
1. Analyze infrastructure changes
2. Review for security implications
3. Check cross-layer dependencies
4. Validate against AWS Well-Architected Framework
5. Provide specific feedback and recommendations

### Interactive Commands

Mention `@claude` in any PR comment or issue to get assistance:

```
@claude analyze this terraform plan for security issues
@claude explain the dependencies between these layers
@claude suggest cost optimizations for this infrastructure
@claude review this configuration against best practices
```

### Specific Use Cases

#### Infrastructure Review
```
@claude review this VPC configuration for security best practices
```

#### Dependency Analysis
```
@claude what are the dependencies for deploying the k8s-eks layer?
```

#### Troubleshooting
```
@claude help me resolve this terraform state lock issue
```

#### Cost Optimization
```
@claude analyze the cost impact of these changes
```

## Configuration

### Environment Variables

The action uses these environment variables:
- `ANTHROPIC_API_KEY`: Required API key for Claude access (stored in repository secrets)

### Persona Configuration

Claude is configured with an expert DevOps persona focusing on:
- AWS infrastructure and security
- Terraform/OpenTofu best practices
- Binbash Leverage Reference Architecture
- Multi-account patterns
- Cost optimization
- Compliance and governance

## Integration with Existing Workflows

This Claude Code action works alongside existing workflows:

### AI-Powered Infrastructure Validation
- Complements the existing `ai-layer-validation.yml` workflow
- Provides deeper, interactive analysis beyond automated validation
- Offers personalized assistance based on specific questions

### Leverage CLI Testing
- Works with `leverage-cli-test.yml` for comprehensive testing
- Provides guidance on resolving test failures
- Helps optimize test workflows

### Infracost Integration
- Enhances cost analysis from `infracost.yml`
- Provides recommendations for cost optimization
- Explains cost implications of changes

## Best Practices

### When to Use @claude

✅ **Good use cases:**
- Complex infrastructure design questions
- Security review requests
- Dependency analysis
- Troubleshooting specific issues
- Best practice guidance
- Cost optimization advice

❌ **Avoid for:**
- Simple syntax questions (use documentation)
- Emergency production issues (use standard procedures)
- Sensitive credential handling

### Writing Effective Prompts

1. **Be specific**: Include context about the layer, account, or issue
2. **Provide details**: Share error messages, logs, or specific files
3. **State your goal**: Explain what you're trying to achieve
4. **Ask follow-ups**: Engage in conversation for deeper insights

### Examples of Good Prompts

```markdown
@claude I'm getting a state lock error in apps-devstg/us-east-1/k8s-eks.
The error message is: "Error acquiring the state lock: ConditionalCheckFailedException"
Can you help me resolve this safely?
```

```markdown
@claude Please review the security group configuration in the base-network layer.
I want to ensure we're following least privilege principles while allowing necessary access for EKS.
```

```markdown
@claude What's the recommended order for deploying layers in the apps-devstg account?
I'm setting up a new environment and want to avoid dependency issues.
```

## Permissions

The Claude Code action has these permissions:
- **contents: read** - Access to repository code
- **pull-requests: write** - Comment on PRs
- **issues: write** - Comment on issues

## Security Considerations

- API keys are stored securely in GitHub repository secrets
- Claude only has read access to repository contents
- No sensitive data is transmitted beyond what's visible in the repository
- Comments are public and visible to all repository users

## Troubleshooting

### Common Issues

1. **No response from @claude**
   - Check if ANTHROPIC_API_KEY is set in repository secrets
   - Verify the action is enabled in repository settings
   - Ensure you're mentioning `@claude` in the comment

2. **Limited or generic responses**
   - Provide more context about your specific situation
   - Include relevant error messages or logs
   - Specify which layer or account you're working with

3. **Action not triggering**
   - Check workflow file syntax in `.github/workflows/claude-code.yml`
   - Verify repository permissions allow GitHub Actions
   - Check action logs in the repository's Actions tab

### Getting Help

If you encounter issues with the Claude Code action:
1. Check the Actions tab for workflow run details
2. Review this documentation for proper usage
3. Contact the repository administrators for configuration issues
4. Use the existing `gh-issue-chore-deps.md` command for other support needs

## Integration with Claude Code CLI

This GitHub Action complements the local Claude Code CLI experience:
- Use local Claude Code for development and testing
- Use GitHub Action Claude for reviews and collaboration
- Save sessions locally with `save-session.md` command
- Load contexts with `load-session.md` command
- Document prompts with `save-prompts.md` command

The combination provides a complete AI-assisted infrastructure development workflow.