#!/bin/bash
set -e

# Configuration
APP_NAME="Nano Pet"
SCHEME="Nano Pet"
PROJECT="Nano Pet.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse version argument
VERSION=$1
if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version required${NC}"
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.0.0"
    exit 1
fi

echo -e "${GREEN}🚀 Releasing Nano Pet v${VERSION}${NC}"

# 1. Update version in Xcode project
echo -e "${YELLOW}📝 Updating version to ${VERSION}...${NC}"
sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = ${VERSION}/" "$PROJECT/project.pbxproj"

# 2. Clean and build
echo -e "${YELLOW}🔨 Building Release...${NC}"
rm -rf build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -derivedDataPath build clean build | tail -5

# Check build succeeded
if [ ! -d "build/Build/Products/Release/${APP_NAME}.app" ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# 3. Create DMG
echo -e "${YELLOW}📦 Creating DMG...${NC}"
DMG_NAME="Nano.Pet.${VERSION}.dmg"
rm -rf dmg_contents "$DMG_NAME"
mkdir dmg_contents
cp -R "build/Build/Products/Release/${APP_NAME}.app" dmg_contents/
ln -s /Applications dmg_contents/Applications
hdiutil create -volname "$APP_NAME" -srcfolder dmg_contents -ov -format UDZO "$DMG_NAME"
rm -rf dmg_contents

echo -e "${GREEN}✅ DMG created: ${DMG_NAME}${NC}"

# 4. Git operations
echo -e "${YELLOW}🏷️ Creating git tag v${VERSION}...${NC}"
git add -A
git commit -m "Release v${VERSION}" || echo "No changes to commit"
git tag -a "v${VERSION}" -m "Release v${VERSION}"

# 5. Push to remote (if configured)
if git remote get-url origin &>/dev/null; then
    echo -e "${YELLOW}📤 Pushing to remote...${NC}"
    git push origin main --tags

    # 6. Create GitHub release with DMG attached (requires gh CLI)
    if command -v gh &>/dev/null; then
        echo -e "${YELLOW}🎉 Creating GitHub release...${NC}"
        gh release create "v${VERSION}" "$DMG_NAME" \
            --title "Nano Pet v${VERSION}" \
            --notes "## Download

Download **${DMG_NAME}** below, open it, and drag Nano Pet to your Applications folder.

> **Note:** On first launch, right-click and select \"Open\" to bypass Gatekeeper.

## What's New

See commit history for changes."

        echo -e "${GREEN}🔗 Release created!${NC}"
    else
        echo -e "${YELLOW}⚠️ gh CLI not found. Skipping GitHub release creation.${NC}"
        echo "Install with: brew install gh"
    fi
else
    echo -e "${YELLOW}⚠️ No git remote configured. Skipping push.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Release v${VERSION} complete!${NC}"
echo -e "📍 DMG: ${DMG_NAME}"
ls -lh "$DMG_NAME"
