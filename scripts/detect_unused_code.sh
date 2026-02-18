#!/bin/bash
set -e

echo "Detecting unused code..."

if ! which periphery >/dev/null; then
  echo "Error: Periphery not installed"
  echo "Install with: brew install peripheryapp/periphery/periphery"
  exit 1
fi

periphery scan \
  --schemes CreativityHub \
  --targets CreativityHub \
  --format xcode

echo "Unused code detection completed!"
