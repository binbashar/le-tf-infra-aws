"""Scope the Infracost pull-request check to the OpenTofu layers a PR affects.

Layer discovery is shared with the OpenTofu plan CI (``tofu_plan_ci.discover``), so both
workflows agree on what an "affected layer" is: disabled ``--`` layers never count, and a
change under ``config/`` or ``{account}/config/`` expands to every active layer it feeds.
"""
