#!/usr/bin/env python3
"""只提交指定文件（其余文件保持不变）——用于 git push 被限流时的小改动。"""
import base64
import json
import subprocess
import sys

REPO = "456123739/C4-Pro"
ROOT = "/home/admin/c4/C4-Pro-1.20.1"


def gh(args, payload=None):
    proc = subprocess.run(
        ["gh", "api"] + args,
        input=json.dumps(payload).encode() if payload is not None else None,
        capture_output=True,
    )
    if proc.returncode != 0:
        print("API ERROR:", proc.stderr.decode()[:2000])
        sys.exit(1)
    out = proc.stdout.decode().strip()
    return json.loads(out) if out else {}


def main(paths, message):
    ref = gh([f"repos/{REPO}/git/ref/heads/main"])
    parent = ref["object"]["sha"]
    commit = gh([f"repos/{REPO}/git/commits/{parent}"])
    base_tree = commit["tree"]["sha"]

    entries = []
    for rel in paths:
        with open(f"{ROOT}/{rel}", "rb") as fh:
            data = fh.read()
        blob = gh(["--method", "POST", f"repos/{REPO}/git/blobs", "--input", "-"],
                  {"content": base64.b64encode(data).decode("ascii"), "encoding": "base64"})
        entries.append({"path": rel, "mode": "100644", "type": "blob", "sha": blob["sha"]})
        print("blob", rel, len(data))

    tree = gh(["--method", "POST", f"repos/{REPO}/git/trees", "--input", "-"],
              {"base_tree": base_tree, "tree": entries})
    new_commit = gh(["--method", "POST", f"repos/{REPO}/git/commits", "--input", "-"],
                    {"message": message, "tree": tree["sha"], "parents": [parent]})
    gh(["--method", "PATCH", f"repos/{REPO}/git/refs/heads/main", "--input", "-"],
       {"sha": new_commit["sha"], "force": False})
    print("commit", new_commit["sha"])


if __name__ == "__main__":
    main(sys.argv[2:], sys.argv[1])
