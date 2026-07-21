#!/usr/bin/env python3
from pathlib import Path


SOURCE_ROOT = Path(__file__).resolve().parents[1]
SECRET_SOURCE = "encrypted_secrets.yaml.age"


def main() -> int:
    insecure_templates = []
    for template in SOURCE_ROOT.rglob("*.tmpl"):
        if ".git" in template.parts or not template.is_file():
            continue
        template_contents = template.read_text()
        if SECRET_SOURCE not in template_contents or "decrypt" not in template_contents:
            continue
        if not template.name.startswith("private_"):
            insecure_templates.append(template.relative_to(SOURCE_ROOT))

    if insecure_templates:
        print("Secret-rendering templates must use chezmoi's private_ attribute:")
        for template in insecure_templates:
            print(f"- {template}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
