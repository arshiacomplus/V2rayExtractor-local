REPO="arshiacomplus/V2rayExtractor-local"
CMD_NAME="v2l"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${GREEN}Starting installation for V2L (V2rayExtractor-local)...${NC}"
for cmd in curl unzip jq; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${YELLOW}Error: '$cmd' is not installed. Please install it first.${NC}"
    echo "On Debian/Ubuntu: sudo apt-get install $cmd"
    echo "On Termux: pkg install $cmd"
    exit 1
  fi
done
ARCH=$(uname -m)
OS=$(uname -s)
ASSET_KEYWORD=""
if [ "$OS" == "Linux" ]; then
  if [ "$ARCH" == "x86_64" ]; then
    ASSET_KEYWORD="linux-x64"
  elif [ "$ARCH" == "aarch64" ]; then
    ASSET_KEYWORD="linux-arm64"
  fi
elif [ "$OS" == "Darwin" ]; then
    ASSET_KEYWORD="macos"
fi
if [ -z "$ASSET_KEYWORD" ]; then
  echo -e "${YELLOW}Error: Unsupported OS/Architecture: $OS/$ARCH${NC}"
  exit 1
fi
echo "Detected System: $OS/$ARCH. Looking for asset: *$ASSET_KEYWORD*"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
echo "Fetching latest release from GitHub..."
DOWNLOAD_URL=$(curl -s $API_URL | jq -r --arg keyword "$ASSET_KEYWORD" '.assets[] | select(.name | contains($keyword)) | .browser_download_url')
if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
  echo -e "${YELLOW}Error: Could not find a release asset for your system. Please check the releases page.${NC}"
  exit 1
fi
echo "Found download URL: $DOWNLOAD_URL"
TEMP_DIR=$(mktemp -d)
echo "Downloading to temporary directory: $TEMP_DIR"
curl -L -o "$TEMP_DIR/asset.zip" "$DOWNLOAD_URL"
EXECUTABLE_NAME=$(unzip -l "$TEMP_DIR/asset.zip" | grep 'v2ray_scraper_ui' | awk '{print $4}')
unzip -o "$TEMP_DIR/asset.zip" -d "$TEMP_DIR"
chmod +x "$TEMP_DIR/$EXECUTABLE_NAME"
if [[ -n "$PREFIX" ]]; then
  INSTALL_DIR="$PREFIX/bin"
  SUDO_CMD=""
else
  INSTALL_DIR="/usr/local/bin"
  SUDO_CMD="sudo"
fi
echo "Installing '$CMD_NAME' to $INSTALL_DIR..."
if $SUDO_CMD mv "$TEMP_DIR/$EXECUTABLE_NAME" "$INSTALL_DIR/$CMD_NAME"; then
  echo -e "${GREEN}Installation successful!${NC}"
  echo "You can now run the application by simply typing:"
  echo -e "${YELLOW}  $CMD_NAME${NC}"
else
  echo -e "${YELLOW}Error: Installation failed. You may need to run this script with sudo, or check permissions for $INSTALL_DIR.${NC}"
  exit 1
fi
rm -rf "$TEMP_DIR"