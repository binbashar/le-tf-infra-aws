"""
Generates the component/flow diagram for **local** Claude Code sessions routed
through Amazon Bedrock by the `claude-bedrock` launcher (left-to-right, edges
numbered 1-7 for one launch): developer shell -> `claude-bedrock` wrapper ->
Leverage SSO credentials (with the automatic `leverage tofu refresh-credentials`
on stale keys) -> Claude Code in Bedrock mode -> the SSO role in the account
picked at launch -> Bedrock Converse API -> a `us.anthropic.*` cross-region
inference profile, subject to the four model-availability gates.

Plain `claude` stays on the native Anthropic API — drawn as the parallel default
path so the dual-mode nature of the setup is obvious. The dashed
`settings.local.json` edge is the precedence hazard (a settings `env` block
overrides the wrapper's exports), not a step in the flow.

Companion to docs/ai-sdlc/claude-code-bedrock.md §0; the step numbers, cluster
names and per-account model lists track that doc (§3.1-§5).

Scope: the local/human launcher only. The CI `@claude` PR reviewer is a separate
integration living in the same apps-prd account — see ci-claude-review.py.

Requires: pip install diagrams && brew install graphviz librsvg

Run from anywhere (icon paths are resolved relative to this file):

    python3 docs/diagrams/claude-bedrock-local.py

Outputs docs/diagrams/claude-bedrock-local.png.

Brand icons (Anthropic/Claude, OpenTofu) are MIT-licensed SVGs from
simple-icons.org, rasterized to 512px PNGs under docs/diagrams/icons/.
"""

import os

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.management import OrganizationsAccount
from diagrams.aws.ml import Bedrock
from diagrams.aws.security import IAMAWSSts, IAMRole, SingleSignOn
from diagrams.custom import Custom
from diagrams.generic.blank import Blank
from diagrams.generic.storage import Storage
from diagrams.onprem.client import User
from diagrams.onprem.network import Internet
from diagrams.programming.flowchart import Document
from diagrams.programming.language import Bash

# Absolute paths so Custom() icons and the output resolve no matter where this is run from.
ICONS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons")
OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "claude-bedrock-local")

graph_attr = {
    "bgcolor": "white",
    "fontcolor": "#1a1a1a",
    # 22 (vs the house default 18) keeps the labels legible after GitHub scales this
    # wide LR flow down to the ~890px content column.
    "fontsize": "22",
    "fontname": "Helvetica",
    "pad": "0.6",
    "rankdir": "LR",
    "splines": "spline",
    "nodesep": "0.7",
    "ranksep": "0.9",
}

cluster_attr = {
    "bgcolor": "#f8f9fa",
    "fontcolor": "#1a1a1a",
    "fontsize": "16",
    "fontname": "Helvetica,bold",
    "style": "rounded",
    "pencolor": "#dee2e6",
    "margin": "16",
}

edge_attr = {
    "color": "#6c757d",
    "fontcolor": "#495057",
    "fontsize": "13",
    "fontname": "Helvetica",
}

# Edge color palette
C_AUTO = "#6c757d"          # grey   — automatic / launcher-driven steps
C_HUMAN = "#0d6efd"         # blue   — human actions
C_CLAUDE = "#d97757"        # orange — Anthropic / Bedrock inference path
C_OK = "#198754"            # green  — successful response

with Diagram(
    "claude-bedrock — local Claude Code session on Amazon Bedrock",
    filename=OUTPUT,
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    edge_attr=edge_attr,
    outformat="png",
):

    # ---------- 1. Local shell — the two modes ----------
    with Cluster("1. Your machine  (local shell)", graph_attr=cluster_attr):
        dev = User("Developer")
        cli_native = Bash("$ claude\n[default]")
        launcher = Bash("$ claude-bedrock\n[opt-in wrapper]")
        settings = Document("settings.local.json\n(env block)")

    # The native (non-Bedrock) default path — untouched by this setup.
    anthropic_api = Internet("native Anthropic API\n(subscription login)")

    # ---------- 2. Credentials ----------
    with Cluster("2. Credentials  (Leverage SSO — no long-lived keys)", graph_attr=cluster_attr):
        sts = IAMAWSSts("STS preflight\nget-caller-identity")
        sso = SingleSignOn("IAM Identity Center\nleverage aws sso login\n(browser, manual)")
        refresh = Custom(
            "leverage tofu\nrefresh-credentials\n(auto)",
            f"{ICONS}/opentofu.png",
        )
        creds = Storage("~/.aws/bb/\ncredentials")

    # ---------- Claude Code in Bedrock mode ----------
    # Un-clustered on purpose: it runs on your machine, but sits after the credentials in
    # the flow. Cluster numbers stay 1→2→3; the 1..7 edge labels carry the step sequence.
    claude_code = Custom(
        "Claude Code\nCLAUDE_CODE_USE_BEDROCK=1\nANTHROPIC_MODEL=us.anthropic.*",
        f"{ICONS}/anthropic.png",
    )

    # ---------- 3. AWS account chosen at launch ----------
    with Cluster("3. AWS account + SSO role  (chosen at launch)", graph_attr=cluster_attr):
        role = IAMRole("bb-<account>-<role>\nDevOps | DataScientist\nbedrock:InvokeModel*")
        acct_prd = OrganizationsAccount(
            "apps-prd  (prod)\nOpus 5 · Sonnet 5\nFable 5 · Haiku 4.5"
        )
        acct_ds = OrganizationsAccount(
            "data-science  (default)\nOpus 4.6 · Sonnet 4.6\nHaiku 4.5  (5.x pending)"
        )

        with Cluster("Amazon Bedrock  (us-east-1)", graph_attr=cluster_attr):
            bedrock = Bedrock("Converse API")
            model = Custom(
                "us.anthropic.claude-*\ncross-region\ninference profile",
                f"{ICONS}/anthropic.png",
            )

        # Label-only callout (Blank draws no icon): the four gates are policy state on the
        # model, not a component in the request path. `\l` is Graphviz's left-justified
        # line break — escaped as `\\l` so Python passes it through literally.
        gates = Blank(
            "Model availability — 4 independent gates\\l"
            "1. Model access  (agreement, per account)\\l"
            "2. Service quota TPM  (per model, us. family)\\l"
            "3. IAM  bedrock:InvokeModel*\\l"
            "4. Data-retention mode  (Fable 5 / Mythos 5 only)\\l"
        )

    # ===== Edges =====

    # The human picks a mode.
    dev >> Edge(label="everyday sessions", color=C_HUMAN) >> cli_native
    dev >> Edge(label="Bedrock sessions", color=C_HUMAN) >> launcher
    cli_native >> Edge(color=C_AUTO) >> anthropic_api

    # Launcher: prompt, preflight, refresh, materialize credentials.
    launcher >> Edge(label="1. prompt\naccount + role", color=C_AUTO) >> sts
    sts >> Edge(label="2. stale keys", style="dashed", color=C_AUTO) >> refresh
    sso >> Edge(label="valid SSO\nsession", color=C_HUMAN) >> refresh
    refresh >> Edge(label="3. mint\ntemp keys", color=C_AUTO) >> creds
    creds >> Edge(label="4. export-credentials\n→ env keys", color=C_AUTO) >> claude_code
    launcher >> Edge(label="5. exec claude\n(mode env vars)", color=C_CLAUDE) >> claude_code

    # Settings-precedence gotcha (§1): a settings `env` block outranks the wrapper's exports.
    settings >> Edge(
        label="env block WINS\nover the shell (§1)",
        style="dashed",
        color=C_AUTO,
    ) >> claude_code

    # Inference path. The account nodes annotate the role rather than sitting between it
    # and Bedrock (constraint=false), so they don't each add a rank to this wide LR flow.
    claude_code >> Edge(label="6. Converse API\n(SigV4, temp creds)", color=C_CLAUDE) >> role
    role >> Edge(label="in whichever\naccount you picked", style="dashed", color=C_AUTO, constraint="false") >> acct_prd
    role >> Edge(style="dashed", color=C_AUTO, constraint="false") >> acct_ds
    role >> Edge(label="InvokeModel*", color=C_CLAUDE) >> bedrock
    bedrock >> Edge(color=C_CLAUDE) >> model
    # constraint=false: annotate the model without ranking the callout ahead of it.
    gates >> Edge(label="all 4 must pass", style="dotted", color=C_AUTO, constraint="false") >> model

    # Response back to the local session. constraint=false keeps this return edge from
    # ranking Claude Code to the right of the entire AWS cluster.
    model >> Edge(label="7. streamed completion", color=C_OK, constraint="false") >> claude_code
