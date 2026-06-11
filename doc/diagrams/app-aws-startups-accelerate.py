"""
Generates the aws-startups-accelerate.binbash.co static-hosting architecture diagram.

Shows the apps-prd layer provisioned in #1085 / PR #1097: the bb-ai-sales-tools
deploy pipeline (GitHub Actions -> OIDC -> least-privilege role -> s3 sync +
CloudFront invalidation), the serving path (Route53 alias in the shared account
-> CloudFront + viewer-request function -> private S3 origin via OAC, TLS from
the security-certs ACM cert), and the operations path (access logs, error-rate
alarms -> notifications SNS -> Slack).

Requires: pip install diagrams && brew install graphviz

Run from anywhere (output path is resolved relative to this file):

    python3 doc/diagrams/app-aws-startups-accelerate.py

Outputs doc/diagrams/app-aws-startups-accelerate.png.
"""

import os

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.integration import SNS
from diagrams.aws.management import CloudwatchAlarm
from diagrams.aws.network import CloudFront, CloudFrontEdgeLocation, Route53
from diagrams.aws.security import ACM, IAM, IAMRole
from diagrams.aws.storage import S3
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import User
from diagrams.onprem.vcs import Github
from diagrams.saas.chat import Slack

graph_attr = {
    "bgcolor": "white",
    "fontcolor": "#1a1a1a",
    "fontsize": "14",
    "fontname": "Helvetica",
    "pad": "0.5",
    "rankdir": "LR",
    "splines": "spline",
}

cluster_attr = {
    "bgcolor": "#f8f9fa",
    "fontcolor": "#1a1a1a",
    "fontsize": "12",
    "fontname": "Helvetica,bold",
    "style": "rounded",
    "pencolor": "#dee2e6",
}

edge_attr = {
    "color": "#6c757d",
    "fontcolor": "#495057",
    "fontsize": "10",
    "fontname": "Helvetica",
}

# Semantic edge colours (house palette)
C_AUTO = "#6c757d"   # automated pipeline steps
C_HUMAN = "#0d6efd"  # human-initiated traffic
C_OK = "#198754"     # feedback / notification path

# Absolute path so the PNG is written next to this script no matter where it is run from.
OUTPUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "app-aws-startups-accelerate"
)

with Diagram(
    "aws-startups-accelerate.binbash.co — S3 + CloudFront static hosting (apps-prd)",
    filename=OUTPUT,
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    edge_attr=edge_attr,
    outformat="png",
):
    visitor = User("Visitor")

    with Cluster("GitHub — bb-ai-sales-tools", graph_attr=cluster_attr):
        repo = Github("main branch\napps/aws-startups-accelerate")
        workflow = GithubActions("deploy workflow\n(next build, output: export)")

    with Cluster("AWS shared", graph_attr=cluster_attr):
        dns = Route53("binbash.co public zone\nA/AAAA alias")

    with Cluster("AWS apps-prd (us-east-1)", graph_attr=cluster_attr):
        with Cluster("app-aws-startups-accelerate layer", graph_attr=cluster_attr):
            oidc = IAM("GitHub OIDC\nidentity provider")
            deploy_role = IAMRole("deploy role\n(s3 sync + invalidation only)")
            cdn = CloudFront("distribution\nPriceClass_100, TLS 1.2+")
            rewrite_fn = CloudFrontEdgeLocation("viewer-request fn\npretty URLs -> index.html")
            origin = S3("origin bucket\nprivate (OAC), SSE, SSL-only")
            logs = S3("access logs\n90-day expiry")
            alarms = CloudwatchAlarm("5xx / total\nerror-rate alarms")

        with Cluster("security-certs layer", graph_attr=cluster_attr):
            cert = ACM("ACM cert\n(us-east-1, DNS-validated)")

        with Cluster("notifications layer", graph_attr=cluster_attr):
            sns = SNS("monitoring topic")

    slack = Slack("#tools-monitoring")

    # Deploy path (automation)
    repo >> Edge(label="1. push to main", color=C_AUTO) >> workflow
    workflow >> Edge(label="2. OIDC token\nAssumeRoleWithWebIdentity", color=C_AUTO) >> oidc
    oidc >> Edge(label="trust: repo@main only", color=C_AUTO) >> deploy_role
    deploy_role >> Edge(label="3. aws s3 sync --delete", color=C_AUTO) >> origin
    deploy_role >> Edge(label="4. create-invalidation /*", color=C_AUTO) >> cdn

    # Serving path (human traffic)
    visitor >> Edge(label="a. HTTPS GET", color=C_HUMAN) >> cdn
    dns >> Edge(label="alias to distribution", style="dashed") >> cdn
    cert >> Edge(label="TLS certificate", style="dashed") >> cdn
    cdn >> Edge(label="b. rewrite URI", color=C_HUMAN) >> rewrite_fn
    cdn >> Edge(label="c. OAC-signed GET", color=C_HUMAN) >> origin

    # Operations / feedback path
    cdn >> Edge(label="access logs", style="dashed") >> logs
    cdn >> Edge(label="error-rate metrics", style="dashed") >> alarms
    alarms >> Edge(label="ALARM", color=C_OK) >> sns
    sns >> Edge(label="notify", color=C_OK) >> slack
