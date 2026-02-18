#!/bin/bash
set -e

echo "Running all quality checks..."
echo ""

# Format code
./scripts/run_format.sh
echo ""

# Lint code
./scripts/run_lint.sh
echo ""

# Run tests
./run_tests.sh
echo ""

echo "All quality checks passed!"
