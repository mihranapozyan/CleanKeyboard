#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
xcodebuild -quiet -project CleanKeyboard.xcodeproj -scheme CleanKeyboard -configuration Release -destination 'generic/platform=macOS' -derivedDataPath build build
ditto build/Build/Products/Release/CleanKeyboard.app CleanKeyboard.app
codesign --verify --deep --strict CleanKeyboard.app
print 'Done: CleanKeyboard.app'
