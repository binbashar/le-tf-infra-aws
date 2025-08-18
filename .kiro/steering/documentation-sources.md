# Documentation Sources and References

## Source of Truth

All code, reviews, and recommendations **must** align with the following official resources:

### Primary Documentation
- **[Leverage Documentation](https://leverage.binbash.co)** - Main source for framework usage, architecture, and best practices
- **[Leverage High-Level Characteristics](https://www.binbash.co/leverage)** - Overview of Leverage capabilities and features
- **[OpenTofu Reference Architecture Code](https://github.com/binbashar/le-tf-infra-aws)** - The main OpenTofu codebase for AWS infrastructure
- **[Leverage CLI](https://github.com/binbashar/leverage)** - CLI tool for orchestrating the Reference Architecture ([PyPI package](https://pypi.org/project/leverage))

### Module Library
- **[Binbash OpenTofu Module Library](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile)** - Complete module library for the Leverage Infrastructure as Code ecosystem
- Always check this Makefile for the latest list of available modules
- Prefer these modules over creating custom solutions

### External References
- **[OpenTofu Registry](https://registry.terraform.io)** - Official OpenTofu provider and module documentation
- **[AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected)** - AWS best practices and design principles
- **[Digger](https://digger.dev)** - CI/CD integration for OpenTofu workflows

## Usage Guidelines

### For AI Assistants
- Use the above documentation and repositories as the primary source of truth for any code generation, review, or architectural advice related to Leverage
- When referencing modules, always check the Makefile for the latest list
- Ensure all recommendations align with the AWS Well-Architected Framework and Leverage conventions
- Reference these sources in code comments and PR descriptions

### For Development Teams
- Consult these resources before implementing new infrastructure components
- Follow the patterns and examples provided in the reference architecture
- Contribute improvements back to the upstream repositories when possible
- Document any deviations from standard patterns with clear justification

### For Code Reviews
- Reviewers should verify that all changes align with Leverage conventions
- Reference specific documentation sections when providing feedback
- Ensure compliance with AWS Well-Architected Framework principles
- Check that appropriate Leverage modules are being used

## Key Integration Points

### Module Selection Process
1. Check the [Binbash module Makefile](https://github.com/binbashar/le-dev-tools/blob/master/terraform/Makefile) first
2. Review the [reference architecture examples](https://github.com/binbashar/le-tf-infra-aws) for usage patterns
3. Consult the [Leverage documentation](https://leverage.binbash.co) for best practices
4. Only create custom modules if no suitable Leverage module exists

### Architecture Decisions
- Follow the [Leverage directory structure](https://leverage.binbash.co/user-guide/ref-architecture-aws/dir-structure)
- Implement patterns from the [reference architecture](https://github.com/binbashar/le-tf-infra-aws)
- Align with [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected) principles
- Use [Leverage CLI](https://github.com/binbashar/leverage) for all operations

### Continuous Learning
- Stay updated with Leverage framework releases and updates
- Monitor the reference architecture repository for new patterns and improvements
- Participate in the Leverage community for knowledge sharing
- Contribute documentation improvements and examples back to the project

## Compliance and Standards

### Code Quality
- All code must follow patterns established in the reference architecture
- Use Leverage CLI for consistent tooling and workflows
- Implement security practices as documented in Leverage guidelines
- Follow naming conventions and tagging strategies from the reference implementation

### Documentation Requirements
- Reference official Leverage documentation in all architectural decisions
- Include links to relevant sections of the reference architecture
- Document any custom implementations with clear reasoning
- Maintain consistency with established Leverage patterns and terminology