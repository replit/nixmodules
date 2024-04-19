#!/usr/bin/env bash
set -xe

rm -rf "${REPL_HOME}/replit.nix" "${REPL_HOME}/poetry.lock" "${REPL_HOME}/.upm" "${REPL_HOME}/venv" "${REPL_HOME}/.config" "${REPL_HOME}/.cache"

mkdir -p "${REPL_HOME}/.pythonlibs"

cat << EOF > "${REPL_HOME}/.replit"
entrypoint = "main.py"
modules = ["python-3.10:v18-20230807-322e88b"]

[nix]
channel = "stable-23_11"

[unitTest]
language = "python3"

[gitHubImport]
requiredFiles = [".replit", "replit.nix"]
EOF

cat << EOF > "${REPL_HOME}/pyproject.toml"
[tool.poetry]
name = "python-template"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = ">=3.10.0,<3.12"

[tool.pyright]
# https://github.com/microsoft/pyright/blob/main/docs/configuration.md
useLibraryCodeForTypes = true
exclude = [".cache"]

[tool.ruff]
# https://beta.ruff.rs/docs/configuration/
select = ['E', 'W', 'F', 'I', 'B', 'C4', 'ARG', 'SIM']
ignore = ['W291', 'W292', 'W293']

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
EOF
