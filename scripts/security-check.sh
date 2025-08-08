#!/bin/bash

# Local security validation script
# Run this before submitting PRs to ensure security checks will pass

set -e

echo "🔒 Running security validation..."

# Check for default passwords
echo "Checking for default passwords..."
if grep -r "admin:admin" config/ --exclude-dir=.git 2>/dev/null; then
    echo "❌ Default passwords found in configuration"
    echo "Please change all default credentials to placeholder values"
    exit 1
else
    echo "✅ No default passwords found"
fi

# Check for hardcoded secrets
echo "Checking for hardcoded secrets..."
secrets_found=$(grep -r "password\|secret\|token" config/ --exclude-dir=.git 2>/dev/null | grep -v -i "example\|placeholder\|your-\|<\|>" || true)

if [ -n "$secrets_found" ]; then
    echo "❌ Potential hardcoded secrets found:"
    echo "$secrets_found"
    echo ""
    echo "Please use placeholder values like:"
    echo "  - your-password-example"
    echo "  - your-token-example"
    echo "  - your-secret-example"
    exit 1
else
    echo "✅ No hardcoded secrets found"
fi

echo ""
echo "🎉 Security validation passed!"
echo "Your configuration is ready for submission."
