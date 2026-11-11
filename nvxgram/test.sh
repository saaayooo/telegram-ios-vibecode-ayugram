#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m unittest discover -s nvxgram/tests -p 'test_*.py' -v
NVX_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$NVX_TEST_DIR"' EXIT
swiftc submodules/TelegramCore/Sources/Account/NVXGramPolicy.swift nvxgram/tests/main.swift -o "$NVX_TEST_DIR/policy-tests"
"$NVX_TEST_DIR/policy-tests"
