# EKS Network Architecture Analysis: Account-Level vs. EKS-Specific NAT Gateway

## 1. Introduction

This document analyzes the network architecture for EKS deployments within this project, specifically addressing the question: **"Why not use the account-level `base-network` layer for NAT Gateways instead of the EKS-specific application layer?"**

The current architecture is composed of three distinct network layers:

1.  `@shared/us-east-1/base-network/`: Centralized hub for shared services (e.g., VPN, DNS, Transit Gateway).
2.  `@apps-devstg/us-east-1/base-network/`: Foundational account-level networking (VPC, core subnets, routing).
3.  `@apps-devstg/us-east-1/k8s-eks-demoapps/network/`: Application-specific networking for an EKS cluster, including its own NAT Gateway.

This analysis defends the decision to place NAT Gateways in the third layer, arguing that it aligns with best practices for security, scalability, and operational agility.

## 2. Separation of Concerns & Layer Responsibilities

Understanding the role of each layer is crucial:

*   **Layer 1 (`@shared/.../base-network`) - The Connectivity Hub:** This layer is the backbone for inter-account and on-premises connectivity. It is not meant for application-specific resources. Think of it as the central telephone exchange or internet service provider for the entire organization.

*   **Layer 2 (`@apps-devstg/.../base-network`) - The Account Foundation:** This layer provides the fundamental VPC and networking "grid" for an entire AWS account. It is designed to be stable, secure, and generic. It should not contain resources specific to any single application, as its lifecycle is tied to the account, not the apps within it.

*   **Layer 3 (`@apps-devstg/.../k8s-eks-demoapps/network`) - The Application Environment:** This layer contains all the networking resources required for a *specific* EKS cluster to function. It is an extension of the account foundation but is dedicated to the application. Its lifecycle is tied directly to the EKS cluster it serves.

## 3. Analysis: NAT Gateway Placement Tradeoffs

The decision to place the NAT Gateway in the EKS-specific layer is based on a clear-eyed view of the tradeoffs between a shared, account-level approach and a dedicated, application-level one.

| Feature | Account-Level NAT (in `base-network`) | EKS-Specific NAT (in `k8s-eks-demoapps/network`) |
| :--- | :--- | :--- |
| **Isolation & Security** | **Lower.** All resources in the VPC share a single egress path. A security compromise or traffic flood from one app can impact the entire account's outbound connectivity. The blast radius is the entire account. | **Higher.** The egress path is dedicated to the EKS cluster. This isolates EKS outbound traffic, making it easier to monitor, secure, and contain. The blast radius is limited to the single cluster. |
| **Cost Management** | **Obscured.** While potentially cheaper if shared, attributing costs is difficult. It's hard to determine which application is responsible for data processing charges, leading to a "tragedy of the commons." | **Clear.** Costs for the NAT Gateway and its data processing are directly attributable to the EKS cluster. This enables accurate showback/chargeback and holds application owners accountable for their consumption. |
| **Scalability & Performance** | **Limited.** A shared NAT Gateway can become a performance bottleneck for the entire account. Scaling it (e.g., adding more capacity) is a high-impact, account-wide change. Prone to the "noisy neighbor" problem. | **Independent.** Each cluster's NAT Gateway can be scaled independently based on its specific workload without impacting other services. High-traffic clusters can have dedicated NATs per AZ. |
| **Agility & Autonomy** | **Low.** Changes to shared networking require centralized approval and carry high risk, slowing down development. Application teams are dependent on a central networking team. | **High.** Application teams can manage their networking needs autonomously. This aligns with DevOps principles, allowing teams to move faster without creating account-wide dependencies. |
| **Lifecycle Management** | **Coupled to the Account.** The NAT Gateway is static infrastructure. This can lead to orphaned rules or configurations if applications are decommissioned improperly. | **Coupled to the Application.** The NAT Gateway's lifecycle is tied to the EKS cluster via Terraform. When the cluster is destroyed, its networking is cleanly destroyed with it. |
| **Multi-Cluster Scenarios** | **Tightly Coupled.** All clusters in the account would be forced to share the same egress path and policies, tightly coupling their fate. A problem in one cluster affects all others. | **Loosely Coupled.** Each cluster has an independent, isolated egress path. This is the industry best practice for running multiple, business-critical clusters. |

## 4. Conclusion: Why the EKS-Specific Layer is the Correct Choice

For enterprise-grade EKS deployments, placing the NAT Gateway within the EKS-specific network layer is the superior architectural choice. It correctly prioritizes:

1.  **Isolation and Security:** It contains the blast radius of any single application.
2.  **Cost Transparency and Accountability:** It makes costs easy to track and attribute.
3.  **Agility and Team Autonomy:** It empowers application teams to manage their own resources safely.
4.  **Clean Lifecycle Management:** It ensures resources are created and destroyed with the application they serve.

While a shared, account-level NAT Gateway might seem simpler or cheaper for very small-scale use cases, it introduces unacceptable risks and operational friction for any serious, production-grade Kubernetes environment. The current architecture correctly implements this critical separation of concerns.
