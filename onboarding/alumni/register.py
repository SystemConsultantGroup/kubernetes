"""Register alumni from real bootstrap image locks; never accesses the cluster."""

import argparse
import json
import re
import shutil
from pathlib import Path

WORKLOADS = {
    "user": "skku-alumni-frontend",
    "admin": "skku-alumni-frontend",
    "be": "skku-alumni-backend",
}


def read_lock(path, workload):
    value = json.loads(path.read_text())
    if set(value) != {"source", "image"}:
        raise ValueError(f"{workload}: expected source and image")
    source = value["source"]
    repository = f"https://github.com/SystemConsultantGroup/{WORKLOADS[workload]}.git"
    if set(source) != {"repository", "revision"} or source["repository"] != repository:
        raise ValueError(f"{workload}: unexpected source repository")
    if not re.fullmatch(r"[0-9a-f]{40}", source["revision"]):
        raise ValueError(f"{workload}: invalid source revision")
    image = f"ghcr.io/systemconsultantgroup/alumni-platform-{workload}@sha256:"
    if not re.fullmatch(re.escape(image) + r"[0-9a-f]{64}", value["image"]):
        raise ValueError(f"{workload}: invalid image repository or digest")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for workload in WORKLOADS:
        parser.add_argument(f"--{workload}", type=Path, required=True)
    args = parser.parse_args()
    locks = {name: read_lock(getattr(args, name), name) for name in WORKLOADS}
    if locks["user"]["source"] != locks["admin"]["source"]:
        raise ValueError("user and admin must come from the same source commit")
    target = Path(__file__).resolve().parents[2] / "applications" / "alumni"
    if target.exists():
        raise ValueError(f"Refusing to overwrite {target}; use delivery workflows after bootstrap")
    (target / "instances").mkdir(parents=True)
    shutil.copyfile(Path(__file__).with_name("meta.yaml"), target / "meta.yaml")
    # JSON is valid YAML and avoids an additional parser dependency.
    (target / "instances" / "production.yaml").write_text(json.dumps(locks, indent=2) + "\n")
    print(f"Created {target}; review, validate, and include it in the onboarding PR.")


if __name__ == "__main__":
    main()
