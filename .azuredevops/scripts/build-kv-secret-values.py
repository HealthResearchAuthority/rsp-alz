#!/usr/bin/env python3
"""
Generates a JSON object containing Key Vault secret values pulled from Azure DevOps variable groups.

Usage: python build-kv-secret-values.py <manifest_path> <output_path>

The manifest describes the secrets (name, optional variableName). Each variableName must match a variable
in the loaded variable group. The resulting JSON object will have properties where the key is the secret
name and the value is the secret's contents.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def resolve_env_value(variable_name: str) -> str | None:
  """Attempt to read the variable from the environment using several name variants."""
  candidates = {
    variable_name,
    variable_name.upper(),
    variable_name.replace('-', '_'),
    variable_name.replace('-', '_').upper(),
  }
  for candidate in candidates:
    value = os.environ.get(candidate)
    if value:
      return value
  return None


def main() -> int:
  if len(sys.argv) != 3:
    print('Usage: python build-kv-secret-values.py <manifest_path> <output_path>')
    return 1

  manifest_path = Path(sys.argv[1]).resolve()
  output_path = Path(sys.argv[2]).resolve()

  if not manifest_path.exists():
    print(f'Manifest file "{manifest_path}" does not exist.')
    return 1

  with manifest_path.open('r', encoding='utf-8') as manifest_file:
    secrets = json.load(manifest_file)

  values: dict[str, str] = {}
  missing: list[str] = []

  for entry in secrets:
    name = entry['name']
    variable_name = entry.get('variableName') or name
    value = resolve_env_value(variable_name)
    if value is None or value == '':
      missing.append(f'{name} (variable: {variable_name})')
    else:
      values[name] = value

  if missing:
    print('The following secrets do not have corresponding variable values:')
    for item in missing:
      print(f' - {item}')
    return 1

  output_path.parent.mkdir(parents=True, exist_ok=True)
  with output_path.open('w', encoding='utf-8') as output_file:
    json.dump(values, output_file)

  print(f'Wrote {len(values)} secret value(s) to {output_path}')
  return 0


if __name__ == '__main__':
  sys.exit(main())
