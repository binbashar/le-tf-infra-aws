# Product Overview

This repository contains the **Binbash Leverage Reference Architecture** - a comprehensive OpenTofu-based AWS infrastructure solution that implements enterprise-grade cloud architecture patterns.

## Purpose
- Provides a complete multi-account AWS infrastructure setup using OpenTofu (migrated from Terraform)
- Implements security, networking, and application layers following AWS best practices
- Serves as a reference implementation for scalable cloud infrastructure
- Supports multiple environments (development, staging, production) across different AWS accounts

## Key Features
- **Multi-account AWS organization structure**: management, security, shared, network, apps-devstg, apps-prd, data-science
- **Layered architecture** with clear separation of concerns and dependencies
- **Automated infrastructure deployment** using Leverage CLI with OpenTofu
- **Built-in security compliance** and monitoring across all layers
- **Container orchestration support** (ECS, EKS) for modern workloads
- **Data lake and analytics capabilities** including ML/AI workloads with AWS Bedrock
- **Comprehensive backup and disaster recovery** strategies
- **Cost optimization** with built-in Infracost integration
- **Atlantis integration** for automated workflow management

## Advanced Capabilities
- **AWS Bedrock integration** for AI/ML workloads and document processing
- **Event-driven architectures** using EventBridge, Lambda, and SQS
- **Multi-region deployment** support (us-east-1 primary, us-east-2 DR)
- **Comprehensive monitoring** with CloudWatch, logging, and alerting
- **Security-first approach** with KMS encryption, IAM least privilege, and audit trails

## Target Users
DevOps engineers, cloud architects, platform engineers, and infrastructure teams looking to implement enterprise-grade AWS infrastructure using modern Infrastructure as Code principles with OpenTofu.

## Migration Status
- **Primary IaC Tool**: OpenTofu (migrated from Terraform)
- **Leverage CLI**: Fully supports both OpenTofu and legacy Terraform workflows
- **Provider Versions**: Updated to latest AWS Provider (~> 5.91) and AWS CC Provider (~> 1.20)
- **Backward Compatibility**: Existing Terraform configurations continue to work