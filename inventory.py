#!/usr/bin/env python3
"""Dynamic Ansible inventory that reads from Terraform outputs."""

import json
import subprocess
import sys


def get_terraform_output(key):
    result = subprocess.run(
        ["terraform", "output", "-raw", key],
        capture_output=True, text=True
    )
    return result.stdout.strip()


def main():
    if "--list" in sys.argv:
        ip = get_terraform_output("instance_public_ip")

        inventory = {
            "webservers": {
                "hosts": [ip]
            },
            "_meta": {
                "hostvars": {}
            }
        }
        print(json.dumps(inventory))

    elif "--host" in sys.argv:
        print(json.dumps({}))


if __name__ == "__main__":
    main()
