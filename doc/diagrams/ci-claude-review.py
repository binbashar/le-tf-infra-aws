"""
Generates the CI/CD `@claude review` flow diagram.

Originally authored in binbashar/bb-sales-tools
(apps/ai-use-case-lab/docs/diagrams/ci-claude-review.py); ported here unchanged
because the wiring (DeployMaster, machine.github.actions.le-cli, apps-prd,
Claude Sonnet 4.6) is identical to .github/workflows/claude.yml in this repo.

Requires: pip install diagrams && brew install graphviz

Run from repo root:

    python3 doc/diagrams/ci-claude-review.py

Outputs doc/diagrams/ci-claude-review.png.
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.ml import Bedrock
from diagrams.aws.security import IAMRole, IAMAWSSts
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.vcs import Github
from diagrams.onprem.client import User

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

with Diagram(
    "@claude PR Review — CI/CD Flow",
    filename="doc/diagrams/ci-claude-review",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    edge_attr=edge_attr,
    outformat="png",
):
    reviewer = User("Reviewer\n(write access)")

    with Cluster("GitHub", graph_attr=cluster_attr):
        pr = Github("PR / Issue")
        workflow = GithubActions("claude.yml\n(issue_comment)")

    with Cluster("AWS apps-prd", graph_attr=cluster_attr):
        sts = IAMAWSSts("STS\nAssumeRole\n+ TagSession")
        deploy_role = IAMRole("DeployMaster")
        bedrock = Bedrock("Claude Sonnet 4.6\n(us-east-1)")

    # Forward path
    reviewer >> Edge(label="1. @claude review") >> pr
    pr >> Edge(label="2. issue_comment\nevent (default branch)") >> workflow
    workflow >> Edge(label="3. AssumeRole\n(machine.github.actions.le-cli)") >> sts
    sts >> Edge(label="4. session\ncredentials") >> deploy_role
    deploy_role >> Edge(label="5. Converse API", color="#0d6efd") >> bedrock

    # Reply path
    bedrock >> Edge(label="6. review reply", color="#198754") >> workflow
    workflow >> Edge(label="7. POST comment", color="#198754") >> pr
    pr >> Edge(label="8. notification", color="#198754") >> reviewer
