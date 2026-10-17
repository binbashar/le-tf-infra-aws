"""Minimal GitHub REST client for the apply workflow's trusted steps.

Standard library only, so the trusted steps need no installed packages. The
transport is injectable, which lets tests run every call without a network.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from typing import Any, Callable

API_URL = "https://api.github.com"
Transport = Callable[[str, str, "dict[str, Any] | None"], "tuple[int, Any]"]


class GitHubError(RuntimeError):
    def __init__(self, status: int, method: str, path: str):
        super().__init__(f"GitHub API {method} {path} returned HTTP {status}")
        self.status = status


def urllib_transport(token: str, api_url: str = API_URL) -> Transport:
    def send(method: str, path: str, body: dict[str, Any] | None) -> tuple[int, Any]:
        request = urllib.request.Request(
            f"{api_url}{path}",
            method=method,
            data=json.dumps(body).encode("utf-8") if body is not None else None,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {token}",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "tofu-plan-ci",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
                return response.status, json.loads(raw) if raw else None
        except urllib.error.HTTPError as error:
            return error.code, None

    return send


class GitHub:
    def __init__(self, repository: str, transport: Transport):
        self.repo = f"/repos/{repository}"
        self._send = transport

    def call(self, method: str, path: str, body: dict[str, Any] | None = None,
             *, allow: tuple[int, ...] = ()) -> tuple[int, Any]:
        status, payload = self._send(method, path, body)
        if status >= 400 and status not in allow:
            raise GitHubError(status, method, path)
        return status, payload

    def get(self, path: str, *, allow: tuple[int, ...] = ()) -> Any:
        return self.call("GET", path, allow=allow)[1]

    def paginate(self, path: str, key: str | None = None, *, limit: int = 10) -> list[Any]:
        items: list[Any] = []
        separator = "&" if "?" in path else "?"
        for page in range(1, limit + 1):
            payload = self.get(f"{path}{separator}per_page=100&page={page}")
            batch = payload.get(key, []) if key else payload
            items.extend(batch or [])
            if not batch or len(batch) < 100:
                break
        return items

    # Pull requests and reviews
    def pull(self, number: int) -> dict:
        return self.get(f"{self.repo}/pulls/{number}")

    def reviews(self, number: int) -> list[dict]:
        return self.paginate(f"{self.repo}/pulls/{number}/reviews")

    def permission(self, user: str) -> str:
        return self.get(f"{self.repo}/collaborators/{user}/permission").get("permission", "none")

    def compare(self, base: str, head: str) -> dict:
        return self.get(f"{self.repo}/compare/{base}...{head}")

    # Comments, reactions, statuses
    def react(self, comment_id: int, content: str) -> None:
        self.call("POST", f"{self.repo}/issues/comments/{comment_id}/reactions",
                  {"content": content})

    def comment(self, number: int, body: str) -> None:
        self.call("POST", f"{self.repo}/issues/{number}/comments", {"body": body})

    def status(self, sha: str, *, state: str, context: str, description: str,
               target_url: str | None = None) -> None:
        body = {"state": state, "context": context, "description": description[:140]}
        if target_url:
            body["target_url"] = target_url
        self.call("POST", f"{self.repo}/statuses/{sha}", body)

    # Workflow runs
    def workflow_runs(self, workflow: str, head_sha: str) -> list[dict]:
        return self.paginate(
            f"{self.repo}/actions/workflows/{workflow}/runs?head_sha={head_sha}",
            "workflow_runs",
            limit=2,
        )

    # Git data: locks are annotated tags under refs/tofu-locks/
    def matching_refs(self, prefix: str) -> list[dict]:
        return self.get(f"{self.repo}/git/matching-refs/{prefix}") or []

    def tag(self, sha: str) -> dict:
        return self.get(f"{self.repo}/git/tags/{sha}")

    def create_tag(self, *, tag: str, message: str, commit: str) -> str:
        _, payload = self.call("POST", f"{self.repo}/git/tags",
                               {"tag": tag, "message": message, "object": commit,
                                "type": "commit"})
        return payload["sha"]

    def create_ref(self, ref: str, sha: str) -> bool:
        """Create a ref; False if it already exists (the atomic lock primitive)."""

        status, _ = self.call("POST", f"{self.repo}/git/refs", {"ref": ref, "sha": sha},
                              allow=(422,))
        return status != 422

    def delete_ref(self, ref: str) -> None:
        self.call("DELETE", f"{self.repo}/git/{ref}", allow=(404, 422))
