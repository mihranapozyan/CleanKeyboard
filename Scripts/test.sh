#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build/tests
src=CleanKeyboard

run() { # name, sources…
  local name=$1; shift
  swiftc -module-cache-path build/TestModuleCache "$@" -o build/tests/$name
  build/tests/$name
}

run policy $src/Models/*.swift Tests/PolicyChecks.swift
run blocker $src/Models/*.swift $src/Services/KeyboardBlocker.swift Tests/KeyboardBlockerChecks.swift
run session $src/Models/*.swift $src/Services/*.swift $src/ViewModels/*.swift Tests/Fakes.swift Tests/SessionViewModelChecks.swift
