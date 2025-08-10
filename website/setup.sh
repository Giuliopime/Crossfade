#!/bin/bash

# Script to add Tailwind CSS build to git pre-commit hook
# Run this from the project root directory using ./website/setup.sh

set -e

# Define the hook content
HOOK_CONTENT='#!/bin/sh

# Stop on first error
set -e

echo "generating Tailwind CSS output..."
tailwindcss -i website/input.css -o website/output.css --minify

echo "generated Tailwind output CSS"'

# Path to the pre-commit hook (from project root)
HOOK_PATH=".git/hooks/pre-commit"

# Check if we're in the project root directory
if [ ! -f ".git/config" ]; then
    echo "Error: This script should be run from the project root directory"
    exit 1
fi

# Create the hooks directory if it doesn't exist
mkdir -p ".git/hooks"

# Check if pre-commit hook already exists
if [ -f "$HOOK_PATH" ]; then
    echo "Warning: pre-commit hook already exists at $HOOK_PATH"
    echo "Creating backup as pre-commit.backup"
    cp "$HOOK_PATH" "${HOOK_PATH}.backup"
fi

# Write the hook content
echo "$HOOK_CONTENT" > "$HOOK_PATH"

# Make the hook executable
chmod +x "$HOOK_PATH"

echo "✅ Pre-commit hook successfully created at $HOOK_PATH"
echo "The hook will now automatically build Tailwind CSS before each commit"