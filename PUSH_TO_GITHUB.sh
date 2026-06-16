#!/bin/bash

echo "🚀 Pushing Komoot2GPX to GitHub..."
echo ""

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI found"
    echo ""
    echo "Creating repository on GitHub..."
    gh repo create Komoot2GPX --public --source=. --remote=origin --push
    echo ""
    echo "✅ Repository created and pushed!"
    echo ""
    echo "📱 Your repo is live at: https://github.com/$(gh api user | jq -r '.login')/Komoot2GPX"
else
    echo "❌ GitHub CLI not found"
    echo ""
    echo "Please follow these steps manually:"
    echo ""
    echo "1. Go to https://github.com/new"
    echo "2. Repository name: Komoot2GPX"
    echo "3. Choose Public or Private"
    echo "4. Click 'Create repository'"
    echo "5. Run these commands:"
    echo ""
    echo "   git remote add origin https://github.com/YOUR_USERNAME/Komoot2GPX.git"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
fi
