"""
Generates the AI-driven SDLC flow diagram for the Leverage Reference
Architecture (left-to-right workflow): Developer / Renovate → Issue / PR →
automated PR review (CodeRabbit, Gemini, GitHub Actions checks, on-demand
@claude via AWS Bedrock) → human approval → manual `leverage tofu apply`
per layer → merge to master.

Requires: pip install diagrams && brew install graphviz librsvg

Run from anywhere (icon paths are resolved relative to this file):

    python3 doc/diagrams/ai-sdlc.py

Outputs doc/diagrams/ai-sdlc.png.

Brand icons (CodeRabbit, Gemini, Anthropic/Claude, Renovate, OpenTofu) are
MIT-licensed SVGs from simple-icons.org, rasterized to 512px PNGs under
doc/diagrams/icons/.
"""

import os

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.ml import Bedrock
from diagrams.aws.security import IAMRole, IAMAWSSts
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.vcs import Github
from diagrams.onprem.client import User, Users
from diagrams.custom import Custom

# Absolute path so Custom() icons resolve no matter where the script is run from.
ICONS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons")
OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ai-sdlc")

graph_attr = {
    "bgcolor": "white",
    "fontcolor": "#1a1a1a",
    "fontsize": "18",
    "fontname": "Helvetica",
    "pad": "0.6",
    "rankdir": "LR",
    "splines": "spline",
    "nodesep": "0.6",
    "ranksep": "1.1",
}

cluster_attr = {
    "bgcolor": "#f8f9fa",
    "fontcolor": "#1a1a1a",
    "fontsize": "13",
    "fontname": "Helvetica,bold",
    "style": "rounded",
    "pencolor": "#dee2e6",
    "margin": "16",
}

edge_attr = {
    "color": "#6c757d",
    "fontcolor": "#495057",
    "fontsize": "10",
    "fontname": "Helvetica",
}

# Edge color palette
C_AUTO = "#6c757d"          # grey  — auto-triggers
C_HUMAN = "#0d6efd"         # blue  — human actions
C_CLAUDE = "#d97757"        # Anthropic orange — @claude on-demand path
C_OK = "#198754"            # green — success / approval / merge

with Diagram(
    "AI-Driven SDLC — Leverage Reference Architecture",
    filename=OUTPUT,
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    edge_attr=edge_attr,
    outformat="png",
):

    # ---------- 1. Authors ----------
    with Cluster("1. Authors", graph_attr=cluster_attr):
        dev = User("Developer")
        renovate = Custom("Renovate\n(bot)", f"{ICONS}/renovate.png")

    # ---------- 2. GitHub entry points ----------
    with Cluster("2. GitHub", graph_attr=cluster_attr):
        issue = Github("Issue")
        pr = Github("Pull Request\n(feature branch)")

    # ---------- 3. Automated PR review fanout ----------
    with Cluster("3. Automated PR review  (auto on open / sync)", graph_attr=cluster_attr):
        with Cluster("AI reviewers (GitHub Apps)", graph_attr=cluster_attr):
            coderabbit = Custom("CodeRabbit AI\nwalkthrough + nitpicks", f"{ICONS}/coderabbit.png")
            gemini = Custom("Gemini Code Assist\nreview summary", f"{ICONS}/googlegemini.png")
        with Cluster("CI checks (GitHub Actions)", graph_attr=cluster_attr):
            test_lint = GithubActions("Test and Lint\n(pre-commit)")
            infracost = GithubActions("Infracost\n(cost diff)")
            gitguardian = GithubActions("GitGuardian\n(secret scan)")

    # ---------- 4. On-demand @claude review via AWS Bedrock ----------
    with Cluster("4. On-demand:  '@claude review'  (.github/workflows/claude.yml)", graph_attr=cluster_attr):
        claude_wf = GithubActions("claude.yml\n(issue_comment)")
        with Cluster("AWS apps-prd", graph_attr=cluster_attr):
            sts = IAMAWSSts("STS AssumeRole\n+ TagSession")
            deploy = IAMRole("DeployMaster")
            bedrock = Bedrock("Bedrock\n(us-east-1)")
            claude_logo = Custom("Anthropic\nClaude Sonnet 4.6", f"{ICONS}/anthropic.png")

        claude_wf >> Edge(label="AssumeRole\nmachine.github.actions.le-cli", color=C_CLAUDE) >> sts
        sts >> Edge(label="session creds", color=C_CLAUDE) >> deploy
        deploy >> Edge(label="Converse API", color=C_CLAUDE) >> bedrock
        bedrock >> Edge(style="dashed", color=C_CLAUDE) >> claude_logo

    # ---------- 5. Human approval, apply & merge ----------
    with Cluster("5. Human approval, apply & merge", graph_attr=cluster_attr):
        maintainers = Users("Maintainers\n(CODEOWNERS team)")
        tofu_apply = Custom("leverage tofu apply\n(per layer, manual)", f"{ICONS}/opentofu.png")
        release_drafter = GithubActions("release-drafter\n(auto-draft notes)")

    # ---------- 6. Master (final) ----------
    master = Github("master\n(default branch)")

    # ===== Edges =====

    # Authors → GitHub entry points
    dev >> Edge(label="opens", color=C_HUMAN) >> issue
    dev >> Edge(label="pushes branch /\nopens PR", color=C_HUMAN) >> pr
    renovate >> Edge(label="auto-opens\ndep PR", color=C_AUTO) >> pr
    issue >> Edge(label="referenced by", style="dashed", color=C_AUTO) >> pr

    # PR fans out to automated reviewers
    pr >> Edge(color=C_AUTO) >> coderabbit
    pr >> Edge(color=C_AUTO) >> gemini
    pr >> Edge(color=C_AUTO) >> test_lint
    pr >> Edge(color=C_AUTO) >> infracost
    pr >> Edge(color=C_AUTO) >> gitguardian

    # On-demand @claude path (PR → claude.yml; reply → PR)
    pr >> Edge(label="'@claude review'\nin PR comment", style="dashed", color=C_CLAUDE) >> claude_wf
    claude_logo >> Edge(label="POST review\ncomment", color=C_OK) >> pr

    # All reviewer findings converge on the PR — maintainers read them on the PR page.
    # Human gate → manual apply → merge → release notes
    pr >> Edge(label="reviewer reads\nall AI + CI findings", color=C_HUMAN) >> maintainers
    maintainers >> Edge(label="approve PR\n(1 required)", color=C_HUMAN) >> tofu_apply
    tofu_apply >> Edge(label="apply OK", color=C_OK) >> master
    pr >> Edge(label="merge", color=C_OK) >> master
    master >> Edge(style="dashed", color=C_AUTO) >> release_drafter
