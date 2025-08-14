#!/bin/bash

echo "🔧 Triggering Staging Workflow Test"
echo "==================================="

echo ""
echo "📋 Current status:"
echo "✅ Local APK works (Firebase config is correct)"  
echo "❌ GitHub staging APK fails (workflow issue)"
echo ""

echo "🔍 Checking if we can trigger a new staging build..."

# Check current branch
current_branch=$(git branch --show-current)
echo "📍 Current branch: $current_branch"

if [ "$current_branch" = "main" ]; then
    echo "✅ On main branch - staging workflow will trigger on push"
else
    echo "⚠️  Not on main branch - need to switch to main or merge"
fi

echo ""
echo "🚀 Next steps:"
echo "1. Ensure DEBUG_KEYSTORE secret is added to GitHub"
echo "2. Push a commit to main branch to trigger staging workflow" 
echo "3. Wait for workflow to complete"
echo "4. Download NEW APK from workflow artifacts"
echo "5. Test the new APK"

echo ""
echo "📝 To trigger staging workflow:"
echo "git checkout main"
echo "git add -A"
echo "git commit -m 'fix: Update workflows to use consistent debug keystore'"
echo "git push origin main"

echo ""
echo "🔍 To verify DEBUG_KEYSTORE secret:"
echo "1. Go to GitHub repo → Settings → Secrets and variables → Actions"
echo "2. Confirm DEBUG_KEYSTORE exists"
echo "3. Value should start with: MIIKNgIBAzCCCeAG..."