#!/bin/zsh
# Builds the app and packs it into dist/CleanKeyboard-<version>.zip with a SHA-256 checksum.
set -euo pipefail
cd "${0:A:h:h}"
./Scripts/build.sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' CleanKeyboard/Info.plist)
mkdir -p dist
archive="dist/CleanKeyboard-$version.zip"
rm -f "$archive" "$archive.sha256"
ditto -c -k --keepParent CleanKeyboard.app "$archive"
(cd dist && shasum -a 256 "CleanKeyboard-$version.zip" > "CleanKeyboard-$version.zip.sha256")
print "Done: $archive"
