#!/bin/bash
# Setup git hooks for this repository
# Run this after cloning to enable commit hooks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up git hooks..."

# Configure git to use our hooks directory
git config core.hooksPath .githooks

# Make hooks executable
chmod +x "$REPO_ROOT/.githooks/"*

echo "Done! Git hooks are now active."
echo "Commits will automatically strip AI co-author attributions."
