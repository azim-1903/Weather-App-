#!/usr/bin/env bash
set -euo pipefail

# Use the latest stable Flutter version that satisfies pubspec SDK constraints.
FLUTTER_VERSION="3.38.3"
FLUTTER_TAR="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

echo "Downloading Flutter ${FLUTTER_VERSION}..."
curl -sSL "${FLUTTER_URL}" | tar -xJ

export PATH="${PWD}/flutter/bin:${PATH}"
git config --global --add safe.directory "${PWD}/flutter"

echo "Flutter version:"
flutter --version

flutter config --no-analytics
flutter pub get
flutter build web --release

