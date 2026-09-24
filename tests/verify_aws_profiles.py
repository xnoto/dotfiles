#!/usr/bin/env python3

import configparser
import sys


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"config", "credentials"}:
        raise SystemExit("usage: verify_aws_profiles.py <config|credentials>")

    kind = sys.argv[1]
    expected = {
        "credentials": {
            "makeitwork": {"aws_access_key_id", "aws_secret_access_key"},
        },
        "config": {
            "profile makeitwork": {"region"},
            **{
                f"profile {name}": {
                    "sso_session", "sso_account_id", "sso_role_name", "region"
                }
                for name in ("staging", "prod", "prod_admin")
            },
            **{
                f"sso-session {name}": {
                    "sso_start_url", "sso_region", "sso_registration_scopes"
                }
                for name in ("staging", "prod", "prod_admin")
            },
        },
    }[kind]
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read_file(sys.stdin)
    except configparser.Error:
        raise SystemExit("AWS profile check failed: invalid INI") from None

    if parser.defaults() or set(parser.sections()) != set(expected):
        raise SystemExit("AWS profile check failed: unexpected profile scope")
    for section, keys in expected.items():
        if set(parser[section]) != keys:
            raise SystemExit("AWS profile check failed: unexpected option scope")
        for value in parser[section].values():
            if not value.strip() or "<no value>" in value or "{{" in value:
                raise SystemExit("AWS profile check failed: missing rendered value")
    if kind == "config":
        for name in ("staging", "prod", "prod_admin"):
            if parser[f"profile {name}"]["sso_session"] != name:
                raise SystemExit("AWS profile check failed: mismatched SSO session")
    print(f"AWS {kind} profile scope verified")


if __name__ == "__main__":
    main()
