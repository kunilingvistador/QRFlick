#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH=/tmp/screenqr-check-clang
swiftc Sources/ScreenQR/QRPolicy.swift checks/main.swift -o /tmp/screenqr-policy-check
/tmp/screenqr-policy-check
swift scripts/recognition-check.swift
