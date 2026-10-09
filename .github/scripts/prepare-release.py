"""Derive repeatable template patch versions from first-parent Git history."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess


VERSION = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def version_tuple(version):
    if not VERSION.fullmatch(version):
        raise ValueError(f"Expected a major.minor.patch version, got {version!r}")
    return tuple(map(int, version.split(".")))


def release_version(path, base):
    # The first commit with this declared version establishes the baseline.
    # Later commits touching this template each advance the patch once.
    commits = git("rev-list", "--first-parent", "HEAD", "--", str(path.parent))
    count = 0
    for commit in commits.splitlines():
        result = subprocess.run(
            ["git", "show", f"{commit}:{path.as_posix()}"],
            text=True, capture_output=True,
        )
        if result.returncode != 0 or json.loads(result.stdout)["version"] != base:
            break
        count += 1
    major, minor, patch = version_tuple(base)
    return f"{major}.{minor}.{patch + max(count - 1, 0)}"


def already_published(path, template_id, version):
    prefix = f"template_{template_id}_"
    tags = git("tag", "--list", f"{prefix}*").splitlines()
    versions = [tag[len(prefix):] for tag in tags if VERSION.fullmatch(tag[len(prefix):])]
    latest = max(versions, key=version_tuple, default=None)
    if latest and version_tuple(version) < version_tuple(latest):
        raise ValueError(
            f"{template_id}: calculated version {version} is older than {latest}. "
            "Set the declared version above the latest published version."
        )
    tag = f"{prefix}{version}"
    if tag not in tags:
        return False
    if git("diff", "--name-only", f"refs/tags/{tag}", "HEAD", "--", str(path.parent)):
        raise ValueError(
            f"{template_id}: {version} is already published for different content. "
            "Set the declared version above the latest published version."
        )
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Show versions without editing files")
    args = parser.parse_args()
    if git("rev-parse", "--is-shallow-repository") == "true":
        raise ValueError("Full Git history is required; use checkout with fetch-depth: 0.")

    publish = False
    for path in sorted(Path("src").glob("*/devcontainer-template.json")):
        # Read committed metadata so repeating this step in one checkout is safe.
        metadata = json.loads(git("show", f"HEAD:{path.as_posix()}"))
        template_id = metadata["id"]
        if template_id != path.parent.name:
            raise ValueError(f"{path}: template id must match its directory name")
        version = release_version(path, metadata["version"])
        published = already_published(path, template_id, version)
        publish |= not published
        status = "already published" if published else "ready to publish"
        print(f"{template_id}: {metadata['version']} -> {version} ({status})")
        metadata["version"] = version
        if not args.dry_run:
            path.write_text(json.dumps(metadata, indent=4) + "\n")

    if not args.dry_run and "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            output.write(f"publish={str(publish).lower()}\n")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        raise SystemExit(str(error)) from error
