"""Minimal GitHub REST client for the apply workflow's trusted steps.

Standard library only, so the trusted steps need no installed packages. The
transport and the wait between retries are injectable, which lets tests run
every call without a network or a delay.
"""

from __future__ import annotations

import http.client
import json
import time
import urllib.error
import urllib.request
from typing import Any, Callable

API_URL = "https://api.github.com"
Transport = Callable[[str, str, "dict[str, Any] | None"], "tuple[int, Any]"]

# GitHub's server errors and dropped connections clear within seconds, so they
# are retried. Repeating a POST is safe here: statuses and reactions are
# idempotent, an extra tag object is never referenced, a lock ref that the first
# attempt did create answers the retry with 422 (`run_lock` then finds this PR
# as its owner), and a comment is at worst posted twice. A DELETE is never
# repeated: GitHub deletes a ref with no owner check, so if the first DELETE
# landed, a retry could delete a lock that another PR took in the meantime.
RETRY_STATUSES = frozenset({500, 502, 503, 504})
RETRY_DELAYS = (2, 4, 8)  # seconds before each retry: four attempts in all
# A refused, reset or timed-out connection: URLError, TimeoutError and
# ConnectionError are all OSErrors.
TRANSIENT_ERRORS = (OSError, http.client.HTTPException)


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
    def __init__(self, repository: str, transport: Transport, *,
                 sleep: Callable[[float], None] = time.sleep):
        self.repo = f"/repos/{repository}"
        self._send = transport
        self._sleep = sleep

    def call(self, method: str, path: str, body: dict[str, Any] | None = None,
             *, allow: tuple[int, ...] = ()) -> tuple[int, Any]:
        delays = () if method == "DELETE" else RETRY_DELAYS  # see RETRY_STATUSES
        for delay in (*delays, None):  # None marks the last attempt
            try:
                status, payload = self._send(method, path, body)
            except TRANSIENT_ERRORS as error:
                if delay is None:
                    raise
                failure = f"{type(error).__name__}: {error}"
            else:
                if status not in RETRY_STATUSES or delay is None:
                    break
                failure = f"HTTP {status}"
            print(f"::warning::GitHub API {method} {path} failed ({failure}); "
                  f"retrying in {delay}s", flush=True)
            self._sleep(delay)
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

    def pull_files(self, number: int) -> list[dict]:
        return self.paginate(f"{self.repo}/pulls/{number}/files", limit=30)

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

    def commit_statuses(self, sha: str) -> list[dict]:
        """The newest 100 statuses of a commit, newest first."""

        return self.get(f"{self.repo}/commits/{sha}/statuses?per_page=100") or []

    # Workflow runs
    def workflow_runs(self, workflow: str, head_sha: str) -> list[dict]:
        return self.paginate(
            f"{self.repo}/actions/workflows/{workflow}/runs?head_sha={head_sha}",
            "workflow_runs",
            limit=2,
        )

    def run_jobs(self, run_id: str, attempt: str) -> list[dict]:
        return self.paginate(
            f"{self.repo}/actions/runs/{run_id}/attempts/{attempt}/jobs", "jobs", limit=2)

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
